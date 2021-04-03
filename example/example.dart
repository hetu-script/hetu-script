import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun closure(func) {
        var i = 42
        fun nested () {
          i = i + 1
          print(func(i))
        }
        return nested
      }

      fun main {
        var func = closure( fun (n) => n * n )
        func()
        func()
      }
      ''', invokeFunc: 'main');
}
