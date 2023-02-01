import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();

  final r = hetu.eval('42');

  print(r);
}
