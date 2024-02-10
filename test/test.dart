import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  var hetu = Hetu(locale: HTLocaleSimplifiedChinese());
  hetu.init();

  final r = hetu.eval(r'''
  class Calculator {
    var x: num
    var y: num

    constructor (x: num, y: num) {
      // 语句块中会覆盖上一级的同名变量，所以这里使用this关键字指定
      this.x = x
      this.y = y
    }
  }

  final c = Calculator()
''');

  if (r != null) {
    if (r is Future) {
      print('async function');
      print(await r);
    } else {
      print(r);
    }
  }
}
