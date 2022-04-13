import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script');
  final sourceContext2 = HTOverlayContext();
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
    sourceContext: sourceContext2,
  );
  hetu.init(locale: HTLocaleSimplifiedChinese());

//   final source1 = HTSource(r'''
//     fun greeting {
//       return 'hello world!'
//     }
// ''', fullName: 'source1.ht');
//   final source2 = HTSource(r'''
//     export 'source1.ht'
//     final meaning = 42
//     export { meaning }
// ''', fullName: 'source2.ht');
//   final source3 = HTSource(r'''
//     import 'source2.ht'
//     fun main {
//       print(greeting())
//       print(meaning)
//       var a = 5
//       var a = 52
//       print(a)
//     }
// ''', fullName: 'source3.ht');
//   sourceContext2.addResource(source1.fullName, source1);
//   sourceContext2.addResource(source2.fullName, source2);
//   sourceContext2.addResource(source3.fullName, source3);

//   final r = hetu.evalFile('source3.ht', invokeFunc: 'main');
  hetu.eval(r'''
  var a = 42
''');
  hetu.eval(r'''
  var a = 42
''');

  // final r = hetu.evalFile('eval.hts');
  // print(hetu.lexicon.stringify(r));
}
