import '../error/error.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/namespace/declaration_namespace.dart';
import '../declaration/type/abstract_type_declaration.dart';
import '../declaration/type/type_alias_declaration.dart';
import 'function.dart';
import 'nominal.dart';
import 'type.dart';

/// A supposed type, could be a type alias or a nominal type or a type within a namespace.
///
/// The interpreter will later trying to resolved it to a concrete type.
class HTUnresolvedNominalType extends HTType {
  @override
  bool get isResolved => false;

  final List<HTType> typeArgs;
  final bool isNullable;
  final List<String> namespacesWithin;

  @override
  String get id => super.id!;

  const HTUnresolvedNominalType(
    String id, {
    this.typeArgs = const [],
    this.isNullable = false,
    this.namespacesWithin = const [],
  }) : super(id);

  @override
  HTType resolve(HTDeclarationNamespace namespace) {
    HTDeclarationNamespace nsp = namespace;
    if (namespacesWithin.isNotEmpty) {
      for (final id in namespacesWithin) {
        nsp = nsp.memberGet(id, from: namespace.fullName, isRecursive: true);
      }
    }
    var type = nsp.memberGet(id, from: namespace.fullName, isRecursive: true);
    if (type is HTType && type.isResolved) {
      return type;
    } else if (type is HTAbstractTypeDeclaration) {
      if (type is HTTypeAliasDeclaration) {
        type.resolve();
        return type.declType;
      } else if (type is HTClassDeclaration) {
        final resolvedTypeArgs = <HTType>[];
        for (final arg in typeArgs) {
          final resolved = arg.resolve(namespace);
          resolvedTypeArgs.add(resolved);
        }
        return HTNominalType(type, typeArgs: resolvedTypeArgs);
      }
    }

    throw HTError.notType(id);
  }
}

/// A supposed parameter type.
///
/// The interpreter will later trying to resolved it to a concrete type.
class HTUnresolvedParameterType {
  final HTType declType;

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  bool get isNamed => id != null;

  /// Wether this is a named parameter.
  final String? id;

  const HTUnresolvedParameterType({
    this.id,
    required this.declType,
    required this.isOptional,
    required this.isVariadic,
  });
}

/// A supposed function type.
///
/// The interpreter will later trying to resolved it to a concrete type.
class HTUnresolvedFunctionType extends HTType {
  @override
  bool get isResolved => false;
}

/// A supposed structure type.
///
/// The interpreter will later trying to resolved it to a concrete type.
class HTUnresolvedStructuralType extends HTType {
  @override
  bool get isResolved => false;
}
