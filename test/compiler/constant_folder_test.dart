import 'dart:typed_data';

import 'package:hetu_script/ast/ast.dart';
import 'package:hetu_script/constant/constant_folder.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/optimization/optimization_result.dart';
import 'package:test/test.dart';

HetuConfig _config({bool folded = false, bool staticAnalysis = false}) {
  return HetuConfig(
    normalizeImportPath: false,
    computeConstantExpression: folded,
    doStaticAnalysis: staticAnalysis,
  );
}

Uint8List _compile(String source, {bool folded = false}) {
  return Hetu(config: _config(folded: folded)).compile(source);
}

dynamic _invoke(
  Uint8List bytes,
  String module,
  String function, {
  List<dynamic> positionalArgs = const [],
}) {
  final hetu = Hetu(config: _config());
  hetu.init();
  hetu.loadBytecode(bytes: bytes, module: module);
  return hetu.invoke(function, positionalArgs: positionalArgs);
}

void main() {
  test('constant identifiers and arithmetic emit smaller bytecode', () {
    const source = r'''
      const base = 2
      function folded() {
        return base * 3 + 4
      }
      function dynamic(value) {
        return value * 3 + 4
      }
    ''';
    final disabled = _compile(source);
    final enabled = _compile(source, folded: true);

    expect(enabled.length, lessThan(disabled.length));
    expect(_invoke(enabled, 'arithmetic', 'folded'), 10);
    expect(_invoke(enabled, 'arithmetic', 'dynamic', positionalArgs: [4]), 16);
  });

  test('short-circuit operators and ternary evaluate only the selected branch',
      () {
    const source = r'''
      function andValue() {
        return false && 1 ~/ 0 == 0 ? 100 : 2
      }
      function orValue() {
        return true || 1 ~/ 0 == 0 ? 3 : 100
      }
      function coalesceValue() {
        return 6 ?? 2
      }
      function ternaryValue() {
        return true ? 42 : 1 ~/ 0
      }
    ''';
    final bytes = _compile(source, folded: true);

    expect(_invoke(bytes, 'short_circuit', 'andValue'), 2);
    expect(_invoke(bytes, 'short_circuit', 'orValue'), 3);
    expect(_invoke(bytes, 'short_circuit', 'coalesceValue'), 6);
    expect(_invoke(bytes, 'short_circuit', 'ternaryValue'), 42);
  });

  test('division by zero and side effects are not folded', () {
    const source = r'''
      var calls = 0
      function invalid() {
        return 1 ~/ 0
      }
      function next() {
        ++calls
        return 1
      }
      function dynamic() {
        return next() + 1
      }
    ''';
    final bytes = _compile(source, folded: true);

    expect(() => _invoke(bytes, 'side_effects', 'invalid'),
        throwsA(isA<HTError>()));
    expect(_invoke(bytes, 'side_effects', 'dynamic'), 2);
  });

  test('constant identifiers and string interpolation fold safely', () {
    const source = r'''
      const name = '世界'
      const base = 2
      const multiplied = base * 3
      function text() {
        return 'hello-${name}-${multiplied + 4}'
      }
      function escaped() {
        return 'line\n${6 * 7}'
      }
    ''';
    final disabled = _compile(source);
    final enabled = _compile(source, folded: true);

    expect(enabled.length, lessThan(disabled.length));
    expect(_invoke(enabled, 'strings', 'text'), 'hello-世界-10');
    expect(_invoke(enabled, 'strings', 'escaped'), 'line\n42');
  });

  test('null, dynamic values and collection literals retain runtime behavior',
      () {
    const source = r'''
      function dynamic(value) {
        return value * 3 + 4
      }
      function nil() {
        return null
      }
      function list() {
        return [1, 2]
      }
      function object() {
        return {value: 1}
      }
      final firstList = list()
      final secondList = list()
      final firstObject = object()
      final secondObject = object()
      function identities() {
        return [firstList == secondList, firstObject == secondObject]
      }
    ''';
    final bytes = _compile(source, folded: true);

    expect(
        _invoke(bytes, 'dynamic_values', 'dynamic', positionalArgs: [4]), 16);
    expect(_invoke(bytes, 'dynamic_values', 'nil'), isNull);
    expect(_invoke(bytes, 'dynamic_values', 'identities'), [false, false]);
  });

  test('cyclic const declarations fall back without new compile errors', () {
    const source = r'''
      const first = second
      const second = first
      function read() {
        return first
      }
    ''';
    final bytes = _compile(source, folded: true);

    expect(() => _invoke(bytes, 'cycles', 'read'), throwsA(anything));
  });

  test('folding also works when static analysis is explicitly enabled', () {
    const source = r'''
      const answer = 6 * 7
      function run() {
        return answer
      }
    ''';
    final bytes = Hetu(config: _config(folded: true, staticAnalysis: true))
        .compile(source);

    expect(_invoke(bytes, 'static_analysis', 'run'), 42);
  });

  test('folding is enabled by default and can be explicitly disabled', () {
    const source = r'''
      function answer() {
        return 6 * 7
      }
    ''';
    final config = HetuConfig();
    final enabled = Hetu(config: config).compile(source);
    final disabled = _compile(source, folded: false);

    expect(config.computeConstantExpression, isTrue);
    expect(enabled.length, lessThan(disabled.length));
    expect(_invoke(enabled, 'default_enabled', 'answer'), 42);
  });

  test('constant null is distinct from an unfodable expression', () {
    final optimization = HTOptimizationResult();
    final folder = HTConstantFolder();
    final constantNull = folder.fold(ASTLiteralNull(), optimization);

    expect(constantNull, isA<HTConstantValue>());
    expect(constantNull!.value, isNull);
    expect(folder.fold(IdentifierExpr('dynamic'), optimization), isNull);

    const source = r'''
      const nil = null
      function readNull() {
        return nil
      }
      function coalesce() {
        return nil ?? 42
      }
      function equal() {
        return nil == null
      }
    ''';
    final disabled = _compile(source);
    final enabled = _compile(source, folded: true);

    expect(enabled.length, lessThan(disabled.length));
    expect(_invoke(enabled, 'constant_null', 'readNull'), isNull);
    expect(_invoke(enabled, 'constant_null', 'coalesce'), 42);
    expect(_invoke(enabled, 'constant_null', 'equal'), isTrue);
  });

  test('member access is not folded even when its object is const', () {
    const source = r'''
      const point = {x: 1}
      function read() {
        return point.x
      }
    ''';
    final bytes = _compile(source, folded: true);

    expect(_invoke(bytes, 'members', 'read'), 1);
  });
}
