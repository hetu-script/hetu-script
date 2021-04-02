import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun main {
        var n = 3
        var c = 2
        var r = 3
        var f = 5
        n = n - (c * r - f)
        print(n)
      }
  ''', invokeFunc: 'main');
}
