import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
  class Super {
    var name = 'super'
  }

  fun main {
    var a = Super()
    print(a.name)
  }

      ''', invokeFunc: 'main');
}
