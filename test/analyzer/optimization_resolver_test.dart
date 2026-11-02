import 'package:hetu_script/optimization/optimization_resolver.dart';
import 'package:hetu_script/optimization/optimization_result.dart';
import 'package:hetu_script/ast/ast.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

HTOptimizationResult _resolve(String content) {
  final hetu = Hetu(config: HetuConfig(normalizeImportPath: false));
  final compilation = hetu.bundle(
    HTSource(content, filename: 'optimization_resolver_test.ht'),
  );
  expect(compilation.errors, isEmpty);
  return HTOptimizationResolver().resolveCompilation(compilation);
}

HTFunctionOptimization _function(HTOptimizationResult result, String name) {
  return result.functions.entries
      .singleWhere((entry) =>
          entry.key is FuncDecl && (entry.key as FuncDecl).id?.id == name)
      .value;
}

List<HTResolvedReference> _references(
  HTOptimizationResult result,
  String name,
) {
  return result.references.entries
      .where((entry) =>
          entry.key is IdentifierExpr &&
          (entry.key as IdentifierExpr).id == name)
      .map((entry) => entry.value)
      .toList();
}

List<HTResolvedVariable> _variables(
  HTOptimizationResult result,
  String name,
) {
  return result.variables.where((variable) => variable.name == name).toList();
}

