import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final r = hetu.eval(r'''
      var aa = {
        a: 1,
        b: 2,
      }

      var bb = {
        name: 'jimmy'
      }

      bb.assign(aa)

      print(bb)
  ''');

  print(r);
}
