import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  final hetu = Hetu(
    sourceContext: sourceContext,
    locale: HTLocaleSimplifiedChinese(),
    config: HetuConfig(
      normalizeImportPath: false,
      allowImplicitNullToZeroConversion: true,
      printPerformanceStatistics: true,
    ),
  );
  hetu.init();

  sourceContext.addResource('file1.ht', HTSource('''
    fun test () {
      print('Hello, World!');
    }
  '''));

  sourceContext.addResource('file2.json', HTSource('''
{
  value: 1.0,
  type: 'percentage',
}
  ''', type: HTResourceType.json));

  var r = hetu.eval(r'''
    let a = 1

    if (a < 3) {
      print('a < 3')
    } else if (a < 5) {
      print('a < 5')
    }
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
