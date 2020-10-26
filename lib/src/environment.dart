import 'dart:io';

import 'lexicon.dart';
import 'binding.dart';
import 'interpreter.dart';
import 'class.dart' show HT_Instance;

//typedef ReadFileMethod = Future<String> Function(String filepath);
typedef HT_External = dynamic Function(HT_Instance instance, List<dynamic> args);

//Future<String> defaultReadFileMethod(String filapath) async => await File(filapath).readAsString();

class HetuEnv {
  //final ReadFileMethod stringLoadMethod;
  final String sdkDirectory;
  final String workingDirectory;
  final bool debugMode;
  final bool staticType;
  final bool requireDeclaration;
  final HT_Lexicon lexicon;

  const HetuEnv._({
    //this.stringLoadMethod = defaultReadFileMethod,
    this.sdkDirectory = 'hetu_lib/',
    this.workingDirectory = 'scripts/',
    this.debugMode = true,
    this.staticType = true,
    this.requireDeclaration = true,
    this.lexicon = defaultLexicon,
  });

  static Future<Interpreter> init({
    //ReadFileMethod stringLoadMethod = defaultReadFileMethod,
    String sdkDirectory = 'hetu_lib/',
    String workingDirectory = 'scripts/',
    bool debugMode = true,
    bool staticType = true,
    bool requireDeclaration = true,
    HT_Lexicon lexicon = const HT_Lexicon(),
    Map<String, HT_External> externalFunctions,
    bool additionalModules = false,
  }) async {
    env = HetuEnv._(
      //stringLoadMethod: stringLoadMethod,
      sdkDirectory: sdkDirectory,
      workingDirectory: workingDirectory,
      debugMode: debugMode,
      staticType: staticType,
      requireDeclaration: requireDeclaration,
      lexicon: lexicon,
    );

    final itp = Interpreter();

    try {
      if (debugMode) print('Hetu: Loading core library.');
      //itp.eval(HT_Buildin.coreLib);

      // 绑定外部函数
      itp.loadExterns(HT_BaseBinding.dartFunctions);
      if (externalFunctions != null) itp.loadExterns(externalFunctions);

      // 载入基础库
      itp.evalf(sdkDirectory + 'core.ht');
      itp.evalf(sdkDirectory + 'value.ht');
      itp.evalf(sdkDirectory + 'system.ht');
      itp.evalf(sdkDirectory + 'console.ht');

      if (additionalModules) {
        itp.evalf(sdkDirectory + 'math.ht');
        itp.evalf(sdkDirectory + 'help.ht');
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
