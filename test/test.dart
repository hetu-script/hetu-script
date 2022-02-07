import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
  fun test2(_, value, [_]) {
    print(value)
  }

  test2(1, 2, 'test2')
  ''');
}
