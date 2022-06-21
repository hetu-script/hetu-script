import 'package:hetu_script/hetu_script.dart';

void main() {
  final sourceContext = HTOverlayContext();
  var hetu = Hetu(
    config: HetuConfig(
      compileWithoutLineInfo: false,
      // doStaticAnalysis: true,
      // computeConstantExpression: true,
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

  final r = hetu.eval(r'''
      final a = {
      }

      for (final obj of a) {
        obj.type = 'array_member'
      }

      print(a)
  ''');
  print(hetu.lexicon.stringify(r));
}
