import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
        final n = 6
        const a = 'age: ${n * 7}'
        print(a)
  ''');
}
