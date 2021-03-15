import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HT_Interpreter();

  hetu.eval(r'''
      fun closure(func) {
        var i = 42
        return fun () { print(func(i)) }
      }

      fun main {
        var func = closure( fun (n) { return n * n } )
        func()
      }
      ''', invokeFunc: 'main');
}
