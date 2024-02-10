import 'package:meta/meta.dart';

import '../../type/type.dart';
import '../declaration.dart';
import '../type/abstract_type_declaration.dart';
import '../generic/generic_type_parameter.dart';
import '../../common/internal_identifier.dart';

class HTClassDeclaration extends HTDeclaration
    implements HasGenericTypeParameter {
  String get name => id ?? InternalIdentifier.anonymousClass;

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

  bool _isResolved = false;
  @override
  bool get isResolved => _isResolved;

  HTClassDeclaration({
    super.id,
    super.classId,
    super.closure,
    super.source,
    super.documentation,
    this.genericTypeParameters = const [],
    HTType? superType,
    this.implementsTypes = const [],
    this.withTypes = const [],
    super.isPrivate,
    super.isExternal = false,
    super.isTopLevel = false,
    this.isAbstract = false,
    this.isEnum = false,
  }) : _unresolvedSuperType = superType {
    if (_unresolvedSuperType != null && _unresolvedSuperType!.isResolved) {
      _resolvedSuperType = _unresolvedSuperType;
    }
  }

  @override
  @mustCallSuper
  void resolve() {
    if (_isResolved) {
      return;
    }
    if ((closure != null) && (_unresolvedSuperType != null)) {
      _resolvedSuperType = _unresolvedSuperType!.resolve(closure!);
    }
    _isResolved = true;
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
      isAbstract: isAbstract,
      isEnum: isEnum,
      isTopLevel: isTopLevel);
}
