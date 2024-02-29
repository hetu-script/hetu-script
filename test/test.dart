import 'package:hetu_script/hetu_script.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  final hetu = Hetu(
    sourceContext: sourceContext,
    locale: HTLocaleSimplifiedChinese(),
    config: HetuConfig(normalizeImportPath: false),
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
    'test.ht',
    HTSource(r'''var i = 42
'''),
  );

  var r = hetu.eval(r'''
    external async fun getJSON()

    let a = {a: 1, b: 2}
    let b = {c: 3, d: 4}
    let c = {a: 42, e: 5}

    Object.assign(a, b)
    print(a)

    Object.merge(a, c)
    print(a)
''');

  if (r is Future) {
    do {
      print('wait for async function...');
      r = await r;
    } while (r is Future);
    print(hetu.lexicon.stringify(r));
  } else {
    print(hetu.lexicon.stringify(r));
  }
}
