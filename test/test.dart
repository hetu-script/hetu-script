import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final a = (a, {b, c}) {}
    print(a)
  ''');
}
