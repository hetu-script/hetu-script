import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class Super {
        var name = 'Super'
      }
      class Extend extends Super {
        var name = 'Extend'
      }
      fun main {
        var a = Extend()
        var b = a as Super
        print(b.name)
        
      }
      ''', invokeFunc: 'main');
}
