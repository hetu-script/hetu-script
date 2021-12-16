import '../error/error.dart';
import '../declaration/class/class_declaration.dart';
import '../value/namespace/namespace.dart';
import '../declaration/type/abstract_type_declaration.dart';
import '../declaration/type/type_alias_declaration.dart';
import 'function_type.dart';
import 'nominal_type.dart';
import 'type.dart';

/// A supposed type generated from ast,
/// will resolved to a concrete type form as
/// nominal(class), function, etc...
class HTUnresolvedType extends HTType {
  @override
  bool get isResolved => false;

  const HTUnresolvedType(String id,
      {List<HTType> typeArgs = const [], bool isNullable = false})
      : super(id, typeArgs: typeArgs, isNullable: isNullable);

  @override
  HTType resolve(HTNamespace namespace) {
    if (HTType.primitiveTypes.containsKey(id)) {
      return HTType.primitiveTypes[id]!;
    } else {
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
}
