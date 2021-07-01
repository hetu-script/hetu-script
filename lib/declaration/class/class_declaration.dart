import '../../type/type.dart';
import '../../source/source.dart';
import '../../grammar/semantic.dart';
import '../namespace.dart';
import '../declaration.dart';
import '../type/abstract_type_declaration.dart';
import '../../type/generic_type_parameter.dart';

class HTClassDeclaration extends HTDeclaration
    implements HTAbstractTypeDeclaration {
  String get name => id ?? SemanticNames.anonymousClass;

  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  final HTType? _unresolvedSuperType;

  HTType? _resolvedSuperType;

  HTType? get superType => _resolvedSuperType ?? _unresolvedSuperType;

  /// Mixined class of this class.
  /// Those mixined class can not have any constructors.
  final Iterable<HTType> withTypes;

  /// Implemented classes of this class.
  /// Implements only inherits methods declaration,
  /// and the child must re-define all implements methods,
  /// and the re-definition must be of the same function signature.
  final Iterable<HTType> implementsTypes;

  final bool isAbstract;

  final bool isEnum;

  bool get isNested => classId != null;

  HTClassDeclaration(
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      this.genericTypeParameters = const [],
      HTType? superType,
      this.implementsTypes = const [],
      this.withTypes = const [],
      bool isExternal = false,
      this.isAbstract = false,
      this.isEnum = false,
      bool isTopLevel = false})
      : _unresolvedSuperType = superType,
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isTopLevel: isTopLevel) {
    if (_unresolvedSuperType != null && _unresolvedSuperType!.isResolved) {
      _resolvedSuperType = _unresolvedSuperType;
    }
  }

  @override
  void resolve() {
    super.resolve();
    if ((closure != null) && (_unresolvedSuperType != null)) {
      _resolvedSuperType = _unresolvedSuperType!.resolve(closure!);
    }
  }

  @override
  HTClassDeclaration clone() => HTClassDeclaration(
      id: id,
      classId: classId,
      closure: closure,
      source: source,
      genericTypeParameters: genericTypeParameters,
      superType: superType,
      implementsTypes: implementsTypes,
      withTypes: withTypes,
      isExternal: isExternal,
      isAbstract: isAbstract);
}
