import 'dart:io';

import 'extern_class.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'errors.dart';

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

  /// 注册外部命名空间，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalNamespace(String id, HT_ExternNamespace namespace);
  HT_ExternNamespace fetchExternalClass(String id);
  void bindExternalFunction(String id, Function function);
  Function fetchExternalFunction(String id);

  void bindExternalVariable(String id, Function getter, Function setter);
  dynamic getExternalVariable(String id);
  void setExternalVariable(String id, value);

  dynamic eval(
    String content, {
    String? fileName,
    String libName = HT_Lexicon.global,
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

mixin Binding {
  final _externSpaces = <String, HT_ExternNamespace>{};
  final _externFunctions = <String, Function>{};

  /// 注册外部命名空间，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalNamespace(String id, HT_ExternNamespace namespace) {
    if (_externSpaces.containsKey(id)) {
      throw HTErr_Defined(id);
    }
    _externSpaces[id] = namespace;
  }

  HT_ExternNamespace fetchExternalClass(String id) {
    if (!_externSpaces.containsKey(id)) {
      throw HTErr_Undefined(id);
    }
    return _externSpaces[id]!;
  }

  void bindExternalFunction(String id, Function function) {
    if (_externFunctions.containsKey(id)) {
      throw HTErr_Defined(id);
    }
    _externFunctions[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFunctions.containsKey(id)) {
      throw HTErr_Undefined(id);
    }
    return _externFunctions[id]!;
  }

  void bindExternalVariable(String id, Function getter, Function setter) {
    if (_externFunctions.containsKey(HT_Lexicon.getter + id) || _externFunctions.containsKey(HT_Lexicon.setter + id)) {
      throw HTErr_Defined(id);
    }
    _externFunctions[HT_Lexicon.getter + id] = getter;
    _externFunctions[HT_Lexicon.setter + id] = setter;
  }

  dynamic getExternalVariable(String id) {
    if (!_externFunctions.containsKey(HT_Lexicon.getter + id)) {
      throw HTErr_Undefined(HT_Lexicon.getter + id);
    }
    final getter = _externFunctions[HT_Lexicon.getter + id]!;
    return getter();
  }

  void setExternalVariable(String id, value) {
    if (!_externFunctions.containsKey(HT_Lexicon.setter + id)) {
      throw HTErr_Undefined(HT_Lexicon.setter + id);
    }
    final setter = _externFunctions[HT_Lexicon.setter + id]!;
    return setter();
  }
}
