import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    class A {
      static fun _init {
        print('private _init called!')
      }
      fun _post {
        print('private _post called!')
      }

      fun init {
        A._init()
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
