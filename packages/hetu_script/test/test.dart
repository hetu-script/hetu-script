import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    var obj = {
      a: 1,
      b: 23,
      c: 42,
    }
    for (var i of obj) {
      print(i)
    }
  ''', isScript: true);
}
