import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      fun closure(func) {
        var i = 42
        fun nested () {
          i = i + 1
          print(func(i))
        }
        return nested
      }

      var func = closure( (n) => n * n )
      func()
      ''');
}
