import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  var hetu = Hetu(locale: HTLocaleSimplifiedChinese());
  hetu.init();

  final r = hetu.eval(r'''
    let #a = 'aaa'
    let #b = 'bbb'

    print(#a, #b)

    print('${#a} and ${#b}')
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
