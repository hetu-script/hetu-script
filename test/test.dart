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
        enum Race {
          caucasian,
          mongolian,
          african,
        }
        var race = Race.african
        print(race.toString())
  ''');
}
