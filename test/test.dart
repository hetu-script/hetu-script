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

  sourceContext.addResource(
    'source1.ht',
    HTSource(r'''
  var i = 42
'''),
  );

  sourceContext.addResource(
    'source2.ht',
    HTSource(r'''
    export 'source1.ht'
'''),
  );

  sourceContext.addResource(
    'source3.ht',
    HTSource(r'''
    export {i} from 'source2.ht'
'''),
  );

  var r = hetu.eval(r'''
    import 'source3.ht'

    var a
    a[1]
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
    print(hetu.lexicon.stringify(r));
  } else {
    print(hetu.lexicon.stringify(r));
  }
}
