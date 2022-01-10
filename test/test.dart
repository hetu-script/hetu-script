import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
      var meaning
      eval("meaning = 'hello from a deeper dream!'")
      meaning
    ''');

  print(result);
}
