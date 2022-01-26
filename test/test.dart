import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    fun test(t) {
      return when (t) {
        1 -> {'odd'}
        2 -> {'even'}
      }
    }
    print(test(2))
  ''');
}
