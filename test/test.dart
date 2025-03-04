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
    struct Test{
      constructor() {
        this.arr = [6,7]
        this.arr.add(42)
        print(this.arr)
      }
    }

    final arr2 = [110]
    arr2.addAll([Test(), Test()])
    print(arr2)
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
    print(hetu.lexicon.stringify(r));
  } else {
    print(hetu.lexicon.stringify(r));
  }
}
