import 'package:hetu_script/hetu_script.dart';

class Person extends HT_Instance {
  var name;
  Person([this.name = 'jimmy'])
      : super(
          Hetu.itp,
          Hetu.itp.fetchGlobal('Person'),
          isExtern: true,
        );
  dynamic getProperty(String id) {
    switch (id) {
      case 'name':
        return name;
      default:
        throw HTErr_Undefined(id, Hetu.itp.curFileName);
    }
  }
}

void main() async {
  var hetu = await Hetu.create(externalFunctions: {
    'Person': ({List<dynamic> positionalArgs, Map<String, dynamic> namedArgs, HT_Instance instance}) {
      return Person();
    },
  });
  hetu.eval('''
      external class Person {
        var name
      }
      fun main {
        var p = Person()
        print(p.name)
      }
      ''', invokeFunc: 'main');
}
