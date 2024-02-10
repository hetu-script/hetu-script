import 'package:hetu_script/hetu_script.dart';
import 'package:pub_semver/pub_semver.dart';

import 'binding/test_external_class.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      // printPerformanceStatistics: true,
      removeLineInfo: false,
      // doStaticAnalysis: true,
      // computeConstantExpression: true,
      showHetuStackTrace: true,
      showDartStackTrace: true,
      // stackTraceDisplayCountLimit: 20,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: true,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
      checkTypeAnnotationAtRuntime: true,
      normalizeImportPath: false,
    ),
    sourceContext: sourceContext,
    locale: HTLocaleSimplifiedChinese(),
  );
  hetu.init(
    externalClasses: [
      PersonClassBinding(),
    ],
  );

  final source1 = HTSource(r'''
    final typename = 'person'
''', filename: 'source1.ht');

  final source2 = HTSource(r'''
    import 'json_data.json' as jsonData
    struct Person {
      constructor {
        this.name = jsonData.name
        this.race = 'han'
      }
    }
// ''', filename: 'source2.ht');

  final source3 = HTSource(r'''
    namespace Person {
      class PersonImpl {
        var name
        constructor {
          name = 'Jimmy'
        }
      }
    }
''', filename: 'source3.ht');
  sourceContext.addResource(source1.fullName, source1);
  sourceContext.addResource(source2.fullName, source2);
  sourceContext.addResource(source3.fullName, source3);

  hetu.interpreter.bindExternalFunction('test', () {
    print('dart function called');
  });
  final jsonSource = HTSource(r'''{
    "name": "Aleph",
    "type": "novel",
    "volumes": 7,
  }''', filename: 'data.json', type: HTResourceType.json);
  sourceContext.addResource('data.json', jsonSource);

  // final result = hetu.eval(
  //   r'''
  //       import 'source1.ht'

  //       print(typename)
  //         ''',
  //   // invoke: 'fromJsonTest',
  //   // positionalArgs: [jsonData],
  // );

  final bytes = hetu.compile(
    r'''
      external class Person {
        var name
        constructor
      }
          ''',
    // isModuleEntryScript: true,
    version: Version(0, 1, 0),
  );

  hetu.loadBytecode(
    bytes: bytes,
    module: 'test',
    // invoke: 'main',
    // positionalArgs: [jsonData],
  );

  hetu.interpreter.bindExternalFunction(
    'fetch',
    () => Future.delayed(const Duration(seconds: 3)).then((value) {
      // print('delayed');
      return 3;
    }),
  );

  final r = hetu.eval('''
    namespace Test {
      external function fetch
    }

    function f async {
      await Test.fetch()
    }

    final r = await f()
    ''');

  if (r is Future) {
    print(await r);
  } else {
    print(r);
  }
}
