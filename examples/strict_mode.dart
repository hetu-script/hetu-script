import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: true,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
    ),
    locale: HTLocaleSimplifiedChinese(),
  );
  hetu.init();
  hetu.eval(r'''
  print(typeof 42.0)
  ''');
}
