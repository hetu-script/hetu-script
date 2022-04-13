import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script');
  var hetu = Hetu(
    config: HetuConfig(
      checkTypeErrors: true,
      computeConstantExpressionValue: true,
      showDartStackTrace: true,
      // stackTraceDisplayCountLimit: 20,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: false,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
    ),
    sourceContext: sourceContext,
  );
  hetu.init(locale: HTLocaleSimplifiedChinese());

  hetu.eval(r'''
    class A {
        static fun test(arg: B) {
            arg.toString();
        }

        fun toString() => "Hello from A";
    }

    class B {
        static fun test(arg: A) {
            arg.toString();
        }

        fun toString() => "Hello from B";
    }
    
    print(A.test(B()));
    print(B.test(A()));
  ''');

  // final r = hetu.evalFile('eval.hts');
}
