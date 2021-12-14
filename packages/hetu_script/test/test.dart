import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      final list = [
       // the meaning
        {
          meaning: 42,
        }
      ]
      list
    ''', isScript: true);

  print(result);
}
