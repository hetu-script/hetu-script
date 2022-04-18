import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script');
  final sourceContext2 = HTOverlayContext();
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
    sourceContext: sourceContext2,
  );
  hetu.init(locale: HTLocaleSimplifiedChinese());

//   final source1 = HTSource(r'''
//     final text = 'hello world!'
// ''', fullName: 'source1.ht');
//   final source2 = HTSource(r'''
//     export 'source1.ht'
//     export { greeting }
//     fun greeting {
//       print(text)
//     }
// ''', fullName: 'source2.ht');
//   final source3 = HTSource(r'''
//     import 'source2.ht'
//     fun main {
//       greeting()
//       print(meaning)
//     }
// ''', fullName: 'source3.ht');
//   sourceContext2.addResource(source1.fullName, source1);
//   sourceContext2.addResource(source2.fullName, source2);
//   sourceContext2.addResource(source3.fullName, source3);

//   final r = hetu.evalFile('source3.ht', invokeFunc: 'main');

  // final r = hetu.evalFile('eval.hts');
  // print(hetu.lexicon.stringify(r));

  hetu.eval(r'''
    class A {
      construct {
        print('constructing A')
      }
    }
    class B extends A {
      construct {
        print('constructing B')
      }
    }
    final b = B()
  ''');
}
