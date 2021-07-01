import '../grammar/lexicon.dart';
import '../error/error.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/namespace.dart';
import '../ast/ast.dart' show TypeExpr;
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

  @override
  final List<HTUnresolvedType> typeArgs;

  const HTUnresolvedType(String id,
      {this.typeArgs = const [], bool isNullable = false})
      : super(id, typeArgs: typeArgs, isNullable: isNullable);

  factory HTUnresolvedType.fromAst(TypeExpr? ast) {
    if (ast != null) {
      return HTUnresolvedType(ast.id,
          typeArgs: ast.arguments
              .map((expr) => HTUnresolvedType.fromAst(expr))
              .toList(),
          isNullable: ast.isNullable);
    } else {
      return HTUnresolvedType(HTLexicon.ANY);
    }
  }

  @override
  HTType resolve(HTNamespace namespace) {
    if (HTType.primitiveTypes.containsKey(id)) {
      return HTType.primitiveTypes[id]!;
    } else {
      var type = namespace.memberGet(id);
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
          throw HTError.unsupported('${HTLexicon.TYPEOF} $type');
        }
      } else {
        throw HTError.notType(id);
      }
    }
  }
}
