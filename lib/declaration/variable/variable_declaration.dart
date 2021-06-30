import '../../source/source.dart';
import '../../type/type.dart';
import '../declaration.dart';
import '../namespace.dart';

class HTVariableDeclaration extends HTDeclaration {
  final HTType? _declType;

  HTType? _resolvedDeclType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  HTType? get declType => _resolvedDeclType ?? _declType;

  HTVariableDeclaration(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      HTType? declType,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isTopLevel = false})
      : _declType = declType,
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable,
            isTopLevel: isTopLevel) {
    if (_declType != null && _declType!.isResolved) {
      _resolvedDeclType = _declType!;
    }
  }

  @override
  void resolve() {
    super.resolve();
    if ((closure != null) && (_declType != null)) {
      _resolvedDeclType = _declType!.resolve(closure!);
    } else {
      _resolvedDeclType = HTType.ANY;
    }
  }

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
