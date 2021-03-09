import 'binding.dart';
import 'interpreter.dart';
import 'core.dart';
import 'lexicon.dart';

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
    String currentDirectory = 'script/',
    HT_Lexicon lexicon = const HT_LexiconDefault(),
    bool debugMode = false,
    ReadFileMethod readFileMethod = defaultReadFileMethod,
    Map<String, HT_External> externalFunctions = const {},
  }) async {
    itp = Interpreter(
      debugMode: debugMode,
      readFileMethod: readFileMethod,
    );

    HT_BaseBinding.itp = itp;

    // load external functions.
    itp.loadExternalFunctions(HT_BaseBinding.dartFunctions);
    itp.loadExternalFunctions(externalFunctions);

    // load classes and functions in core library.
    for (final file in coreLibs.keys) {
      itp.eval(coreLibs[file], fileName: file);
    }

    return itp;
  }
}
