import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
    final i = 42
    when (i) {
      42 -> 'the meaning!'
    }
    ''', isScript: true);

  print(result);
}
