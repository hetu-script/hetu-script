import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    final list = [4,33,1]
    final [_,_,z] = list
    print(z)
  ''');
}
