import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu()..strictMode = true;
  hetu.init(externalFunctions: {
    'Person.type': () {
      return 'person type getter';
    }
  });
  hetu.eval(r'''
    class Person {
      external static fun type
    }

    // final p = Person()
    print(Person.type())
  ''');
}
