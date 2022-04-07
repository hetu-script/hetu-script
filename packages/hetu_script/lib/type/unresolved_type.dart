import '../error/error.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/namespace/declaration_namespace.dart';
import '../declaration/type/abstract_type_declaration.dart';
import '../declaration/type/type_alias_declaration.dart';
import 'function_type.dart';
import 'nominal_type.dart';
import 'type.dart';

/// A supposed type,
/// the interpreter will later trying to resolved it
/// to a concrete type.
///
/// For types other than nominal type, it will resolve to itself.
///
/// For nominal type, it will
class HTUnresolvedType extends HTType {
  @override
  bool get isResolved => false;

  final String _id;

  @override
  String get id => _id;

  const HTUnresolvedType(String id,
      {List<HTType> typeArgs = const [], bool isNullable = false})
      : _id = id,
        super(id: id, typeArgs: typeArgs, isNullable: isNullable);

  @override
  HTType resolve(HTDeclarationNamespace namespace) {
    var type =
        namespace.memberGet(id, from: namespace.fullName, recursive: true);
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
