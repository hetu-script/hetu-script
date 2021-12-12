import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
    3 - (2 * 3 - 5)
  ''', isScript: true);

  print(result);
}
