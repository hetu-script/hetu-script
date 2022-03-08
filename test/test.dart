import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu(
    config: InterpreterConfig(
      checkTypeErrors: true,
      computeConstantExpressionValue: true,
      strictMode: true,
    ),
  );
  hetu.init(
    locale: HTLocaleSimplifiedChinese(),
  );
  hetu.eval(r'''
    const i = 42
    const j = 3 * i
    print(j)
  ''');
}
