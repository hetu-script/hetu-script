import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
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
        struct P {
          var name = 'Jimmy'
        }
        final p = new P
        print(p)
  ''');
}
