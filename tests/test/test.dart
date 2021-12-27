import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      print([{d:'df', p: { p: 3}}, 3, 'df'])
    ''');
}
