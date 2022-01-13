import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    for (final i in range(0, 10)) {
      when (i) {
        0 -> {
          print('number: 0')
        }
        2, 3, 5, 7 -> {
          print('prime: ${i}')
        }
        in [4, 9] -> {
          print('square: ${i}')
        }
        else -> {
          print('other: ${i}')
        }
      }
    }
  ''');
}
