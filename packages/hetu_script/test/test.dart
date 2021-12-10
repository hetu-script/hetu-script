import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
  final beifenglinMazes = {
    // terrains数组中的数值代表sprite sheet上的位置，从左到右，从上到下。从 1 开始，0 代表空。
    terrains: [5, 1, 0, 1, 2, 1, 3, 0, 0, 3, 0, 3, 1, 2, 1, 8, 0, 3, 0, 0, 3, 0, 0, 3, 0, 0, 1, 0, 0, 1],
  }
  ''', isScript: true);
}
