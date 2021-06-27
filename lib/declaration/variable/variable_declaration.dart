import '../../source/source.dart';
import '../../type/type.dart';
import '../declaration.dart';
import '../namespace.dart';

class HTVariableDeclaration extends HTDeclaration {
  HTType? _declType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  HTType? get declType => _declType;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  HTVariableDeclaration(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      HTType? declType,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false})
      : super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable) {
    _declType = declType;
  }

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
  HTVariableDeclaration clone() => HTVariableDeclaration(
      id: id,
      classId: classId,
      closure: closure,
      declType: declType,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isMutable: isMutable);
}
