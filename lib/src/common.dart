import 'dart:io';

import 'binding.dart';
import 'parser.dart';
import 'lexicon.dart';

typedef ReadFileMethod = dynamic Function(String filepath);
Future<String> defaultReadFileMethod(String filapath) async => await File(filapath).readAsString();
String readFileSync(String filapath) => File(filapath).readAsStringSync();

class HT_Context {
  void clear() {
    _constInt.clear();
    _constFloat.clear();
    _constString.clear();
  }

  /// 常量表
  final _constInt = <int>[];
  int addConstInt(int value) {
    for (var i = 0; i < _constInt.length; ++i) {
      if (_constInt[i] == value) return i;
    }

    _constInt.add(value);
    return _constInt.length - 1;
  }

  int getConstInt(int index) => _constInt[index];

  final _constFloat = <double>[];
  int addConstFloat(double value) {
    for (var i = 0; i < _constFloat.length; ++i) {
      if (_constFloat[i] == value) return i;
    }

    _constFloat.add(value);
    return _constFloat.length - 1;
  }

  double getConstFloat(int index) => _constFloat[index];

  final _constString = <String>[];
  int addConstString(String value) {
    for (var i = 0; i < _constString.length; ++i) {
      if (_constString[i] == value) return i;
    }

    _constString.add(value);
    return _constString.length - 1;
  }

  String getConstString(int index) => _constString[index];
}

abstract class CodeRunner {
  String? get curFileName;
  String? get curDirectory;

  void loadExternalFunctions(Map<String, HT_ExternFunc> lib);

  dynamic eval(
    String content, {
    String? fileName,
    String libName = HT_Lexicon.globals,
    HT_Context? context,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  dynamic evalf(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  dynamic evalfSync(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}});
}
