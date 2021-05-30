import '../error/errors.dart';
import '../grammar/semantic.dart';
import '../type_system/type.dart';
import 'namespace/namespace.dart';
import 'abstract_interpreter.dart';
import 'function/abstract_function.dart';

/// A [HTDeclaration] is basically a binding between a symbol and a value
class HTDeclaration with InterpreterRef {
  final String id;

  final String? classId;

  bool get isMember => classId != null;

  // 为了允许保存宿主程序变量，这里是dynamic，而不是HTObject
  dynamic _value;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the [valueType] on [HTObject] to
  /// determine wether an value binding (assignment) is legal.
  HTType? get declType => null;

  final bool isExternal;

  final bool isStatic;

  /// Whether this variable is immutable.
  final bool isImmutable;

  final HTNamespace? closure;

  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  HTDeclaration(this.id, HTInterpreter interpreter,
      {this.classId,
      dynamic value,
      this.isExternal = false,
      this.isStatic = false,
      this.isImmutable = true,
      this.closure}) {
    this.interpreter = interpreter;
    if (value != null) {
      this.value = value;
      _isInitialized = true;
    }
  }

  /// 调用这个接口来初始化这个变量，继承类需要
  /// override 这个接口来实现自己的初始化过程
  void initialize() {}

  /// 调用这个接口来赋值这个变量，继承类可以
  /// override 这个接口来实现自己的赋值过程
  /// must call super
  set value(dynamic value) {
    if (isImmutable && isInitialized) {
      throw HTError.immutable(id);
    }

    _value = value;
    _isInitialized = true;
  }

  dynamic get value {
    if (!isExternal) {
      if (!isInitialized) {
        initialize();
      }
      if (_value is AbstractFunction) {
        if (_value.externalId != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(_value);
          return externalFunc;
        }
      }
      return _value;
    } else {
      final externClass = interpreter.fetchExternalClass(classId!);
      return externClass.memberGet(id);
    }
  }

  /// Create a copy of this variable declaration,
  /// mainly used on class member inheritance and function arguments passing.
  HTDeclaration clone() => HTDeclaration(id, interpreter,
      classId: classId,
      value: value,
      isExternal: isExternal,
      isStatic: isStatic,
      isImmutable: isImmutable,
      closure: closure);
}
