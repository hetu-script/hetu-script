import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = await Hetu.init();

  hetu.eval('''
      class Person {
        var name: any = 'some person'
        fun greeting {
          print("Hi!")
        }
      }

      class Jimmy extends Person {
        init withName(the_name: any) {
          name = the_name
        }

        fun greeting {
          print("Hi! I'm", name)
        }
      }
      
      fun main {
        
        var j = Jimmy.withName('Jimmy')
        j.greeting()

      }
      ''', invokeFunc: 'main');
}
