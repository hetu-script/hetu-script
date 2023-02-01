import 'package:hetu_script/hetu_script.dart';
import 'package:pub_semver/pub_semver.dart';

import 'binding/test_external_class.dart';

Future<void> main() async {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
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
  );
  hetu.init(
    locale: HTLocaleSimplifiedChinese(),
    externalClasses: [
      PersonClassBinding(),
    ],
  );

  final source1 = HTSource(r'''
    final typename = 'person'
''', fullName: 'source1.ht');

  final source2 = HTSource(r'''
    import 'json_data.json' as jsonData
    struct Person {
      construct {
        this.name = jsonData.name
        this.race = 'han'
      }
    }
// ''', fullName: 'source2.ht');

  final source3 = HTSource(r'''
    namespace Person {
      class PersonImpl {
        var name
        construct {
          name = 'Jimmy'
        }
      }
    }
''', fullName: 'source3.ht');
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
  }''', fullName: 'data.json', type: HTResourceType.hetuValue);
  sourceContext.addResource('data.json', jsonSource);

  // final result = hetu.eval(
  //   r'''
  //       import 'source1.ht'

  //       print(typename)
  //         ''',
  //   // invokeFunc: 'fromJsonTest',
  //   // positionalArgs: [jsonData],
  // );

  final bytes = hetu.compile(
    r'''
      external class Person {
        var name
        construct
      }
          ''',
    // isModuleEntryScript: true,
    version: Version(0, 1, 0),
  );

  hetu.loadBytecode(
    bytes: bytes,
    moduleName: 'test',
    // invokeFunc: 'main',
    // positionalArgs: [jsonData],
  );

  hetu.interpreter.bindExternalFunction(
    'fetch',
    () => Future.delayed(const Duration(seconds: 3)).then((value) {
      // print('delayed');
      return 3;
    }),
  );

  hetu.eval('''
    fun value1 async {
      return Future.value(6)
    }

    fun value2 async {
      return Future.value(7)
    }

    final v = await value1() + await value2()
    
    print(v)
    ''');

  // final r2 = await hetu.invoke('valueFuture');
  // print(r2);
}
