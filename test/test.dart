import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
        const a = 'age: ${6 * 7}'
        print(a)
  ''');
}
