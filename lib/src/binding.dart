import 'package:hetu_script/hetu_script.dart';

import 'extern_class.dart';

mixin Binding {
  final _externSpaces = <String, HT_ExternClass>{};
  final _externFunctions = <String, Function>{};

  /// 注册外部命名空间，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalNamespace(String id, HT_ExternClass namespace) {
    if (_externSpaces.containsKey(id)) {
      throw HT_Error_Defined_Runtime(id);
    }
    _externSpaces[id] = namespace;
  }

  HT_ExternClass fetchExternalClass(String id) {
    if (!_externSpaces.containsKey(id)) {
      throw HT_Error_Undefined(id);
    }
    return _externSpaces[id]!;
  }

  void bindExternalFunction(String id, Function function) {
    if (_externFunctions.containsKey(id)) {
      throw HT_Error_Defined_Runtime(id);
    }
    _externFunctions[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFunctions.containsKey(id)) {
      throw HT_Error_Undefined(id);
    }
    return _externFunctions[id]!;
  }

  void bindExternalVariable(String id, Function getter, Function setter) {
    if (_externFunctions.containsKey(HT_Lexicon.getter + id) || _externFunctions.containsKey(HT_Lexicon.setter + id)) {
      throw HT_Error_Defined_Runtime(id);
    }
    _externFunctions[HT_Lexicon.getter + id] = getter;
    _externFunctions[HT_Lexicon.setter + id] = setter;
  }

  dynamic getExternalVariable(String id) {
    if (!_externFunctions.containsKey(HT_Lexicon.getter + id)) {
      throw HT_Error_Undefined(HT_Lexicon.getter + id);
    }
    final getter = _externFunctions[HT_Lexicon.getter + id]!;
    return getter();
  }

  void setExternalVariable(String id, value) {
    if (!_externFunctions.containsKey(HT_Lexicon.setter + id)) {
      throw HT_Error_Undefined(HT_Lexicon.setter + id);
    }
    final setter = _externFunctions[HT_Lexicon.setter + id]!;
    return setter();
  }
}
