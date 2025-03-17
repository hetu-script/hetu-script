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

  var r = hetu.eval(r'''
    async function futureTest (n) {
      await Future.delayed(1);
      return 'hello, ${n}'
    }

    var i = 0
    while (i < 5) {
      final v = await futureTest(i)
      print(v);
      i++
    }

''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
