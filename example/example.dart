import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HT_Interpreter();

  hetu.eval(r'''
      class Person {
        var name: String = 'some person'
        fun greeting {
          print('Hi!')
        }
      }

      class Jimmy extends Person {
        init {
          name = 'noname'
        }

        init withName(the_name: String) {
          name = the_name
        }

        fun greeting {
          print('Hi! I\'m', name)
        }
      }
      
      fun main {
        
        var j = Jimmy.withName('Jimmy')
        j.greeting()

        var j2 = Jimmy()
        j2.greeting()

      }
      ''', invokeFunc: 'main');
}
