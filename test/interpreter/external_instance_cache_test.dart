import 'package:hetu_script/binding.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

class _Counter {}

class _CounterBinding extends HTExternalClass {
  _CounterBinding(super.id);

  int methodBindings = 0;

  @override
  dynamic memberGet(
    String id, {
    String? from,
    bool isRecursive = false,
    bool ignoreUndefined = false,
  }) {
    if (id == 'Counter') {
      return ({positionalArgs, namedArgs}) => _Counter();
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }

  @override
  dynamic instanceMemberGet(
    dynamic instance,
    String id, {
    bool ignoreUndefined = false,
  }) {
    if (id == 'add') {
      final value = ++methodBindings;
      return ({object, positionalArgs, namedArgs}) => value;
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }
}

void main() {
  test('external wrappers preserve inheritance and dynamic method bindings',
      () {
    final binding = _CounterBinding('Counter');
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init(
      externalClasses: [_CounterBinding('Base'), binding],
      externalTypeReflections: [
        (object) => object is _Counter ? 'Counter' : null,
      ],
    );
    final result = hetu.eval(r'''
      external class Base {
        function add() -> int
      }
      external class Counter extends Base {
        constructor()
      }
      final counter = Counter()
      [counter.add(), counter.add(), counter.add()]
    ''');

    expect(result, [1, 2, 3]);
    expect(binding.methodBindings, 3);
    expect(hetu.interpreter.externalInstanceCacheMisses, 1);
    expect(hetu.interpreter.externalInstanceCacheHits, 2);
  });

  test('external wrappers do not reuse declarations across modules', () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init(
      externalClasses: [_CounterBinding('Counter')],
      externalTypeReflections: [
        (object) => object is _Counter ? 'Counter' : null,
      ],
    );
    final counter = _Counter();
    final bytes = hetu.compile('''
      external class Counter {
        function add() -> int
      }
    ''');

    hetu.loadBytecode(bytes: bytes, module: 'moduleA');
    final first = hetu.interpreter.encapsulate(counter) as HTExternalInstance;
    final second = hetu.interpreter.encapsulate(counter);
    expect(identical(first, second), isTrue);

    hetu.loadBytecode(bytes: bytes, module: 'moduleB');
    final third = hetu.interpreter.encapsulate(counter) as HTExternalInstance;
    expect(identical(first, third), isFalse);
    expect(identical(first.klass, third.klass), isFalse);

    hetu.interpreter.switchModule('moduleA');
    final fourth = hetu.interpreter.encapsulate(counter);
    expect(identical(first, fourth), isFalse);
    expect(hetu.interpreter.externalInstanceCacheMisses, 3);
    expect(hetu.interpreter.externalInstanceCacheHits, 1);
  });

  test('external wrappers are invalidated by new reflections', () {
    var reflectionCalls = 0;
    var typeName = 'Counter';
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init(externalTypeReflections: [
      (object) {
        ++reflectionCalls;
        return object is _Counter ? typeName : null;
      },
    ]);
    final counter = _Counter();

    final first = hetu.interpreter.encapsulate(counter) as HTExternalInstance;
    final second = hetu.interpreter.encapsulate(counter) as HTExternalInstance;
    expect(first.typeString, 'Counter');
    expect(second.typeString, 'Counter');
    expect(identical(first, second), isTrue);
    expect(reflectionCalls, 1);
    expect(hetu.interpreter.externalInstanceCacheMisses, 1);
    expect(hetu.interpreter.externalInstanceCacheHits, 1);

    typeName = 'RenamedCounter';
    hetu.interpreter.bindExternalReflection((object) => null);
    expect(hetu.interpreter.externalInstanceCacheHits, 0);
    expect(hetu.interpreter.externalInstanceCacheMisses, 0);

    final third = hetu.interpreter.encapsulate(counter) as HTExternalInstance;
    expect(third.typeString, 'RenamedCounter');
    expect(identical(first, third), isFalse);
    expect(hetu.interpreter.externalInstanceCacheMisses, 1);

    final other = hetu.interpreter.encapsulate(_Counter());
    expect(identical(third, other), isFalse);
    expect(hetu.interpreter.externalInstanceCacheMisses, 2);
  });

  test('collection wrappers are reused but primitive wrappers bypass Expando',
      () {
    final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
    hetu.init();
    final list = <int>[];

    final first = hetu.interpreter.encapsulate(list);
    final second = hetu.interpreter.encapsulate(list);
    expect(identical(first, second), isTrue);
    expect(hetu.interpreter.externalInstanceCacheMisses, 1);
    expect(hetu.interpreter.externalInstanceCacheHits, 1);

    for (final value in <dynamic>[
      1,
      1.5,
      'text',
      true,
      BigInt.one,
      (1, 2),
      Expando(),
    ]) {
      expect(hetu.interpreter.encapsulate(value), isNotNull);
    }
    expect(hetu.interpreter.externalInstanceCacheMisses, 1);
    expect(hetu.interpreter.externalInstanceCacheHits, 1);
  });
}
