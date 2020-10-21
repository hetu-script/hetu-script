import 'dart:io';

import 'lexicons.dart';
import 'buildin.dart';
import 'interpreter.dart';
import 'class.dart' show HT_Instance;

typedef ReadFileMethod = Future<String> Function(String filepath);
typedef HT_External = dynamic Function(HT_Instance instance, List<dynamic> args);

Future<String> defaultReadFileMethod(String filapath) async => await File(filapath).readAsString();

class HetuEnv {
  final ReadFileMethod stringLoadMethod;
  final String sdkDirectory;
  final String workingDirectory;
  final bool debugMode;
  final bool staticType;
  final bool requireDeclaration;
  final HT_Lexicons lexicon;

  const HetuEnv._({
    this.stringLoadMethod = defaultReadFileMethod,
    this.sdkDirectory = 'hetu_core/',
    this.workingDirectory = 'scripts/',
    this.debugMode = true,
    this.staticType = true,
    this.requireDeclaration = true,
    this.lexicon = const HT_Lexicons(),
  });

  static Future<Interpreter> init({
    ReadFileMethod stringLoadMethod = defaultReadFileMethod,
    String sdkDirectory = 'hetu_lib/',
    String workingDirectory = 'scripts/',
    bool debugMode = true,
    bool staticType = true,
    bool requireDeclaration = true,
    HT_Lexicons lexicon = const HT_Lexicons(),
    Map<String, HT_External> externalFunctions,
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
      await itp.eval(HT_Buildin.coreLib, 'core.ht');

      // 绑定外部函数
      itp.loadExterns(HT_Buildin.functions);
      if (externalFunctions != null) itp.loadExterns(externalFunctions);

      // 载入基础库
      await itp.evalf(sdkDirectory + 'core.ht');
      await itp.evalf(sdkDirectory + 'value.ht');
      await itp.evalf(sdkDirectory + 'system.ht');
      await itp.evalf(sdkDirectory + 'console.ht');

      if (additionalModules) {
        await itp.evalf(sdkDirectory + 'math.ht');
        await itp.evalf(sdkDirectory + 'help.ht');
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
