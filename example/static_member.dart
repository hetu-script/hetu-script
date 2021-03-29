import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class A {
        static var field: str
        construct ([field: str = 'a']) {
          this.field = field
        }
        static fun a {
          print(field)
        }
        fun b {
          a()
        }
      }

      fun main {
        var a = A()
        a.b()
      }
      ''', invokeFunc: 'main');
}
