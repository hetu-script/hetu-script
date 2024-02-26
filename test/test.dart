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

    // console.time('loop test')
    // for (var i = 0; i < 100000; ++i) {

    // }
    // console.timeEnd('loop test')

    let data = await getJSON()

    let obj = Object.createFromJSON(data)

    print(obj)
    print(obj.keys)
    print('obj.hasOwnProperty(\'toJSON\')', obj.hasOwnProperty('toJSON'))
    print('obj.contains(\'toJSON\')', obj.contains('toJSON'))
    print(obj.toJSON())

    fun test() async {
      print('async execution')
    }
    
    test()
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
