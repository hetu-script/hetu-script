import '../grammar/lexicon.dart';
import '../error/error.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/namespace.dart';
import '../ast/ast.dart' show TypeExpr;
import 'nominal_type.dart';
import 'type.dart';

class HTUnresolvedType extends HTType {
  @override
  bool get isResolved => false;

  const HTUnresolvedType(String id,
      {List<HTType> typeArgs = const [], bool isNullable = false})
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
      final resolvedTypeArgs = <HTType>[];
      for (final type in typeArgs) {
        final arg = type.resolve(namespace);
        resolvedTypeArgs.add(arg);
      }

      final type = namespace.memberGet(id);
      if (type is HTClassDeclaration) {
        return HTNominalType(type, typeArgs: resolvedTypeArgs);
      } else if (type is HTType && type.isResolved) {
        return type;
      } else {
        throw HTError.notType(id);
      }
    }
  }
}
