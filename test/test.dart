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
<<<<<<< HEAD
  hetu.init(locale: HTLocaleSimplifiedChinese());

  final r = hetu.eval(r'''
      1 + 2
  ''');
=======
  hetu.init(locale: HTLocaleSimplifiedChinese(), externalFunctions: {
    "my_eval": (HTEntity entity,
        {List<dynamic> positionalArgs = const [],
        Map<String, dynamic> namedArgs = const {},
        List<HTType> typeArgs = const []}) {
      final code = positionalArgs.first as String;
      return hetu.eval(code);
    },
  });

  // final r = hetu.eval(r'''
  //   external fun my_eval
  //   var a
  //   a = my_eval('3')
  //   a
  // ''');
  final r = hetu.evalFile('eval.hts');
>>>>>>> fix bug on eval method within script where stack frame is not properly restored. (#50)

  print(r);
}
