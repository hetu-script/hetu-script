import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final a = Set(3,2,1)
    final b = a.toList()
    b.sort()
    print(b)
  ''');
}
