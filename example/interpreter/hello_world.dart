import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTInterpreter();

  await hetu.init();

  await hetu.eval(r'''
      class Person {
        var name: String
        var age: num
        get number { return 42 }
        fun greeting {
          print('Hi! I\'m', name, ', my age is', age)
        }
        fun meaning {
          print('The meaning of life is', number.toString())
        }
      }

      class Jimmy extends Person {
        construct ({name: String = 'Jimmy', age: num = 17}) {
          this.name = name
          this.age = age
        }
      }

      fun main {
        var jimmy = Jimmy()
        print('This is', jimmy.typeid)
        
        var j2 = Jimmy(name: 'j2')
        print(j2.name)

        print(jimmy.name)
      }
      ''', invokeFunc: 'main');
}
