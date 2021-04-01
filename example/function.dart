import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    class Name {
      fun toString => 'noname'
    }
    fun main {
      var a = Name()
      print(a)
    }
  ''', invokeFunc: 'main');
}
