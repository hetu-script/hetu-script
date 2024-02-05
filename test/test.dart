import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  var hetu = Hetu();
  hetu.init();

  hetu.eval(r'''
    var a = 0
    do {
      print(a)
      ++a
    } while (
      a < 2 
      // && '' is str
    )
''');
}
