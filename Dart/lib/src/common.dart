import 'dart:io';

import 'lexicons.dart';
import 'buildin.dart';
import 'interpreter.dart';
import 'class.dart' show HS_Instance;

typedef ReadFileMethod = Future<String> Function(String filepath);
typedef HS_External = dynamic Function(HS_Instance instance, List<dynamic> args);

Future<String> defaultReadFileMethod(String filapath) async => await File(filapath).readAsString();

class HetuEnv {
  final ReadFileMethod stringLoadMethod;
  final String sdkDirectory;
  final String workingDirectory;
  final bool debugMode;
  final bool staticType;
  final bool requireDeclaration;
  final HS_Lexicons lexicon;

  const HetuEnv._({
    this.stringLoadMethod = defaultReadFileMethod,
    this.sdkDirectory = 'hetu_core/',
    this.workingDirectory = 'scripts/',
    this.debugMode = true,
    this.staticType = true,
    this.requireDeclaration = true,
    this.lexicon = const HS_Lexicons(),
  });

  static Future<Interpreter> init({
    ReadFileMethod stringLoadMethod = defaultReadFileMethod,
    String sdkDirectory = 'hetu_lib/',
    String workingDirectory = 'scripts/',
    bool debugMode = true,
    bool staticType = true,
    bool requireDeclaration = true,
    lexicon = const HS_Lexicons(),
    Map<String, HS_External> externalFunctions,
    bool additionalModules = false,
  }) async {
    env = HetuEnv._(
      stringLoadMethod: defaultReadFileMethod,
      sdkDirectory: sdkDirectory,
      workingDirectory: workingDirectory,
      debugMode: debugMode,
      staticType: staticType,
      requireDeclaration: requireDeclaration,
      lexicon: lexicon,
    );

    itp = Interpreter();

    try {
      if (debugMode) print('Hetu: Loading core library.');
      await itp.eval(HS_Buildin.coreLib, 'core.ht');

      // 绑定外部函数
      itp.loadExterns(HS_Buildin.functions);
      if (externalFunctions != null) itp.loadExterns(externalFunctions);

      // 载入基础库
      await itp.evalf(sdkDirectory + 'core/core.ht');
      await itp.evalf(sdkDirectory + 'core/value.ht');
      await itp.evalf(sdkDirectory + 'core/system.ht');
      await itp.evalf(sdkDirectory + 'core/console.ht');

      if (additionalModules) {
        await itp.evalf(sdkDirectory + 'core/math.ht');
        await itp.evalf(sdkDirectory + 'core/help.ht');
      }
    } catch (e) {
      stdout.write('\x1B[32m');
      print(e);
      print('Hetu init failed!');
      stdout.write('\x1B[m');
    }

    return itp;
  }
}

HetuEnv env;
Interpreter itp;
