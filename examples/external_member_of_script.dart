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

  hetu.interpreter.bindExternalFunction('Test.v1', (
      {positionalArgs, namedArgs}) {
    return v1;
  });

  hetu.interpreter.bindExternalMethod('Test::v2', (
      {object, positionalArgs, namedArgs}) {
    return v2;
  });

  hetu.interpreter.bindExternalFunction('Test2::v3', (
      {positionalArgs, namedArgs}) {
    return v3;
  });

  var r = hetu.eval(r'''
    class Test {
      external static get v1
      external get v2
    }

    namespace Test2 {
      external function v3
    }

    print(Test.v1)

    final t = Test()
    print(t.v2)

    print(Test2.v3())
''');

  if (r is Future) {
    print('wait for async function...');
    r = await r;
  }

  print(hetu.stringify(r));
}
