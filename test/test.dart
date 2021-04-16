import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      fun loop {
        var j = 1
        var i = 0
        for (;;) {
          ++i
          when (i % 2) {
            0 -> j += i
            1 -> j *= i
          }
          if (i > 5) {
            break
          }
        }
        print(j)
      }
    ''', invokeFunc: 'loop');
}
