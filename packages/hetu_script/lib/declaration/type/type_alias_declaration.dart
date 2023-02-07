import '../../type/type.dart';
import '../generic/generic_type_parameter.dart';
import '../declaration.dart';
import 'abstract_type_declaration.dart';

/// Similar to variable, but the value is a type.
/// And can have generic type parameters.
class HTTypeAliasDeclaration extends HTDeclaration
    implements HasGenericTypeParameter {
  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  final HTType _declType;

  HTType? _resolvedDeclType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  @override
  HTType get declType => _resolvedDeclType ?? _declType;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTTypeAliasDeclaration({
    required String id,
    required HTType declType,
    super.classId,
    super.closure,
    super.source,
    super.documentation,
    this.genericTypeParameters = const [],
    super.isExternal = false,
    super.isStatic = false,
    super.isConst = false,
    super.isMutable = false,
    super.isTopLevel = false,
  })  : _declType = declType,
        super(id: id);

  @override
  void resolve() {
    if (_isResolved) {
      return;
    }
    if (closure != null) {
      _resolvedDeclType = _declType.resolve(closure!);
      _isResolved = true;
    }
  }

  @override
  HTTypeAliasDeclaration clone() => HTTypeAliasDeclaration(
      id: id!,
      declType: declType,
      classId: classId,
      closure: closure,
      genericTypeParameters: genericTypeParameters,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isMutable: isMutable,
      isTopLevel: isTopLevel);
}
