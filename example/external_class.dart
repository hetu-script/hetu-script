import 'package:hetu_script/hetu_script.dart';

class HT_Instance_Person extends HT_Instance {
  final String theName;

  HT_Instance_Person(this.theName, Interpreter interpreter)
      : super(
          interpreter,
          interpreter.fetchGlobal('Person'),
        );
}

void main() async {
  var hetu = await Hetu.create(externalFunctions: {
    'Person': ({List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, HT_Instance instance}) {
      return {'dartValue': 'hello'};
    },
  });
  hetu.eval('''
      external class Person {
        var name = 'jimmy'
      }

      fun main {
        var p = Person()

        print(p.name)
      }
      ''', invokeFunc: 'main');
}
