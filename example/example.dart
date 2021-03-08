import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init();

  hetu.eval('''
      class Person {
        var name: String = 'some person'
        fun greeting {
          print("Hi! I'm", name)
        }
      }

      class Jimmy extends Person {
        construct (the_name: String) {
          name = the_name
        }

        fun greeting {
          print("Hi! I'm", name)
        }
      }
      
      fun main {

        var p = Person()
        p.greeting()
        
        var j = Jimmy('Jimmy')
        j.greeting()

      }
      ''', invokeFunc: 'main');
}
