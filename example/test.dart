import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    class Person {
      var property = []
      construct {
        fill()
      }
      fun fill {
        for (var i = 0; i < 4; ++i) {
          property.add(i)
        }
      }
    }
    fun main {
      var p1 = Person()
      print(p1.property)
      var p2 = Person()
      print(p2.property)
    }

  ''', invokeFunc: 'main');
}
