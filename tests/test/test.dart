import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      var a = {
        age: 17,
        meaning: 42
      }
      print(a)
      delete a['meaning']
      print(a)
    ''');
}
