import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  final result = await hetu.eval('''
    import 'script/tool/person.ht'
    import 'script/tool/beauty.ht'

    class Jimmy extends Person {
      var age = 17
      construct {
        name = 'Jimmy'
      }
      fun greeting {
        print("Hi! I'm", name)
      }
    }

    fun importTest {
      var cal = Calculator(6, 7)

      var j = Jimmy()

      // print(cal.meaning())

      return (getBeauty(cal.meaning(), j.age, 100))

    }
    ''', invokeFunc: 'importTest');
  print(result);
}
