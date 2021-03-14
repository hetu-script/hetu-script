import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HT_Interpreter();

  hetu.eval(r'''
      class Person {
        var name: String
        var age: num
        construct ([name: String = 'Jimmy', age: num = 42]) {
          this.name = name
          this.age = age
        }
        fun greeting {
          print('Hi! I\'m', name, ', my age is', age)
        }
        fun meaning {
          print('The meaning of life is', (6 * 7).toString())
        }
      }

      fun main {
        var jimmy = Person('Jimmy')
        jimmy.greeting()
      }
      ''', invokeFunc: 'main');
}
