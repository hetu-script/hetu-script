import 'package:hetu_script/hetu_script.dart';

const v1 = 'external static member of a script class';
const v2 = 'external instance member of a script class';
const v3 = 'external member of a script namespace';

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
    function test(n) {
      let result = 
      switch (n) {
        case 0,1: {
          'small number';
        }
        case 2 =>
          'medium number';
        default =>
          'unknown number: ${n}';
      }
      return result;
    }

    for (var i in range(4)) {
      print('${i}: ${test(i)}');
    }
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
