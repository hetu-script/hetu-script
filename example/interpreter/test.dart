import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTInterpreter();

  await hetu.init();

  await hetu.eval(r'''
      fun main {
        print(42.typeid)
      }
      ''', invokeFunc: 'main');
}
