import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script');
  var hetu = Hetu(
    config: HetuConfig(
      checkTypeErrors: true,
      computeConstantExpressionValue: true,
      showDartStackTrace: true,
      // stackTraceDisplayCountLimit: 20,
      allowVariableShadowing: true,
      allowImplicitVariableDeclaration: false,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
    ),
    sourceContext: sourceContext,
  );
  hetu.init(locale: HTLocaleSimplifiedChinese());

  final r = hetu.eval(r'''
    typeof fun(a: str) => 3;
  ''');

  // final r = hetu.evalFile('eval.hts');
  print(hetu.lexicon.stringify(r));
}
