import 'package:hetu_script/hetu_script.dart';

void main() {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      compileWithoutLineInfo: false,
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
    var name = 'Richard Byson'
    var _age = 42
''', fullName: 'source1.ht');
  final source2 = HTSource(r'''
    export 'source1.ht'
    export { greeting }
    var _age = 42
    fun greeting(a, b) {
      if (a?.aaa == null) {
        // assert(name == null)
      }
      print(name)
    }
// ''', fullName: 'source2.ht');
  final source3 = HTSource(r'''
    fun tutorial {
      print('a guide to use Hetu')
    }
''', fullName: 'source3.ht');
  sourceContext.addResource(source1.fullName, source1);
  sourceContext.addResource(source2.fullName, source2);
  sourceContext.addResource(source3.fullName, source3);

//   final r = hetu.evalFile('source3.ht', invokeFunc: 'main');

  // final r = hetu.evalFile('eval.hts');
  // print(hetu.lexicon.stringify(r));

  final r = hetu.eval(r'''
    // final { name, age } = require('source1.ht');
    // print(name, age)
    import 'source2.ht' as nsp
    nsp.greeting()

    final s3 = require('source3.ht')
    s3.tutorial()
  ''');

  print(hetu.lexicon.stringify(r));
}
