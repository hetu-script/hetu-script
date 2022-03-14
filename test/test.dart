import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu(
    config: InterpreterConfig(
      checkTypeErrors: true,
      computeConstantExpressionValue: true,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: true,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
    ),
  );
  hetu.init(
    locale: HTLocaleSimplifiedChinese(),
  );
  hetu.eval(r'''
        a = 42
        a = "hi"
        print(a)
  ''');
}
