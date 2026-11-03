import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import 'package:test/test.dart';

class _ExecutionSnapshot {
  final HTContext context;
  final HTStackFrame stack;
  final List<dynamic> operands;

  _ExecutionSnapshot(Hetu hetu)
      : context = hetu.interpreter.getContext(),
        stack = hetu.interpreter.stack,
        operands = List<dynamic>.of(hetu.interpreter.stack.operandStack);
}

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

Future<dynamic> _resolve(dynamic value) async {
  while (value is Future) {
    value = await value;
  }
  return value;
}

void _expectRestored(Hetu hetu, _ExecutionSnapshot snapshot) {
  final context = hetu.interpreter.getContext();
  expect(context.file, snapshot.context.file, reason: 'file must be restored');
  expect(context.module, snapshot.context.module,
      reason: 'module must be restored');
  expect(identical(context.namespace, snapshot.context.namespace), isTrue,
      reason: 'namespace identity must be restored');
  expect(identical(context.callScope, snapshot.context.callScope), isTrue,
      reason: 'call scope identity must be restored');
  expect(context.ip, snapshot.context.ip, reason: 'ip must be restored');
  expect(context.line, snapshot.context.line, reason: 'line must be restored');
  expect(context.column, snapshot.context.column,
      reason: 'column must be restored');
  expect(identical(hetu.interpreter.stack, snapshot.stack), isTrue,
      reason: 'the executing stack frame must be removed');
  expect(hetu.interpreter.stack.operandStack, snapshot.operands,
      reason: 'the restored operand stack must not retain temporary values');
}

