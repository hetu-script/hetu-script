import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
  fun main {
    var obj = {
      1: "tom",
      2: "jimmy",
      3: "jerry",
      4: "ted",
      5: "larry",
    }
    var i = 0
    for (;;) {
      ++i
      if ((i % 2) == 0) {
        print(i)
      }
      if (i > 10) {
        break
      }
    }
  }
  ''', invokeFunc: 'main');
}
