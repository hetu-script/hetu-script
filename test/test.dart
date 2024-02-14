import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  final hetu = Hetu(
    sourceContext: sourceContext,
    locale: HTLocaleSimplifiedChinese(),
    config: HetuConfig(normalizeImportPath: false),
  );
  hetu.init();

  sourceContext.addResource(
    'test.ht',
    HTSource(r'''const kWords = 'the thing behind everything'
'''),
  );

  final r = hetu.eval(r'''
  import 'test.ht'

  const _kNewWords = kWords + '!!!'

  print(_kNewWords)

  const obj = {a:'aaa'}

  print(obj.keys)

  // for (const k in obj.keys) {
  //   print(k)
  // }
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
