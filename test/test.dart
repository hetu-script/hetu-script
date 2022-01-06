import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
        final list = [1, 2, 3]
        for (final pos in list) {
          print('hello', pos)
        }
    ''');
}
