import 'package:hetu_script/hetu_script.dart';

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
      stackTraceDisplayCountLimit: 20,
      // explicitEndOfStatement: true,
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
  );

  final r = hetu.eval(r'''
    final lowerLevel = true
    when ('a') {
      'a' -> {
        when(lowerLevel) {
          true -> {
            print(lowerLevel)
          }
          false -> {
            print(lowerLevel)
          }
        }
      }
      'b' -> {
        print('b')
      }
    }

''');

  // if (r is Future) {
  //   print(await r);
  // } else {
  //   print(r);
  // }
}
