import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  var hetu = Hetu(locale: HTLocaleSimplifiedChinese());
  hetu.init();

  final r = hetu.eval(r'''
  external class SamsaraEngine {
    fun loadLocale(data: Map)
  }

  var buildContext

  fun build(ctx) {
    buildContext = ctx
  }

  var engine: SamsaraEngine
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
