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
class HTUnresolvedType extends HTType {
  @override
  bool get isResolved => false;

  final List<HTType> typeArgs;
  final bool isNullable;
  final List<String> namespacesWithin;

  @override
  String get id => super.id!;

  const HTUnresolvedType(
    super.id, {
    this.typeArgs = const [],
    this.isNullable = false,
    this.namespacesWithin = const [],
  });

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
        type = type.declType;
      }
      final resolvedTypeArgs = <HTType>[];
      for (final arg in typeArgs) {
        final resolved = arg.resolve(namespace);
        resolvedTypeArgs.add(resolved);
      }
      if (type is HTClassDeclaration) {
        return HTNominalType(type, typeArgs: resolvedTypeArgs);
      } else if (type is HTFunctionType) {
        return type;
      } // TODO: interface type, union type, literal type etc...
      else {
        throw HTError.notType(id);
      }
    } else {
      throw HTError.notType(id);
    }
  }
}
