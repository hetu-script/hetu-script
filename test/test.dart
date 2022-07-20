import 'package:hetu_script/hetu_script.dart';

void main() {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      timer: true,
      compileWithoutLineInfo: false,
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
    import 'source1.ht'
    struct Person {
      construct {
        this.name = typename
        this.race = 'han'
      }
    }
// ''', fullName: 'source2.ht');
  final source3 = HTSource(r'''
    import 'source2.ht'
    struct Jimmy extends Person {
      construct : super() {
        this.age = 17
      }
    }
    fun test {
      final p = Jimmy()
      print(p)
    }
''', fullName: 'source3.ht');
  sourceContext.addResource(source1.fullName, source1);
  sourceContext.addResource(source2.fullName, source2);
  sourceContext.addResource(source3.fullName, source3);

  final result = hetu.eval(r'''
      fun test([a, b]) {
        print(a,b)
      }
      test(1, 2)
  ''');

  if (result is Future) {
    result.then((value) => print(hetu.lexicon.stringify(value)));
  } else {
    print(hetu.lexicon.stringify(result));
  }
}
