import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  var hetu = Hetu(locale: HTLocaleSimplifiedChinese());
  hetu.init();

  final r = hetu.eval(r'''
    let a = 42
    let b = 2047

    const c // = 'sum: ${a + b}'
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
