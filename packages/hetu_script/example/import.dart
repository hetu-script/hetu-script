import 'package:hetu_script/hetu_script.dart';

void main() {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      // doStaticAnalysis: true,
      // computeConstantExpression: true,
      showDartStackTrace: true,
      // stackTraceDisplayCountLimit: 20,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: false,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
      normalizeImportPath: false,
    ),
    sourceContext: sourceContext,
  );
  hetu.init(locale: HTLocaleSimplifiedChinese());

  final source1 = HTSource(r'''
    final text = 'hello world!'
''', fullName: 'source1.ht');
  final source2 = HTSource(r'''
    export 'source1.ht'
    export { greeting }
    fun greeting {
      print(text)
    }
''', fullName: 'source2.ht');
  final source3 = HTSource(r'''
    import 'source2.ht'
    fun main {
      greeting()
      print(text)
    }
''', fullName: 'source3.ht');
  sourceContext.addResource(source1.fullName, source1);
  sourceContext.addResource(source2.fullName, source2);
  sourceContext.addResource(source3.fullName, source3);

  hetu.evalFile('source3.ht', invokeFunc: 'main');
}
