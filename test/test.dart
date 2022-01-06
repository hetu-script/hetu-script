import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
       if (2 > 1) {

       }
    ''');

  print(result);
}
