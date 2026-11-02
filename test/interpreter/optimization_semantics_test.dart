import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import 'package:test/test.dart';

Hetu _createHetu() {
  final hetu = Hetu(
    config: HetuConfig(
      normalizeImportPath: false,
      allowVariableShadowing: true,
    ),
  );
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
  group('optimization baseline parameters -', () {
    test('positional, optional, named and omitted parameters', () {
      final hetu = _createHetu();
      final result = hetu.eval(r'''
        function positional(_, value, [optional = 3]) {
          return [value, optional]
        }
        function named(value, {increment = 2}) {
          return value + increment
        }
        [
          positional(0, 1),
          positional(0, 1, 4),
          named(5),
          named(5, increment: 4),
        ]
      ''');

      expect(result, [
        [1, 3],
        [1, 4],
        7,
        9,
      ]);
    });

    test('default values retain current resolution timing', () {
      final hetu = _createHetu();
      final result = hetu.eval(r'''
        var calls = 0
        function next() {
          ++calls
          return calls
        }
        function withDefault({value = next()}) {
          return value
        }
        final first = withDefault()
        final second = withDefault()
        [first, second, calls]
      ''');

      expect(result, [1, 1, 1]);
    });
  });

  group('optimization baseline locals -', () {
    test('shadowing, assignment, recursion and early return', () {
      final hetu = _createHetu();
      final result = hetu.eval(r'''
        function sumDown(n) {
          if (n <= 0) {
            return 0
          }
          var value = n
          var shadowed = 0
          if (true) {
            var value = 100
            shadowed = value
          }
          value += 1
          return shadowed == 100 ? value + sumDown(n - 1) : -1
        }
        sumDown(3)
      ''');

      expect(result, 9);
    });

    test('deleting a local preserves undefined behavior', () {
      final hetu = _createHetu();
      expect(
        () => hetu.eval(r'''
          function removeLocal() {
            var value = 42
            delete value
            return value
          }
          removeLocal()
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('exceptions preserve error behavior and clear the script stack', () {
      final hetu = Hetu(
        config: HetuConfig(
          normalizeImportPath: false,
          showHetuStackTrace: true,
        ),
      );
      hetu.init();
      hetu.eval(r'''
        function fail() {
          throw 'boom'
          return 1
        }
      ''');

      expect(() => hetu.invoke('fail'), throwsA(isA<HTError>()));
      expect(hetu.interpreter.stackTraceList, isEmpty);
    });
  });

  group('optimization baseline closures -', () {
    test('captured mutation and function identity', () {
      final hetu = _createHetu();
      final result = hetu.eval(r'''
        function makeCounter(start) {
          var count = start
          return () {
            return ++count
          }
        }
        final first = makeCounter(0)
        final second = makeCounter(10)
        final values = [first(), first(), second(), first()]
        [values, first == second]
      ''');

      expect(result, [
        [1, 2, 11, 3],
        false,
      ]);
    });

    test('loop closures retain current capture and identity behavior', () {
      final hetu = _createHetu();
      final result = hetu.eval(r'''
        final callbacks = []
        for (var i = 0; i < 3; ++i) {
          callbacks.add(() => i)
        }
        [
          callbacks[0](),
          callbacks[1](),
          callbacks[2](),
          callbacks[0] == callbacks[1],
        ]
      ''');

      expect(result, [3, 3, 3, false]);
    });
  });

  group('optimization baseline objects and bindings -', () {
    test('class, struct and constructor field initialization', () {
      final hetu = _createHetu();
      final result = hetu.eval(r'''
        class Box {
          var value
          constructor(this.value) {}
          function read() {
            return this.value
          }
        }
        struct Pair {
          var left
          var right
          constructor(left, right) {
            this.left = left
            this.right = right
          }
        }
        final pair = Pair(1, 2)
        [Box(42).read(), pair.left, pair.right]
      ''');

      expect(result, [42, 1, 2]);
    });

    test('external calls and nested script callbacks', () {
      final hetu = _createHetu();
      hetu.interpreter.bindExternalFunction(
          'hostAdd',
          ({positionalArgs, namedArgs}) =>
              positionalArgs[0] + positionalArgs[1]);
      hetu.interpreter.bindExternalFunction('hostInvoke', (
          {positionalArgs, namedArgs}) {
        final callback = positionalArgs[0] as HTFunction;
        return callback.call(positionalArgs: [positionalArgs[1]]);
      });
      final result = hetu.eval(r'''
        external function hostAdd(a, b)
        external function hostInvoke(callback, value)
        [hostAdd(20, 22), hostInvoke((value) => value * 2, 21)]
      ''');

      expect(result, [42, 42]);
    });
  });

  group('optimization baseline execution lifecycle -', () {
    test('async suspension resumes captured locals', () async {
      final hetu = _createHetu();
      hetu.interpreter.bindExternalFunction('fetch42', () => Future.value(42));
      hetu.eval(r'''
        external function fetch42()
        function resume(start) async {
          var local = start
          final add = (value) => local + value
          final fetched = await fetch42()
          return add(fetched)
        }
      ''');

      expect(
        await _resolve(hetu.invoke('resume', positionalArgs: [1])),
        43,
      );
    });

    test('module switching and repeated loading preserve module behavior', () {
      final hetu = _createHetu();
      final counterBytes = hetu.compile(r'''
        var count = 0
        function next() {
          ++count
          return count
        }
      ''');
      final otherBytes = hetu.compile(r'''
        function next() {
          return 100
        }
      ''');

      hetu.loadBytecode(bytes: counterBytes, module: 'counter');
      expect(hetu.invoke('next', module: 'counter'), 1);
      hetu.loadBytecode(bytes: otherBytes, module: 'other');
      expect(hetu.invoke('next', module: 'other'), 100);
      expect(hetu.invoke('next', module: 'counter'), 2);
      hetu.loadBytecode(bytes: counterBytes, module: 'counter');
      expect(hetu.invoke('next', module: 'counter'), 1);
    });
  });
}
