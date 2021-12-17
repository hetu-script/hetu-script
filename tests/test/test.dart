import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
<<<<<<< HEAD
      class Person {
        var _name
        construct (name) {
          _name = name
        }
        fun greeting {
          print('Hi, I\'m ', _name)
        }
      }
      final p = Person('jimmy')
      // Error!
      // print(p._name)
      p.greeting()
    ''', isModule: true);
=======
      var a // a is null
      final value = a?.collection.dict.value // value is null and we won't get errors
      print(value)
    ''');
>>>>>>> 8088931f8cb3f7549b089e54de9363c527bdd4e4
}
