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
    struct T {
      constructor() {
        this.a = 1
      }
      var b = 42
    }

    struct T2 extends T {}
    let obj = T2()
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
