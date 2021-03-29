import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun getIndex {
        return 2
      }

      class Person {
        var age = 12
      }

      fun main {
        var tables = { 'weapon': [1,2,3] }
        var rows = tables['weapon'];
        var i = getIndex()
        print(rows[i])

      }
    ''', invokeFunc: 'main');
}
