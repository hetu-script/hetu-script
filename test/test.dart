import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun main {
        var i = 'hello'
        var j = 'world'
        print(' ${i} ${j}')
      }
      ''', invokeFunc: 'main');
}
