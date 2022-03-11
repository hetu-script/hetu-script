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
    struct P {
      var name = 'guy'
      var age = 17 
    }

    final p1 = struct extends P {}
    final p2 = {}
    p2.$prototype = P

    print(p2.$prototype)
    print(p2.age)
  ''');
}
