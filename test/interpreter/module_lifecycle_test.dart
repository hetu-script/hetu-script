import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

Hetu _createHetu({HTOverlayContext? sourceContext}) {
  final hetu = Hetu(
    config: HetuConfig(
      normalizeImportPath: false,
      processError: false,
    ),
    sourceContext: sourceContext,
  );
  hetu.init();
  return hetu;
}

void main() {
  group('established module behavior', () {
    test('the same bytecode can reexecute while retaining its module and cache',
        () {
      final hetu = _createHetu();
      final bytes = hetu.compile(r'''
        function target({value = 1}) {
          return value
        }
        function run() {
          return target(value: 42)
        }
      ''', filename: 'shared.ht');

      hetu.loadBytecode(bytes: bytes, module: 'shared');
      final module = hetu.interpreter.getBytecode('shared')!;
      expect(hetu.invoke('run', module: 'shared'), 42);
      expect(module.callSiteCacheMisses, 1);

      hetu.loadBytecode(bytes: bytes, module: 'shared');

      expect(identical(hetu.interpreter.getBytecode('shared'), module), isTrue);
      expect(hetu.invoke('run', module: 'shared'), 42);
      expect(module.callSiteCacheSize, 1);
      expect(module.callSiteCacheHits, greaterThan(0));
    });

    test('different module names isolate identical source names and state', () {
      final hetu = _createHetu();
      final first = hetu.compile(r'''
        var state = 1
        function read() {
          return state
        }
        function update(value) {
          state = value
        }
      ''', filename: 'shared.ht');
      final second = hetu.compile(r'''
        var state = 2
        function read() {
          return state
        }
        function update(value) {
          state = value
        }
      ''', filename: 'shared.ht');

      hetu.loadBytecode(bytes: first, module: 'first');
      hetu.loadBytecode(bytes: second, module: 'second');
      hetu.invoke('update', module: 'first', positionalArgs: [42]);

      expect(hetu.invoke('read', module: 'first'), 42);
      expect(hetu.invoke('read', module: 'second'), 2);

      hetu.interpreter.switchModule('first');
      final firstNamespace = hetu.interpreter.currentNamespace;
      expect(hetu.invoke('read'), 42);
      hetu.interpreter.switchModule('second');
      expect(hetu.invoke('read'), 2);
      expect(identical(hetu.interpreter.currentNamespace, firstNamespace),
          isFalse);
    });

    test('dynamic deletion affects only the selected module', () {
      final hetu = _createHetu();
      final bytes = hetu.compile(
        'var removable = 42',
        filename: 'shared.ht',
      );

      hetu.loadBytecode(bytes: bytes, module: 'first');
      hetu.loadBytecode(bytes: bytes, module: 'second');
      hetu.interpreter.switchModule('first');
      hetu.interpreter.currentNamespace.delete('removable');

      expect(() => hetu.fetch('removable', module: 'first'),
          throwsA(isA<HTError>()));
      expect(hetu.fetch('removable', module: 'second'), 42);
    });

    test('imports are bundled per compilation and remain module-local', () {
      final sources = HTOverlayContext();
      sources.addResource('dep.ht', HTSource('var answer = 42'));
      sources.addResource(
        'entry.ht',
        HTSource(r'''
          import 'dep.ht'
          function read() {
            return answer
          }
        '''),
      );
      final hetu = _createHetu(sourceContext: sources);

      hetu.evalFile('entry.ht', module: 'first');
      expect(hetu.invoke('read', module: 'first'), 42);

      sources.updateResource('dep.ht', HTSource('var answer = 100'));
      hetu.evalFile('entry.ht', module: 'second');

      expect(hetu.invoke('read', module: 'second'), 100);
      expect(hetu.invoke('read', module: 'first'), 42);
    });
  });

  group('current behavior awaiting a reload semantics decision', () {
    test('same-name different bytecode currently executes the old module', () {
      final hetu = _createHetu();
      final oldBytes = hetu.compile(
        'function read() { return 1 }',
        filename: 'shared.ht',
      );
      final newBytes = hetu.compile(
        'function read() { return 2 }',
        filename: 'shared.ht',
      );

      hetu.loadBytecode(bytes: oldBytes, module: 'shared');
      final module = hetu.interpreter.getBytecode('shared')!;
      hetu.loadBytecode(bytes: newBytes, module: 'shared');

      expect(identical(hetu.interpreter.getBytecode('shared'), module), isTrue);
      expect(module.bytes, orderedEquals(oldBytes));
      expect(hetu.invoke('read', module: 'shared'), 1);
    });

    test(
        'different bytecode reload uses new declarations and module generation',
        () {
      final hetu = _createHetu();
      final oldBytes = hetu.compile(
        'function read() { return 1 }',
        filename: 'shared.ht',
      );
      final newBytes = hetu.compile(
        'function read() { return 2 }',
        filename: 'shared.ht',
      );

      hetu.loadBytecode(bytes: oldBytes, module: 'shared');
      hetu.loadBytecode(bytes: newBytes, module: 'shared');

      expect(hetu.invoke('read', module: 'shared'), 2);
    },
        skip:
            'Stage 4 decision required: replacement, rejection or explicit reload');
  });
}
