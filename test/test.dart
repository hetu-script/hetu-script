import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''

    final iter = 'Hello, world!'.characters.iterator;
    while (iter.moveNext()) {
      print(iter.current);
    }
  ''');
}
