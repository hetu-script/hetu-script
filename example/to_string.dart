import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.module));

  await hetu.init();

  await hetu.eval(r'''
    class Name {
      var firstName = 'Adam'
      var familyName = 'Christ'
      fun toString {
        return '${firstName} ${familyName}'
      }
    }
    class Person {
      fun greeting {
        return 6 * 7
      }
      var name = Name()
    }
    fun main {
      var j = Person()
      var i
      j.name.familyName = i = 'Luke'
      print(j.name) // Will use overrided toString function in user's class
    }
  ''', invokeFunc: 'main');
}
