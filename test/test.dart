import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    for (final i in range(1, 10)) {
      print(i)
    }
  ''');
}
