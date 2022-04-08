import 'package:quiver/core.dart';

import '../value/entity.dart';
import '../declaration/namespace/declaration_namespace.dart';
// import 'unresolved_type.dart';
// import '../ast/ast.dart' show TypeExpr, FuncTypeExpr;
// import 'function_type.dart';
// import '../declaration/generic/generic_type_parameter.dart';

enum PrimitiveTypeCategory {
  none,
  any,
  unknown,
  vo1d,
  never,
}

/// Type is basically a set of things.
/// It is used to check errors in code.
abstract class HTType with HTEntity {
  // static String parseBaseType(String typeString) {
  //   final argsStart = typeString.indexOf(HTLexicon.typeParameterStart);
  //   if (argsStart != -1) {
  //     final id = typeString.substring(0, argsStart);
  //     return id;
  //   } else {
  //     return typeString;
  //   }
  // }

  bool get isResolved => true;

  HTType resolve(HTDeclarationNamespace namespace) => this;

  final String? id;
  final List<HTType> typeArgs;
  final bool isNullable;

  const HTType({this.id, this.typeArgs = const [], this.isNullable = false});

  // factory HTType.fromAST(TypeExpr? ast) {
  //   if (ast != null) {
  //     if (ast is FuncTypeExpr) {
  //       return HTFunctionType(
  //           genericTypeParameters: ast.genericTypeParameters
  //               .map((param) => HTGenericTypeParameter(param.id.id,
  //                   superType: HTType.fromAST(param.superType)))
  //               .toList(),
  //           parameterTypes: ast.paramTypes
  //               .map((param) => HTParameterType(HTType.fromAST(param.declType),
  //                   isOptional: param.isOptional,
  //                   isVariadic: param.isVariadic,
  //                   id: param.id?.id))
  //               .toList(),
  //           returnType: HTType.fromAST(ast.returnType));
  //     } else {
  //       switch (ast.primitiveTypeCategory) {
  //         case PrimitiveTypeCategory.none:
  //           return HTUnresolvedType(ast.id!.id,
  //               typeArgs:
  //                   ast.arguments.map((expr) => HTType.fromAST(expr)).toList(),
  //               isNullable: ast.isNullable);
  //         case PrimitiveTypeCategory.any:
  //           return HTTypeAny(ast.id!.id);
  //         case PrimitiveTypeCategory.vo1d:
  //           return HTTypeVoid(ast.id!.id);
  //         case PrimitiveTypeCategory.never:
  //           return HTTypeNever(ast.id!.id);
  //       }
  //     }
  //   } else {
  //     return HTType.any;
  //   }
  // }

  @override
  int get hashCode {
    final hashList = [];
    hashList.add(id);
    hashList.add(isNullable);
    for (final typeArg in typeArgs) {
      hashList.add(typeArg);
    }
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool operator ==(Object other) =>
      other is HTType && hashCode == other.hashCode;

  /// Wether object of this [HTType] can be assigned to other [HTType]
  bool isA(HTType? other) {
    if (other == null) {
      return true;
    } else if (other is HTTypeAny) {
      return true;
    }

    return false;
  }

  /// Wether object of this [HTType] cannot be assigned to other [HTType]
  bool isNotA(HTType? other) => !isA(other);
}

/// A special type that only used on declaration.
/// There's no runtime value that has `any` as its type.
class HTTypeAny extends HTType {
  const HTTypeAny(String id) : super(id: id);
}

/// A special type that only used on declaration.
/// There's no runtime value that has `unknown` as its type.
class HTTypeUnknown extends HTType {
  const HTTypeUnknown(String id) : super(id: id);

  @override
  bool isA(HTType? other) {
    if (other == null) {
      return true;
    } else if (other is HTTypeAny) {
      return true;
    } else if (other is HTTypeUnknown) {
      return true;
    }

    return false;
  }
}

/// A special type that only used on declaration.
/// There's no runtime value that has `void` as its type.
class HTTypeVoid extends HTType {
  const HTTypeVoid(String id) : super(id: id);

  @override
  bool isA(HTType? other) {
    if (other is HTTypeVoid) {
      return true;
    }

    return false;
  }
}

/// A special type that only used on declaration.
/// There's no runtime value that has `never` as its type.
class HTTypeNever extends HTType {
  const HTTypeNever(String id) : super(id: id);

  @override
  bool isA(HTType? other) => false;
}

/// A special type that only used on null value.
/// Cannot be used on declaration.
class HTTypeNull extends HTType {
  const HTTypeNull(String id) : super(id: id);

  @override
  bool isA(HTType? other) {
    if (other == null) {
      return true;
    } else if (other is HTTypeNull) {
      return true;
    }

    return false;
  }
}
