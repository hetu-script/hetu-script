import 'namespace/namespace.dart';
import 'declaration.dart';
import 'abstract_interpreter.dart';

/// 一个变量声明，包含了类型等额外信息。
/// 在编译后的代码中，被提前到整个代码块最前面。
class HTVariable with HTDeclaration, InterpreterRef {
  // 为了允许保存宿主程序变量，这里是dynamic，而不是HTObject
  dynamic _value;

  final Function? getter;
  final Function? setter;

  final bool isExternal;
  final bool isStatic;

  final HTNamespace? closure;

  var _isInitialized = false;
  @override
  bool get isInitialized => _isInitialized;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  HTVariable(String id, HTInterpreter interpreter,
      {String? classId,
      dynamic value,
      this.getter,
      this.setter,
      this.isExternal = false,
      this.isStatic = false,
      this.closure}) {
    this.id = id;
    this.classId = classId;
    this.interpreter = interpreter;
    if (value != null) {
      this.value = value;
      _isInitialized = true;
    }
  }

  @override
  set value(dynamic value) {
    super.value = value;

    _value = value;
    _isInitialized = true;
  }

  @override
  dynamic get value {
    if (!isExternal) {
      if (!isInitialized) {
        initialize();
      }
      return _value;
    } else {
      final externClass = interpreter.fetchExternalClass(classId!);
      return externClass.memberGet(id);
    }
  }

  @override
  HTVariable clone() => HTVariable(id, interpreter,
      classId: classId,
      value: value,
      getter: getter,
      setter: setter,
      isExternal: isExternal);
}
