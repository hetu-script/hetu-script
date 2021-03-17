import 'package:hetu_script/hetu_script.dart';

import 'binding.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'context.dart';

mixin InterpreterRef {
  late final Interpreter interpreter;
}

abstract class Interpreter with Binding {
  String get workingDirectory;

  Future<dynamic> eval(
    String content, {
    String libName = HTLexicon.global,
    HTContext? context,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  Future<dynamic> import(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  // dynamic evalfSync(
  //   String fileName, {
  //   String? directory,
  //   String? libName,
  //   ParseStyle style = ParseStyle.library,
  //   String? invokeFunc,
  //   List<dynamic> positionalArgs = const [],
  //   Map<String, dynamic> namedArgs = const {},
  // });

  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}});

  HTTypeId typeof(dynamic object);
}
