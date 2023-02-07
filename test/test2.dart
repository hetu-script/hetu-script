import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();

  final r = hetu.eval(r'''
  var a: int = 42;
  decltypeof a
  ''');

  print(hetu.lexicon.stringify(r));
}
