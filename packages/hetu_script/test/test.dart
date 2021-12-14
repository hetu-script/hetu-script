import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      final list = [
       
        42, // the meaning
      ]
      list
    ''', isScript: true);

  print(result);
}
