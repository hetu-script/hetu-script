import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final ss = Map()
    ss[1] = 2
    print(ss)
  ''');
}
