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

    let a = {
      name: 'jimmy'
    }

    let b = {
      func : () async {
        print(this.name)
      }
    }

    b.func.apply(a)
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
    print(hetu.lexicon.stringify(r));
  } else {
    print(hetu.lexicon.stringify(r));
  }
}
