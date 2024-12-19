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
    external fun getJSON
    let data = await getJSON()
    let data2 = Object.fromJSON(data)

    print(data2)

    print(data2.toJSON())

''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
    print(hetu.lexicon.stringify(r));
  } else {
    print(hetu.lexicon.stringify(r));
  }
}
