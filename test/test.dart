import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final list = [1, 2, 1, 3, 2, 5, 1]

    final s = Set(...list)

    print(s)
  ''');
}
