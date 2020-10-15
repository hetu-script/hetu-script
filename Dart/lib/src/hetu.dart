import 'interpreter.dart';

abstract class Hetu {
  static Future<Interpreter> init({
    _LoadStringFunc loadStringFunc = defaultLoadString,
    String sdkLocation = 'hetu_core/',
    String workingDir = 'scripts/',
    HS_Lexicons lexicon = const HS_Lexicons(),
    bool debugMode = true,
    Map<String, HS_External> externalFunctions,
    bool extra = false,
    bool staticType = true,
    bool requireDeclaration = true,
  }) async {
    try {
      if (_debugMode) print('Hetu: Loading core library.');
      await eval(HS_Buildin.coreLib, 'core.ht');

      // 绑定外部函数
      linkAll(HS_Buildin.functions);
      linkAll(externalFunctions);

      // 载入基础库
      await evalf(_sdkDir + 'core.ht');
      await evalf(_sdkDir + 'value.ht');
      await evalf(_sdkDir + 'system.ht');
      await evalf(_sdkDir + 'console.ht');

      if (extra) {
        await evalf(_sdkDir + 'math.ht');
        await evalf(_sdkDir + 'help.ht');
      }

      _initted = true;
    } catch (e) {
      stdout.write('\x1B[32m');
      print(e);
      print('Hetu init failed!');
      stdout.write('\x1B[m');
    }
  }
}
