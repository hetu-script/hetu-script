import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import 'package:test/test.dart';

Hetu _createHetu() {
  final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
  hetu.init();
  return hetu;
}

Future<dynamic> _resolve(dynamic value) async {
  while (value is Future) {
    value = await value;
  }
  return value;
}

void main() {
  test('captured cells survive their owner and preserve mutation', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function makeCounter(start) {
        var count = start
        return () {
          return ++count
        }
      }
    ''');
    final owner = hetu.fetch('makeCounter') as HTFunction;
    final first = hetu.invoke('makeCounter', positionalArgs: [0]) as HTFunction;
    final second =
        hetu.invoke('makeCounter', positionalArgs: [10]) as HTFunction;

    expect(owner.callScopeCapturedSlots, [1]);
    expect(first.callScopeUpvalues.single.depth, 0);
    expect(first.callScopeUpvalues.single.slot, 1);
    expect(first.capturedCells, hasLength(1));
    expect(first.definingScope, isNotNull);
    expect([first.call(), first.call(), second.call(), first.call()],
        [1, 2, 11, 3]);
    expect(first == second, isFalse);
  });

  test('uncaptured locals and closures do not allocate captured cells', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function add(value) {
        var result = value + 1
        return result
      }
      function uncaptured() {
        final increment = (value) => value + 1
        return increment(2)
      }
    ''');

    expect((hetu.fetch('add') as HTFunction).callScopeCapturedSlots, isEmpty);
    expect((hetu.fetch('uncaptured') as HTFunction).callScopeCapturedSlots,
        isEmpty);
    expect(hetu.invoke('add', positionalArgs: [2]), 3);
    expect(hetu.invoke('uncaptured'), 3);
  });

  test('sibling closures share the same captured cell', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function makeAccessors() {
        var value = 0
        final read = () => value
        final write = (next) {
          value = next
        }
        return [read, write]
      }
    ''');
    final accessors = hetu.invoke('makeAccessors') as List;
    final read = accessors[0] as HTFunction;
    final write = accessors[1] as HTFunction;

    expect(identical(read.capturedCells.single, write.capturedCells.single),
        isTrue);
    write.call(positionalArgs: [42]);
    expect(read.call(), 42);
  });

  test('transitive captures retain the correct depths and cells', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function outer(x) {
        function middle(y) {
          function inner(z) {
            return x + y + z
          }
          return inner
        }
        return middle
      }
    ''');
    final middle = hetu.invoke('outer', positionalArgs: [1]) as HTFunction;
    final inner = middle.call(positionalArgs: [2]) as HTFunction;

    expect(middle.callScopeUpvalues, hasLength(1));
    expect(inner.callScopeUpvalues, hasLength(2));
    expect(inner.callScopeUpvalues[0].depth, 1);
    expect(inner.callScopeUpvalues[1].depth, 0);
    expect(inner.call(positionalArgs: [3]), 6);
  });

  test('local recursive functions capture their own binding', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function makeFib() {
        function fib(n) {
          if (n <= 1) {
            return n
          }
          return fib(n - 1) + fib(n - 2)
        }
        return fib
      }
    ''');
    final fib = hetu.invoke('makeFib') as HTFunction;

    expect(fib.callScopeUpvalues.single.depth, 0);
    expect(fib.callScopeUpvalues.single.slot, 0);
    expect(fib.call(positionalArgs: [10]), 55);
  });

  test('loop closures preserve current for and per-iteration for-in behavior',
      () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function makeLoops() {
        final callbacks = []
        for (var i = 0; i < 3; ++i) {
          callbacks.add(() => i)
        }
        for (final item in [1, 2, 3]) {
          callbacks.add(() => item)
        }
        return callbacks
      }
    ''');
    final callbacks = hetu.invoke('makeLoops') as List;
    final values = callbacks.map((callback) => callback.call()).toList();

    expect(values, [3, 3, 3, 1, 2, 3]);
    expect(callbacks[0] == callbacks[1], isFalse);
    expect(callbacks[3] == callbacks[4], isFalse);
  });

  test('async suspension and nested external calls retain captured cells',
      () async {
    final hetu = _createHetu();
    hetu.interpreter.bindExternalFunction('fetch42', () => Future.value(42));
    hetu.interpreter.bindExternalFunction('hostInvoke', (
        {positionalArgs, namedArgs}) {
      final callback = positionalArgs[0] as HTFunction;
      return callback.call();
    });
    hetu.eval(r'''
      external function fetch42()
      external function hostInvoke(callback)
      function resume(start) async {
        var local = start
        final add = (value) => local + value
        final fetched = await fetch42()
        return add(fetched)
      }
      function makeAnswer() {
        var value = 42
        return () => value
      }
    ''');

    expect(await _resolve(hetu.invoke('resume', positionalArgs: [1])), 43);
    expect(
        hetu.invoke('hostInvoke', positionalArgs: [hetu.invoke('makeAnswer')]),
        42);
  });

  test('dynamic nested functions propagate the generic fallback outward', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function outer(value) {
        function inner() {
          delete value
          return value
        }
        return inner
      }
    ''');
    final outer = hetu.fetch('outer') as HTFunction;
    final inner = hetu.invoke('outer', positionalArgs: [1]) as HTFunction;

    expect(outer.callScopeSlotCount, isNull);
    expect(inner.callScopeSlotCount, isNull);
    expect(() => inner.call(), throwsA(isA<HTError>()));
  });

  test('function clones retain captured cells and their mutation', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function makeCounter() {
        var count = 0
        return () => ++count
      }
    ''');
    final original = hetu.invoke('makeCounter') as HTFunction;
    final clone = original.clone();

    expect(identical(clone.capturedCells.single, original.capturedCells.single),
        isTrue);
    expect([original.call(), clone.call(), original.call()], [1, 2, 3]);
  });
}
