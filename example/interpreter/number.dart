import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = HT_ASTInterpreter();

  hetu.eval(r'''
      fun main {
        print(System.now)
      }
      ''', invokeFunc: 'main');
}
