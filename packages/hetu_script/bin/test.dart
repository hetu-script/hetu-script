import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    fun main {
      var ht = {
        name: 'Jimmy',
        greeting: () {
          print('Hi! I\'m', this.name)
        }
      }
      print(ht.toString())
    }
  ''', invokeFunc: 'main');
}
