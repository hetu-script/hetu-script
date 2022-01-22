import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final r = hetu.eval(r'''
    fun func() {
      final a = false
      if (!a) {}
    }
  ''');

  print(r);
}
