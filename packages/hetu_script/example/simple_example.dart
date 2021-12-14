import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final game = {
      name: 'Bibble',
      job: 'Catcher'
    }
    fun main {
      print(game.keys)

    }
    ''', invokeFunc: 'main');
}
