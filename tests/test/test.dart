import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      var bi = BigInt.parse("9223372036854775807")

      print(bi)
    ''', isScript: true);
}
