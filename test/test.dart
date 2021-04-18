import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class Person {
        var age = 17
        var name = 'Jimmy'
        var klass = 'farmer'
      }

      var p = Person.fromJson({'age': 8, 'name': 'Lawrence', 'klass': 'magician'})
      print(p.age)
      print(p.name)
      print(p.klass)
      print(p.toJson())

    ''', codeType: CodeType.script);
}
