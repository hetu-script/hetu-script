import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final obj = {
      a: 6,
      b: 7,
    }
    final { a, b } = obj
    print(a, b)
    final list = [1,2,3]
    final [x,y,z] = list
    print(x,y,z)
  ''');
}
