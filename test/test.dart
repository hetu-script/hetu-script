import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final r = hetu.eval(r'''
      var name = when (2) {
        1 -> 'never'
        2 -> 'yay!'
      }

      print(name)
  ''');

  print(r);
}
