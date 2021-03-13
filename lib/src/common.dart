import 'dart:io';

import 'binding.dart';
import 'parser.dart';
import 'lexicon.dart';

typedef ReadFileMethod = dynamic Function(String filepath);
Future<String> defaultReadFileMethod(String filapath) async => await File(filapath).readAsString();
String readFileSync(String filapath) => File(filapath).readAsStringSync();

abstract class HT_Context {}

abstract class CodeRunner {
  String get curFileName;
  String get curDirectory;

  void loadExternalFunctions(Map<String, HT_ExternFunc> lib);

  dynamic eval(
    String content, {
    String fileName,
    String libName = HT_Lexicon.globals,
    HT_Context context,
    ParseStyle style = ParseStyle.library,
    String invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}});
}
