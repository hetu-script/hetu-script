import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    class A {
      static fun _init {
        print('private static _init called!')
      }
      fun _post {
        print('private instance _post called!')
      }
      fun init {
        _init()
        _post()
      }
    }
    fun main {
      var a = A()
      a.init()
      // a._post() // erorr!
    }

  ''', invokeFunc: 'main');
}
