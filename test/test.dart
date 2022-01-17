import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    for (var i in range(5)) {
      print(i)
    }
  ''');
}
