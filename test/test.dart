import 'package:hetu_script/hetu_script.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: true,
      removeLineInfo: false,
      // doStaticAnalysis: true,
      // computeConstantExpression: true,
      showHetuStackTrace: true,
      showDartStackTrace: true,
      // stackTraceDisplayCountLimit: 20,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: false,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
      checkTypeAnnotationAtRuntime: true,
      normalizeImportPath: false,
    ),
    sourceContext: sourceContext,
  );
  hetu.init(locale: HTLocaleSimplifiedChinese());

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

  final jsonData = {
    "name": "Aleph",
    "type": "novel",
    "volumes": 7,
  };

  final bytes = hetu.compile(
    r'''
      import 'source3.ht' as PP
      
      final p: PP.Person.PersonImpl = PP.Person.PersonImpl()
      print(p.name)
          ''',
    isModuleEntryScript: true,
    version: Version(0, 1, 0),
  );

  final result = hetu.loadBytecode(
    bytes: bytes,
    moduleName: 'test',
    // invokeFunc: 'main',
    // positionalArgs: [jsonData],
  );

  if (result is Future) {
    result.then((value) => print(hetu.lexicon.stringify(value)));
  } else {
    print(hetu.lexicon.stringify(result));
  }
}
