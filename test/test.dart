import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script');
  var hetu = Hetu(
    config: InterpreterConfig(
      checkTypeErrors: true,
      computeConstantExpressionValue: true,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: false,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
    ),
    sourceContext: sourceContext,
  );
  hetu.init(locale: HTLocaleSimplifiedChinese());

  final r = hetu.eval(r'''
    struct B {
      var age = 42
      construct (age: num) {
        this.age = age
      }
    }
    final t = typeof B
    print(t)
    
    type T = {
      age: int
    }
    print(B is T)
  ''');
  // final r = hetu.evalFile('eval.hts');

  print(r);
}
