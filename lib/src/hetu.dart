import 'binding.dart';
import 'interpreter.dart';
import 'core.dart';

/// Helper class for init the environment of Hetu.
///
/// Provide a global Interpreter ref [itp] for use in other classes (e.g. binding functions).
///
/// Only have static members.
abstract class Hetu {
  /// current global interpreter
  static Interpreter itp;

  /// Get a initted instance of interpreter
  static Future<Interpreter> init({
    String sdkDirectory = 'hetu_lib/',
    String workingDirectory = 'script/',
    bool debugMode = false,
    ReadFileMethod readFileMethod = defaultReadFileMethod,
    Map<String, HT_External> externalFunctions,
  }) async {
    itp = Interpreter(
      workingDirectory: workingDirectory,
      debugMode: debugMode,
      readFileMethod: readFileMethod,
    );

    HT_BaseBinding.itp = itp;

    try {
      // load external functions.
      itp.loadExternalFunctions(HT_BaseBinding.dartFunctions);
      if (externalFunctions != null) {
        itp.loadExternalFunctions(externalFunctions);
      }

      // load classes and functions in core library.
      for (final file in coreLibs.keys) {
        itp.eval(coreLibs[file], fileName: file);
      }
    } catch (e) {
      //stdout.write('\x1B[32m');
      print('Hetu init failed!');
      print(e);
      //stdout.write('\x1B[m');
    }

    return itp;
  }
}
