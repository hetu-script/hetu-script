import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final game = { };
    fun main {
      print(game)

    }
    ''', invokeFunc: 'main');
}
