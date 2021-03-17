import 'errors.dart';
import 'extern_class.dart';
import 'lexicon.dart';

///用于生成自动绑定代码的Annotation标记
class HTBinding {
  const HTBinding();
}

mixin Binding {
  final _externClasses = <String, HTExternClass>{};
  final _externFunctions = <String, Function>{};

  bool containsExternalClass(String id) => _externClasses.containsKey(id);

  /// 注册外部类，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalClass(String id, HTExternClass namespace) {
    if (_externClasses.containsKey(id)) {
      throw HTErrorDefined_Runtime(id);
    }
    _externClasses[id] = namespace;
  }

  HTExternClass fetchExternalClass(String id) {
    if (!_externClasses.containsKey(id)) {
      throw HTErrorUndefined(id);
    }
    return _externClasses[id]!;
  }

  void bindExternalFunction(String id, Function function) {
    if (_externFunctions.containsKey(id)) {
      throw HTErrorDefined_Runtime(id);
    }
    _externFunctions[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFunctions.containsKey(id)) {
      throw HTErrorUndefined(id);
    }
    return _externFunctions[id]!;
  }

  void bindExternalVariable(String id, Function getter, Function setter) {
    if (_externFunctions.containsKey(HTLexicon.getter + id) || _externFunctions.containsKey(HTLexicon.setter + id)) {
      throw HTErrorDefined_Runtime(id);
    }
    _externFunctions[HTLexicon.getter + id] = getter;
    _externFunctions[HTLexicon.setter + id] = setter;
  }

  dynamic getExternalVariable(String id) {
    if (!_externFunctions.containsKey(HTLexicon.getter + id)) {
      throw HTErrorUndefined(HTLexicon.getter + id);
    }
    final getter = _externFunctions[HTLexicon.getter + id]!;
    return getter();
  }

  void setExternalVariable(String id, value) {
    if (!_externFunctions.containsKey(HTLexicon.setter + id)) {
      throw HTErrorUndefined(HTLexicon.setter + id);
    }
    final setter = _externFunctions[HTLexicon.setter + id]!;
    return setter();
  }
}
