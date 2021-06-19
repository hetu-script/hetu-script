// import '../../error/errors.dart';
import '../../type/type.dart';
import '../element.dart';
import '../namespace.dart';
// import '../../core/abstract_interpreter.dart';
// import '../../core/function/abstract_function.dart';

class HTTypedVariableDeclaration extends HTElement {
  HTType? _declType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  HTType? get declType => _declType;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  HTTypedVariableDeclaration(
      String id, String moduleFullName, String libraryName,
      {HTNamespace? closure,
      String? classId,
      HTType? declType,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false})
      : super(id, moduleFullName, libraryName,
            closure: closure,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable) {
    _declType = declType;
  }

  /// initialize the declared type
  @override
  void resolve() {
    super.resolve();

    if ((closure != null) && (_declType != null) && (!_declType!.isResolved)) {
      _declType = _declType!.resolve(closure!);
    }
  }

  /// Create a copy of this variable declaration,
  /// mainly used on class member inheritance and function arguments passing.
  @override
  HTTypedVariableDeclaration clone() =>
      HTTypedVariableDeclaration(id, moduleFullName, libraryName,
          closure: closure,
          classId: classId,
          declType: declType,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          isMutable: isMutable);
}
