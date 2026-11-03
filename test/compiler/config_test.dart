import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/values.dart';
import 'package:test/test.dart';

const _foldableSource = r'''
  function run() {
    return 6 * 7
  }
''';

Hetu _createHetu({
  bool computeConstantExpression = false,
  HTOverlayContext? sourceContext,
}) {
  final hetu = Hetu(
    config: HetuConfig(
      normalizeImportPath: false,
      processError: false,
      computeConstantExpression: computeConstantExpression,
    ),
    sourceContext: sourceContext,
  );
  hetu.init();
  return hetu;
}

void main() {
  test('initialization config enables folding by default and allows disabling',
      () {
    final defaultCompiler = _createHetu(computeConstantExpression: true);
    final disabledCompiler = _createHetu();

    final enabled = defaultCompiler.compile(_foldableSource);
    final disabled = disabledCompiler.compile(_foldableSource);

    expect(defaultCompiler.config.computeConstantExpression, isTrue);
    expect(enabled.length, lessThan(disabled.length));
  });

  test('the public default initialization config enables folding', () {
    final hetu = Hetu();

    expect(hetu.config.computeConstantExpression, isTrue);
  });

  group('per-call config overrides only one compilation', () {
    test('constant folding override does not change subsequent compilations',
        () {
      final hetu = _createHetu();
      final disabled = hetu.compile(_foldableSource);

      final enabled = hetu.compile(
        _foldableSource,
        config: CompilerConfig(computeConstantExpression: true),
      );
      final next = hetu.compile(_foldableSource);

      expect(enabled.length, lessThan(disabled.length));
      expect(next.length, disabled.length);
      expect(hetu.config.computeConstantExpression, isFalse);
    });

    test('line info override does not change subsequent compilations', () {
      final hetu = _createHetu();
      final withLines = hetu.compile(_foldableSource);

      final withoutLines = hetu.compile(
        _foldableSource,
        config: CompilerConfig(removeLineInfo: true),
      );
      final next = hetu.compile(_foldableSource);

      expect(withoutLines.length, lessThan(withLines.length));
      expect(next.length, withLines.length);
      expect(hetu.config.removeLineInfo, isFalse);
    });

    test('assertion override applies once without changing later failures', () {
      final hetu = _createHetu();
      const source = r'''
        function run() {
          assert(false, 'expected failure')
          return 42
        }
      ''';
      final withoutAssertions = hetu.compile(
        source,
        config: CompilerConfig(removeAssertion: true),
      );

      hetu.loadBytecode(bytes: withoutAssertions, module: 'without_assertions');
      expect(hetu.invoke('run', module: 'without_assertions'), 42);

      final withAssertions = hetu.compile(source);
      hetu.loadBytecode(bytes: withAssertions, module: 'with_assertions');
      expect(() => hetu.invoke('run', module: 'with_assertions'),
          throwsA(isA<HTError>()));
      expect(hetu.config.removeAssertion, isFalse);
    });

    test('documentation override does not change subsequent compilations', () {
      final hetu = _createHetu();
      const source = r'''
        /// A documentation comment that is retained by default.
        function run() {
          return 42
        }
      ''';
      final withDocumentation = hetu.compile(source);

      final withoutDocumentation = hetu.compile(
        source,
        config: CompilerConfig(removeDocumentation: true),
      );
      final next = hetu.compile(source);

      expect(withoutDocumentation.length, lessThan(withDocumentation.length));
      expect(next.length, withDocumentation.length);
      expect(hetu.config.removeDocumentation, isFalse);
    });

    test('runtime type checking override changes only the selected function',
        () {
      final hetu = _createHetu();
      final checked = hetu.compile(
        _foldableSource,
        config: CompilerConfig(checkTypeAnnotationAtRuntime: true),
      );

      hetu.loadBytecode(bytes: checked, module: 'checked');
      final checkedFunction =
          hetu.fetch('run', module: 'checked') as HTFunction;
      expect(checkedFunction.callScopeSlotCount, isNull);

      final unchecked = hetu.compile(_foldableSource);
      hetu.loadBytecode(bytes: unchecked, module: 'unchecked');
      final uncheckedFunction =
          hetu.fetch('run', module: 'unchecked') as HTFunction;
      expect(uncheckedFunction.callScopeSlotCount, isNotNull);
      expect(hetu.config.checkTypeAnnotationAtRuntime, isFalse);
    });

    test('compileFile honors per-call config without retaining the override',
        () {
      final sources = HTOverlayContext();
      sources.addResource('config.ht', HTSource(_foldableSource));
      final hetu = _createHetu(sourceContext: sources);
      final withLines = hetu.compileFile('config.ht');

      final withoutLines = hetu.compileFile(
        'config.ht',
        config: CompilerConfig(removeLineInfo: true),
      );
      final next = hetu.compileFile('config.ht');

      expect(withoutLines.length, lessThan(withLines.length));
      expect(next.length, withLines.length);
      expect(hetu.config.removeLineInfo, isFalse);
    });
  });
}
