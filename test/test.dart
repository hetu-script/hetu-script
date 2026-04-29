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
      showHetuStackTrace: true,
    ),
  );
  hetu.init();

  var r = hetu.eval(r'''
     let t1 = typeof () {}
     type t2 = () -> any
     
     switch (t1) {
       typeval {} => 'structural type'
       typeval ()->any => 'function type'
       default => 'other type'
     }
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
