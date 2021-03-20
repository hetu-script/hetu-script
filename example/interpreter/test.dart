import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTAstInterpreter();

  await hetu.init();

  await hetu.eval(r'''
      fun main {
        var s = 'abc'
        pr1nt(s)
      }
      ''', invokeFunc: 'main');
}