void main() {
  test('parameters and locals receive function-wide slots', () {
    final result = _resolve(r'''
      var moduleValue = 1
      function sample(param, [optional = 2]) {
        var local = param
        if (true) {
          var shadow = 4
        }
        return local + optional + moduleValue
      }
      function namedSample(value, {named = 3}) {
        return named
      }
    ''');
    final optimization = _function(result, 'sample');

    expect(optimization.localSlotCount, 4);
    expect(optimization.slotNames, {
      0: 'param',
      1: 'optional',
      2: 'local',
      3: 'shadow',
    });
    expect(_function(result, 'namedSample').localSlotCount, 2);
    expect(_references(result, 'named').single.storage,
        HTResolvedStorage.localSlot);
    expect(_references(result, 'param').single.storage,
        HTResolvedStorage.localSlot);
    expect(_references(result, 'moduleValue').single.storage,
        HTResolvedStorage.moduleDeclaration);
  });

  test('shadowed declarations and references keep distinct identities', () {
    final result = _resolve(r'''
      function outer(value) {
        var item = value
        if (true) {
          var item = 2
          item = 3
        }
        return item
      }
    ''');
    final variables = _variables(result, 'item');
    final references = _references(result, 'item');

    expect(variables, hasLength(2));
    expect(variables[0].slot, isNot(variables[1].slot));
    expect(references, hasLength(2));
    expect(identical(references[0].variable, variables[1]), isTrue);
    expect(identical(references[1].variable, variables[0]), isTrue);
  });

  test('nested functions capture only referenced outer variables', () {
    final result = _resolve(r'''
      function outer(x) {
        var y = 1
        function inner(z) {
          return x + y + z
        }
        return inner
      }
    ''');
    final outer = _function(result, 'outer');
    final inner = _function(result, 'inner');
    final x = _variables(result, 'x').single;
    final y = _variables(result, 'y').single;

    expect(outer.capturedVariables, containsAll([x, y]));
    expect(inner.upvalues, containsAll([x, y]));
    expect(_references(result, 'x').single.storage,
        HTResolvedStorage.capturedCell);
    expect(_references(result, 'y').single.storage,
        HTResolvedStorage.capturedCell);
    expect(
        _references(result, 'z').single.storage, HTResolvedStorage.localSlot);
  });

  test('same-named parameters do not cause false captures', () {
    final result = _resolve(r'''
      function outer(x) {
        function inner(x) {
          return x
        }
        return () => x
      }
    ''');
    final outer = _function(result, 'outer');
    final inner = _function(result, 'inner');
    final variables = _variables(result, 'x');

    expect(variables, hasLength(2));
    expect(inner.upvalues, isEmpty);
    expect(inner.capturedVariables, isEmpty);
    expect(outer.capturedVariables, contains(variables[0]));
    expect(variables[1].storage, HTResolvedStorage.localSlot);
  });

  test('module and local recursion use their actual declarations', () {
    final result = _resolve(r'''
      function factorial(n) {
        return n <= 1 ? 1 : n * factorial(n - 1)
      }
      function outer() {
        function recurse(n) {
          return n <= 0 ? 0 : recurse(n - 1)
        }
        return recurse(2)
      }
    ''');

    expect(_references(result, 'factorial').single.storage,
        HTResolvedStorage.moduleDeclaration);
    expect(
      _references(result, 'recurse').every(
          (reference) => reference.storage == HTResolvedStorage.capturedCell),
      isTrue,
    );
    expect(_function(result, 'outer').capturedVariables,
        contains(_variables(result, 'recurse').single));
  });

  test('default parameter references stay in the enclosing scope', () {
    final result = _resolve(r'''
      var fallback = 42
      function withDefault(value, {fallback = fallback}) {
        return fallback
      }
    ''');
    final references = _references(result, 'fallback');

    expect(references, hasLength(2));
    expect(references[0].storage, HTResolvedStorage.moduleDeclaration);
    expect(references[1].storage, HTResolvedStorage.localSlot);
    expect(identical(references[0].variable, references[1].variable), isFalse);
  });

  test('for and for-in expose compiler-style loop bindings', () {
    final result = _resolve(r'''
      function loops() {
        for (var i = 0; i < 3; ++i) {
          final read = () => i
          read()
        }
        for (final item in [1, 2]) {
          final read = () => item
          read()
        }
      }
    ''');
    final loops = result.loopBindings.keys.toList();
    final forLoop = loops.singleWhere((node) => node is ForExpr);
    final forRange = loops.singleWhere((node) => node is ForRangeExpr);
    final forBindings = result.loopBindings[forLoop]!;
    final rangeBindings = result.loopBindings[forRange]!;
    final iReferences = _references(result, 'i');

    expect(forBindings, hasLength(2));
    expect(forBindings[0].name, '__i');
    expect(forBindings[0].isSynthetic, isTrue);
    expect(forBindings[1].name, 'i');
    expect(forBindings[1].slot, isNot(forBindings[0].slot));
    expect(rangeBindings, hasLength(2));
    expect(rangeBindings[0].name, '__iterator');
    expect(rangeBindings[1].name, 'item');
    expect(iReferences, hasLength(3));
    expect(identical(iReferences[0].variable, forBindings[0]), isTrue);
    expect(identical(iReferences[1].variable, forBindings[0]), isTrue);
    expect(identical(iReferences[2].variable, forBindings[1]), isTrue);
    expect(forBindings[1].storage, HTResolvedStorage.capturedCell);
    expect(rangeBindings[1].storage, HTResolvedStorage.capturedCell);
    expect(_function(result, 'loops').localSlotCount, 6);
  });

  test('class members and unresolved accesses fall back to dynamic', () {
    final result = _resolve(r'''
      var moduleValue = 1
      class Box {
        var field = 1
        function method(param) {
          var local = param
          return field + local + unknown + moduleValue
        }
      }
      function read() {
        final obj = {value: 1}
        return obj.value
      }
    ''');

    expect(
        _references(result, 'field').single.storage, HTResolvedStorage.dynamic);
    expect(_references(result, 'local').single.storage,
        HTResolvedStorage.localSlot);
    expect(_references(result, 'unknown').single.storage,
        HTResolvedStorage.dynamic);
    expect(_references(result, 'moduleValue').single.storage,
        HTResolvedStorage.moduleDeclaration);
    expect(_references(result, 'value'), isEmpty);
  });

  test('delete retains a dynamic operation and a declaration reference', () {
    final result = _resolve(r'''
      function remove() {
        var value = 1
        delete value
        return value
      }
    ''');
    final operation = result.dynamicOperations.single;
    final variable = _variables(result, 'value').single;

    expect(operation, isA<DeleteStmt>());
    expect(result.references[operation]?.variable, same(variable));
    expect(result.references[operation]?.storage, HTResolvedStorage.localSlot);
  });

  test('return, throw, assertion and struct closures are all visited', () {
    final result = _resolve(r'''
      function outer(value) {
        final fn = () {
          throw value
        }
        final obj = {result: () => value}
        assert(true, value)
        return () => value
      }
    ''');
    final references = _references(result, 'value');

    expect(references, hasLength(4));
    expect(_function(result, 'outer').capturedVariables,
        contains(_variables(result, 'value').single));
  });

  test(
      'namespaces, imports, structs and external declarations stay conservative',
      () {
    final sourceContext = HTOverlayContext();
    sourceContext.addResource(
      'other.ht',
      HTSource('var imported = 1', filename: 'other.ht'),
    );
    final hetu = Hetu(
      sourceContext: sourceContext,
      config: HetuConfig(normalizeImportPath: false),
    );
    final compilation = hetu.bundle(
      HTSource(
        r'''
          import 'other.ht' as other
          namespace Sample {
            function helper() {
              return unknown
            }
          }
          struct Point {
            var x
            function read() {
              return x
            }
          }
          external function externalFunction(value)
          function run() {
            return other.imported + externalFunction(1)
          }
        ''',
        filename: 'entry.ht',
      ),
    );
    expect(compilation.errors, isEmpty);
    final result = HTOptimizationResolver().resolveCompilation(compilation);

    expect(_references(result, 'other').single.storage,
        HTResolvedStorage.moduleDeclaration);
    expect(_references(result, 'externalFunction').single.storage,
        HTResolvedStorage.moduleDeclaration);
    expect(_references(result, 'unknown').single.storage,
        HTResolvedStorage.dynamic);
    expect(_references(result, 'x').single.storage, HTResolvedStorage.dynamic);
    expect(_references(result, 'imported'), isEmpty);
  });
}
