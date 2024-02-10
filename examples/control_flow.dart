import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var j = 1
    var i = 0
    for (;;) {
      ++i
      switch (i % 2) {
        0 => j += i
        1 => j *= i
      }
      if (i > 5) {
        break
      }
    }
    print(i)
    print(j)
  ''');
}
