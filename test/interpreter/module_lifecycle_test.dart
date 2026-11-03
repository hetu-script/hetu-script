import 'dart:typed_data';

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

      hetu.loadBytecode(bytes: Uint8List.fromList(bytes), module: 'shared');

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

  group('module reload semantics', () {
    test('different bytecode replaces declarations and starts a fresh cache',
        () {
      final hetu = _createHetu();
      final oldBytes = hetu.compile(r'''
        function target({value = 1}) {
          return value
        }
        function run() {
          return target()
        }
      ''', filename: 'shared.ht');
      final newBytes = hetu.compile(r'''
        function target({value = 2}) {
          return value
        }
        function run() {
          return target()
        }
      ''', filename: 'shared.ht');

      hetu.loadBytecode(bytes: oldBytes, module: 'shared');
      final oldModule = hetu.interpreter.getBytecode('shared')!;
      expect(hetu.invoke('run', module: 'shared'), 1);
      expect(oldModule.callSiteCacheMisses, 1);

      hetu.loadBytecode(bytes: newBytes, module: 'shared');
      final newModule = hetu.interpreter.getBytecode('shared')!;

      expect(identical(newModule, oldModule), isFalse);
      expect(newModule.bytes, orderedEquals(newBytes));
      expect(newModule.callSiteCacheSize, 0);
      expect(newModule.callSiteCacheMisses, 0);
      expect(hetu.invoke('run', module: 'shared'), 2);
      expect(newModule.callSiteCacheMisses, 1);
      expect(oldModule.callSiteCacheMisses, 1);
    });

    test('reload uses fresh state without disturbing other modules', () {
      final hetu = _createHetu();
      final oldBytes = hetu.compile(r'''
        var state = 1
        function read() {
          return state
        }
        function update(value) {
          state = value
        }
      ''', filename: 'shared.ht');
      final newBytes = hetu.compile(r'''
        var state = 2
        function read() {
          return state
        }
      ''', filename: 'shared.ht');
      final otherBytes = hetu.compile(
        'function answer() { return 42 }',
        filename: 'other.ht',
      );

      hetu.loadBytecode(bytes: oldBytes, module: 'shared');
      hetu.invoke('update', module: 'shared', positionalArgs: [99]);
      hetu.loadBytecode(bytes: otherBytes, module: 'other');
      hetu.loadBytecode(bytes: newBytes, module: 'shared');

      expect(hetu.invoke('read', module: 'shared'), 2);
      expect(hetu.invoke('answer', module: 'other'), 42);
      hetu.interpreter.switchModule('other');
      expect(hetu.invoke('answer'), 42);
      hetu.interpreter.switchModule('shared');
      expect(hetu.invoke('read'), 2);
    });

    test('recompiling an imported source reloads the same module name', () {
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

      hetu.evalFile('entry.ht', module: 'shared');
      final oldModule = hetu.interpreter.getBytecode('shared')!;
      expect(hetu.invoke('read', module: 'shared'), 42);

      sources.updateResource('dep.ht', HTSource('var answer = 100'));
      hetu.evalFile('entry.ht', module: 'shared');

      expect(identical(hetu.interpreter.getBytecode('shared'), oldModule),
          isFalse);
      expect(hetu.invoke('read', module: 'shared'), 100);
    });
  });
}
