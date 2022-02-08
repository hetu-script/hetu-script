import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var a = 1
    var b = 2
    [a,b] = [b,a]
  ''');
}
