import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      final l1 = [1, 2, 3, 4, 5, 6]

      final l2  = l1.where((element) => element % 2 == 0)

      print(l2)
    ''', isScript: true);
}
