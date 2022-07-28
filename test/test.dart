import 'package:hetu_script/hetu_script.dart';

void main() {
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
      allowImplicitVariableDeclaration: false,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
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
    // import 'source2.ht'
    import 'json_data.json' as jsonData
    // struct Jimmy extends Person {
    //   construct : super() {
    //     this.age = 17
    //   }
    // }
    // export { Person }
    fun test {
      print(jsonData.type)
    }
''', fullName: 'source3.ht');
  sourceContext.addResource(source1.fullName, source1);
  sourceContext.addResource(source2.fullName, source2);
  sourceContext.addResource(source3.fullName, source3);

  hetu.interpreter.bindExternalFunction('test', () {
    print('dart function called');
  });
  final jsonData = HTSource(r'''{
    "name": "Aleph",
    "type": "novel",
    "volumes": 7,
  }''', fullName: 'data.json', type: HTResourceType.hetuValue);
  sourceContext.addResource('data.json', jsonData);

  final result = hetu.eval(
    r'''
        import 'data.json' as jsonData
        
        struct T {
          construct {
            this.name = 'test'
          }
        }
        T()
          ''',
    // invokeFunc: 'fromJsonTest',
    // positionalArgs: [jsonData],
  );

  if (result is Future) {
    result.then((value) => print(hetu.lexicon.stringify(value)));
  } else {
    print(hetu.lexicon.stringify(result));
  }
}
