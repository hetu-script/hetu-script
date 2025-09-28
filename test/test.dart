import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

class ConstantsClassBinding extends HTExternalClass {
  ConstantsClassBinding() : super('Constants');

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Constants.aaa':
        return 42;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

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

  hetu.interpreter.bindExternalClass(ConstantsClassBinding());

  var r = hetu.eval(r'''
    function test({a: integer, b: integer}) -> integer {}

    print(typeof test)
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
