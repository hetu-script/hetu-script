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

HTFunction _function(Hetu hetu, String name) {
  return hetu.fetch(name) as HTFunction;
}

void main() {
  test('eligible functions use call scopes and uncaptured closures', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function optimized(value) {
        var result = value
        if (true) {
          var shadow = 2
          result += shadow
        }
        return result
      }
      function uncaptured() {
        final add = (value) => value + 1
        return add(2)
      }
      function captured(value) {
        return () => value
      }
    ''');
    final optimized = _function(hetu, 'optimized');
    final uncaptured = _function(hetu, 'uncaptured');
    final captured = _function(hetu, 'captured');

    expect(optimized.callScopeSlotCount, 3);
    expect(optimized.callScopeSlotNames, ['value', 'result', 'shadow']);
    expect(uncaptured.callScopeSlotCount, 1);
    expect(captured.callScopeSlotCount, 1);
    expect(captured.callScopeCapturedSlots, [0]);
    expect(hetu.invoke('optimized', positionalArgs: [40]), 42);
    expect(hetu.invoke('uncaptured'), 3);
  });

  test('slot declarations preserve immutability and missing initializers', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function immutable() {
        final value = 1
        value = 2
        return value
      }
      function missingInitializer() {
        var value
        return value
      }
    ''');

    expect(_function(hetu, 'immutable').callScopeSlotCount, 1);
    expect(_function(hetu, 'missingInitializer').callScopeSlotCount, 1);
    expect(() => hetu.invoke('immutable'), throwsA(isA<HTError>()));
    expect(hetu.invoke('missingInitializer'), isNull);
  });

  test('default, named and variadic parameters use their original semantics',
      () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function withDefault({value = 1}) {
        return value
      }
      function sum(...values) {
        var total = 0
        for (final value in values) {
          total += value
        }
        return total
      }
    ''');

    expect(_function(hetu, 'withDefault').callScopeSlotCount, 1);
    expect(hetu.invoke('withDefault'), 1);
    expect(hetu.invoke('withDefault', namedArgs: {'value': 2}), 2);
    expect(hetu.invoke('sum', positionalArgs: [1, 2, 3]), 6);
  });

  test('local functions and module recursion work with call scopes', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function outer() {
        function inner(value) {
          return value + 1
        }
        return inner(2)
      }
      function sumDown(n) {
        if (n <= 0) {
          return 0
        }
        var value = n
        return value + sumDown(n - 1)
      }
    ''');

    expect(_function(hetu, 'outer').callScopeSlotCount, 1);
    expect(_function(hetu, 'sumDown').callScopeSlotCount, 2);
    expect(hetu.invoke('outer'), 3);
    expect(hetu.invoke('sumDown', positionalArgs: [3]), 6);
  });

  test('for and for-in loops use synthetic slot bindings', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function sum(n) {
        var total = 0
        for (var i = 0; i < n; ++i) {
          total += i
        }
        for (final item in [1, 2, 3]) {
          total += item
        }
        return total
      }
    ''');
    final function = _function(hetu, 'sum');

    expect(function.callScopeSlotCount, 6);
    expect(function.callScopeSlotNames, [
      'n',
      'total',
      '__i',
      'i',
      '__iterator',
      'item',
    ]);
    expect(hetu.invoke('sum', positionalArgs: [4]), 12);
  });

  test('captured locals use cells while deleted and late locals stay generic',
      () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function captured(value) {
        return () => value
      }
      function deleted() {
        var value = 1
        delete value
        return value
      }
      function lateValue() {
        late value
        value = 1
        return value
      }
    ''');

    expect(_function(hetu, 'captured').callScopeSlotCount, 1);
    expect(_function(hetu, 'deleted').callScopeSlotCount, isNull);
    expect(_function(hetu, 'lateValue').callScopeSlotCount, isNull);
    expect(() => hetu.invoke('deleted'), throwsA(isA<HTError>()));
    expect(hetu.invoke('lateValue'), 1);
  });

  test('uint16 slots support more than 255 local declarations', () {
    final declarations = StringBuffer();
    for (var i = 0; i < 300; ++i) {
      declarations.writeln('var value$i = $i');
    }
    final hetu = _createHetu();
    hetu.eval('''
      function manySlots() {
        $declarations
        return value299
      }
    ''');
    final function = _function(hetu, 'manySlots');

    expect(function.callScopeSlotCount, 300);
    expect(function.callScopeSlotNames[299], 'value299');
    expect(hetu.invoke('manySlots'), 299);
  });

  test('declaration expressions preserve configured result values', () {
    final hetu = Hetu(
      config: HetuConfig(
        normalizeImportPath: false,
        allowInitializationExpresssionHaveValue: true,
      ),
    );
    hetu.init();
    hetu.eval(r'''
      function declarationValue() {
        var value = 42
      }
    ''');

    expect(_function(hetu, 'declarationValue').callScopeSlotCount, 1);
    expect(hetu.invoke('declarationValue'), 42);
  });

  test('runtime type checking retains the generic namespace path', () {
    final hetu = Hetu(
      config: HetuConfig(
        normalizeImportPath: false,
        checkTypeAnnotationAtRuntime: true,
      ),
    );
    hetu.init();
    hetu.eval(r'''
      function typed(value: int) {
        var result = value
        return result
      }
    ''');

    expect(_function(hetu, 'typed').callScopeSlotCount, isNull);
    expect(hetu.invoke('typed', positionalArgs: [1]), 1);
  });

  test('function clones retain call scope metadata and bytecode version', () {
    final hetu = _createHetu();
    hetu.eval(r'''
      function identity(value) {
        return value
      }
    ''');
    final function = _function(hetu, 'identity');
    final clone = function.clone();

    expect(clone.callScopeSlotCount, function.callScopeSlotCount);
    expect(clone.callScopeSlotNames, function.callScopeSlotNames);
    expect(kHetuVersion.toString(), '0.7.1');
  });
}
