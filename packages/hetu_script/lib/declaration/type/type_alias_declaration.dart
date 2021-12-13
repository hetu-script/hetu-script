import '../../source/source.dart';
import '../../type/type.dart';
import '../generic/generic_type_parameter.dart';
import '../declaration.dart';
import '../namespace/namespace.dart';
import 'abstract_type_declaration.dart';

/// Similar to variable, but the value is a type.
/// And can have generic type parameters.
class HTTypeAliasDeclaration extends HTDeclaration
    implements HTAbstractTypeDeclaration {
  final String _id;

  @override
  String get id => _id;

  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  final HTType _declType;

  HTType? _resolvedDeclType;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type before compile to
  /// determine wether an value binding (assignment) is legal.
  HTType get declType => _resolvedDeclType ?? _declType;

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTTypeAliasDeclaration(this._id, HTType declType,
      {String? classId,
      HTNamespace? closure,
      HTSource? source,
      this.genericTypeParameters = const [],
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      bool isTopLevel = false})
      : _declType = declType,
        super(
            id: _id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable,
            isTopLevel: isTopLevel);

  @override
  void resolve() {
    if (_isResolved) {
      return;
    }
    if (closure != null) {
      _resolvedDeclType = _declType.resolve(closure!);
    } else {
      _resolvedDeclType = HTType.any;
    }
    _isResolved = true;
  }

  @override
  HTTypeAliasDeclaration clone() => HTTypeAliasDeclaration(id, declType,
      classId: classId,
      closure: closure,
      genericTypeParameters: genericTypeParameters,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isMutable: isMutable,
      isTopLevel: isTopLevel);
}
