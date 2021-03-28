import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun main() {
        var i1 = 100
        var i2 = 200
        var a = i1
        if (true) {
          a = i2
        }
        print(a, i1, i2)
      }
    ''', invokeFunc: 'main');
}
