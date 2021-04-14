import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    fun main {
      let value = ['', 'hello', 'world']
      let item = ''
      for (let val in value) {
        if (val != '') {
          item = val
          break
        }
      }
      print(value)
    }
      ''', invokeFunc: 'main');
}
