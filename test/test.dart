import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  var hetu = Hetu(locale: HTLocaleSimplifiedChinese());
  hetu.init();

  final r = hetu.eval(r'''
  let arr = [1,2,3]

  const [a,b,c] = arr
  print(a,b,c)
''');

  if (r != null) {
    if (r is Future) {
      print('async function');
      print(await r);
    } else {
      print(r);
    }
  }
}
