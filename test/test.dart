import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  final hetu = Hetu(
    sourceContext: sourceContext,
    locale: HTLocaleSimplifiedChinese(),
    config: HetuConfig(
      normalizeImportPath: false,
      allowImplicitNullToZeroConversion: true,
    ),
  );
  hetu.init(externalFunctions: {
    'getJSON': ({positionalArgs, namedArgs}) async {
      final jsonData = {
        "name": "Aleph",
        "type": "novel",
        "volumes": 7,
      };
      return jsonData;
    }
  });

  sourceContext.addResource('source1.ht', HTSource('''
  
  '''));

  var r = hetu.eval(r'''
    for (var i in range(10)) {
      let n = Random().distantInt(100, exponent: 0.5)
      print(n)
    }
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
    print(hetu.lexicon.stringify(r));
  } else {
    print(hetu.lexicon.stringify(r));
  }
}
