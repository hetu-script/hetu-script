import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var i
    i ??= 42
    print(i)
    ''', isScript: true);
}
