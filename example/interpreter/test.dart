import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HTInterpreter();

  hetu.eval(r'''
      fun main {
        print(42.typeid)
      }
      ''', invokeFunc: 'main');
}
