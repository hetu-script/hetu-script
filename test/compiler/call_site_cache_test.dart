import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

Hetu _createHetu() {
  final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
  hetu.init();
  return hetu;
}

const _argumentSource = r'''
function add(a, b) {
  return a + b
}

function namedAdd(value, {increment = 1}) {
  return value + increment
}

function sum(...values) {
  return values[0] + values[1] + values[2]
}

function run() {
  final args = [1, 2]
  return [
    add(1, 2),
    namedAdd(1, increment: 2),
    sum(...args, 3),
  ]
}
''';

void main() {
  test('call site cache records hits and survives same-bytecode reexecution',
      () {
    final hetu = _createHetu();
    final bytes = hetu.compile(_argumentSource);
    hetu.loadBytecode(bytes: bytes, module: 'arguments');
    final module = hetu.interpreter.getBytecode('arguments')!;

    for (var i = 0; i < 5; ++i) {
      expect(hetu.invoke('run', module: 'arguments'), [3, 3, 6]);
    }
    expect(module.callSiteCacheSize, 3);
    expect(module.callSiteCacheMisses, 3);
    expect(module.callSiteCacheHits, 12);
    expect(module.callSiteCacheHitRate, 0.8);

    hetu.loadBytecode(bytes: bytes, module: 'arguments');
    for (var i = 0; i < 2; ++i) {
      expect(hetu.invoke('run', module: 'arguments'), [3, 3, 6]);
    }
    expect(module.callSiteCacheSize, 3);
    expect(module.callSiteCacheMisses, 3);
    expect(module.callSiteCacheHits, 18);
    expect(module.callSiteCacheHitRate, closeTo(18 / 21, 0.000001));
  });

  test('call site caches are isolated by bytecode module', () {
    final hetu = _createHetu();
    for (final entry in {'first': 'moduleA', 'other': 'moduleB'}.entries) {
      final name = entry.key;
      final moduleName = entry.value;
      final bytes = hetu.compile('''
        function target({$name = 0}) {
          return $name
        }
        function run() {
          return target($name: 7)
        }
      ''');
      hetu.loadBytecode(bytes: bytes, module: moduleName);
      expect(hetu.invoke('run', module: moduleName), 7);
      final module = hetu.interpreter.getBytecode(moduleName)!;
      expect(module.callSiteCacheSize, 1);
      expect(module.callSiteCacheMisses, 1);
      expect(module.callSiteCacheHits, 0);
    }
  });

  test('call site cache preserves default value evaluation semantics', () {
    final hetu = _createHetu();
    final bytes = hetu.compile(r'''
      var nextValue = 0
      function next() {
        ++nextValue
        return nextValue
      }
      function withDefault({value = next()}) {
        return value
      }
      function run() {
        return [withDefault(), withDefault()]
      }
    ''');
    hetu.loadBytecode(bytes: bytes, module: 'defaults');
    final module = hetu.interpreter.getBytecode('defaults')!;

    expect(hetu.invoke('run', module: 'defaults'), [1, 1]);
    expect(hetu.invoke('run', module: 'defaults'), [1, 1]);
    expect(module.callSiteCacheMisses, 3);
    expect(module.callSiteCacheHits, 2);
  });

  test('constructor calls reuse their cached metadata', () {
    final hetu = _createHetu();
    final bytes = hetu.compile(r'''
      class Box {
        var value
        constructor(value) {
          this.value = value
        }
      }
      function run() {
        return Box(42).value
      }
    ''');
    hetu.loadBytecode(bytes: bytes, module: 'constructors');
    final module = hetu.interpreter.getBytecode('constructors')!;

    for (var i = 0; i < 3; ++i) {
      expect(hetu.invoke('run', module: 'constructors'), 42);
    }
    expect(module.callSiteCacheMisses, 1);
    expect(module.callSiteCacheHits, 2);
  });
}
