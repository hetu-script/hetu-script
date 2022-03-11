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
    class R {
      get meaning => 42
    }

    class P extends R {
      get meaning {
        return super.meaning * 2
      }
    }

    final p= P()
    print(p.meaning)
  ''');
}
