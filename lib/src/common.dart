import 'dart:io';

import 'extern_class.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'errors.dart';

typedef ReadFileMethod = dynamic Function(String filepath);
Future<String> defaultReadFileMethod(String filapath) async => await File(filapath).readAsString();
String readFileSync(String filapath) => File(filapath).readAsStringSync();

abstract class HT_Context {}

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

  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}});
}

mixin HT_ExternalBinding {
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

  HT_ExternNamespace fetchExternalClass(String id) => _externSpaces[id]!;

  void bindExternalFunction(String id, Function function) {
    if (_externFunctions.containsKey(id)) {
      throw HTErr_Defined(id);
    }
    _externFunctions[id] = function;
  }

  Function fetchExternalFunction(String id) => _externFunctions[id]!;

  void bindExternalVariable(String id, Function getter, Function setter) {
    if (_externFunctions.containsKey(HT_Lexicon.getter + id) || _externFunctions.containsKey(HT_Lexicon.setter + id)) {
      throw HTErr_Defined(id);
    }
    _externFunctions[HT_Lexicon.getter + id] = getter;
    _externFunctions[HT_Lexicon.setter + id] = setter;
  }

  dynamic getExternalVariable(String id) {
    if (!_externFunctions.containsKey(HT_Lexicon.getter + id)) {
      throw HTErr_Defined(HT_Lexicon.getter + id);
    }
    final getter = _externFunctions[HT_Lexicon.getter + id];
    return getter!();
  }

  void setExternalVariable(String id, value) {
    if (!_externFunctions.containsKey(HT_Lexicon.setter + id)) {
      throw HTErr_Defined(HT_Lexicon.setter + id);
    }
    final setter = _externFunctions[HT_Lexicon.setter + id];
    return setter!();
  }
}
