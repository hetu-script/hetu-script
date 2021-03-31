import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    class A {
      static var tables
      static fun init() {
        tables = []
      }
    }
    fun main {
      A.init()
    }

  ''', invokeFunc: 'main');
}
