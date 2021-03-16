import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HTInterpreter();

  hetu.eval(r'''
      fun closure(func) {
        var i = 42
        return fun () {
          i = i + 1
          print(func(i))
        }
      }

      fun main {
        var func = closure( fun (n) { return n * n } )
        func()
        func()
      }
      ''', invokeFunc: 'main');
}