void main() {
  group('successful execution restores context and stack frames', () {
    test('early return, recursion and loop break restore every call', () {
      final hetu = _createHetu();
      hetu.eval(r'''
        function early(value) {
          if (value) {
            return 42
          }
          return 0
        }
        function recurse(value) {
          if (value == 0) {
            return 0
          }
          return 1 + recurse(value - 1)
        }
        function stop() {
          var value = 0
          while (true) {
            ++value
            if (value == 3) {
              break
            }
          }
          return value
        }
      ''');
      final snapshot = _ExecutionSnapshot(hetu);

      expect(hetu.invoke('early', positionalArgs: [true]), 42);
      _expectRestored(hetu, snapshot);
      expect(hetu.invoke('recurse', positionalArgs: [4]), 4);
      _expectRestored(hetu, snapshot);
      expect(hetu.invoke('stop'), 3);
      _expectRestored(hetu, snapshot);
    });

    test('successful await restores the suspended context and stack frame',
        () async {
      final hetu = _createHetu();
      hetu.interpreter
          .bindExternalFunction('fetchValue', () => Future.value(41));
      hetu.eval(r'''
        external function fetchValue()
        function resume() async {
          var local = 1
          final fetched = await fetchValue()
          return local + fetched
        }
      ''');
      final snapshot = _ExecutionSnapshot(hetu);

      expect(await _resolve(hetu.invoke('resume')), 42);
      _expectRestored(hetu, snapshot);
    });
  });

  group('public entry points restore state after errors', () {
    test('top-level eval errors restore the facade context', () {
      final hetu = _createHetu();
      final snapshot = _ExecutionSnapshot(hetu);

      expect(() => hetu.eval("throw 'failure'"), throwsA(isA<HTError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.eval('6 * 7'), 42);
    });

    test('invoke restores the previously selected module after an error', () {
      final hetu = _createHetu();
      final failing = hetu.compile(
        "function fail() { throw 'failure' }",
        filename: 'failing.ht',
      );
      final working = hetu.compile(
        'function answer() { return 42 }',
        filename: 'working.ht',
      );
      hetu.loadBytecode(bytes: failing, module: 'failing');
      hetu.loadBytecode(bytes: working, module: 'working');
      final snapshot = _ExecutionSnapshot(hetu);

      expect(() => hetu.invoke('fail', module: 'failing'),
          throwsA(isA<HTError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.invoke('answer'), 42);
      _expectRestored(hetu, snapshot);
    });

    test('errors retain their throw-site location after context restoration',
        () {
      final hetu = _createHetu();
      hetu.eval(r'''function fail() {
        assert(false, 'failure')
      }''');
      final snapshot = _ExecutionSnapshot(hetu);

      try {
        hetu.invoke('fail');
        fail('expected an assertion error');
      } on HTError catch (error) {
        expect(error.line, 2);
        expect(error.filename, isNot(snapshot.context.file));
      }
      _expectRestored(hetu, snapshot);
    });

    test('require restores the previous context when loading fails', () {
      final sources = HTOverlayContext();
      sources.addResource('broken.ht', HTSource("throw 'failure'"));
      final hetu = _createHetu(sourceContext: sources);
      final snapshot = _ExecutionSnapshot(hetu);

      expect(() => hetu.require('broken.ht'), throwsA(isA<HTError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.eval('6 * 7'), 42);
    });
  });

  group('exceptional execution restores state', () {
    test('nested script exceptions restore context and stack frames', () {
      final hetu = _createHetu();
      hetu.eval(r'''
        function inner() {
          throw 'failure'
        }
        function outer() {
          inner()
        }
      ''');
      final snapshot = _ExecutionSnapshot(hetu);

      expect(() => hetu.invoke('outer'), throwsA(isA<HTError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.eval('6 * 7'), 42);
    });

    test('exceptions through external callbacks restore every nested call', () {
      final hetu = _createHetu();
      hetu.interpreter.bindExternalFunction('hostInvoke', (
          {positionalArgs, namedArgs}) {
        final callback = positionalArgs.single as HTFunction;
        return callback.call();
      });
      hetu.interpreter.bindExternalFunction('hostThrow', () {
        throw StateError('host failure');
      });
      hetu.eval(r'''
        external function hostInvoke(callback)
        external function hostThrow()
        function inner() {
          hostThrow()
        }
        function outer() {
          hostInvoke(inner)
        }
      ''');
      final snapshot = _ExecutionSnapshot(hetu);

      expect(() => hetu.invoke('outer'), throwsA(isA<StateError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.eval('6 * 7'), 42);
    });

    test('recursive exceptions restore all frames owned by the calls', () {
      final hetu = _createHetu();
      hetu.eval(r'''
        function recurse(value) {
          if (value == 0) {
            throw 'bottom'
          }
          recurse(value - 1)
        }
      ''');
      final snapshot = _ExecutionSnapshot(hetu);

      expect(() => hetu.invoke('recurse', positionalArgs: [4]),
          throwsA(isA<HTError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.eval('6 * 7'), 42);
    });

    test('a rejected awaited future restores the suspended execution state',
        () async {
      final hetu = _createHetu();
      hetu.interpreter.bindExternalFunction(
          'fetchError', () => Future<void>.error(StateError('future failure')));
      hetu.eval(r'''
        external function fetchError()
        function resume() async {
          var local = 42
          await fetchError()
          return local
        }
      ''');
      final snapshot = _ExecutionSnapshot(hetu);

      await expectLater(
          _resolve(hetu.invoke('resume')), throwsA(isA<StateError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.eval('6 * 7'), 42);
    });

    test('an exception after await restores the resumed execution state',
        () async {
      final hetu = _createHetu();
      hetu.interpreter
          .bindExternalFunction('fetchValue', () => Future.value(42));
      hetu.eval(r'''
        external function fetchValue()
        function resume() async {
          var local = await fetchValue()
          throw 'after await'
        }
      ''');
      final snapshot = _ExecutionSnapshot(hetu);

      await expectLater(
          _resolve(hetu.invoke('resume')), throwsA(isA<HTError>()));
      _expectRestored(hetu, snapshot);
      expect(hetu.eval('6 * 7'), 42);
    });
  });
}
