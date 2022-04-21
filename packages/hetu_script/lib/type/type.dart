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
  bool get isResolved => true;

  bool get isTop => false;

  bool get isBottom => false;

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
  //           return HTTypeIntrinsic.any(ast.id!.id);
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
    if (other == null) return true;

    if (id != other.id) return false;
    if (isNullable != other.isNullable) return false;
    if (typeArgs.length != other.typeArgs.length) return false;

    for (final arg in typeArgs) {
      if (arg.isNotA(other)) return false;
    }

    return true;
  }

  /// Wether object of this [HTType] cannot be assigned to other [HTType]
  bool isNotA(HTType? other) => !isA(other);
}

class HTTypeIntrinsic extends HTType {
  @override
  final bool isTop;

  @override
  final bool isBottom;

  const HTTypeIntrinsic(String id,
      {required this.isTop, required this.isBottom})
      : super(id: id);

  /// A type is both `top` and `bottom`, only used on declaration for analysis.
  ///
  /// There's no runtime value that has `any` as its type.
  ///
  /// In analysis, you can do everything with it:
  ///
  /// 1, use any operator on it.
  ///
  /// 2, call it as a function.
  ///
  /// 3, get a member out of it.
  ///
  /// 4, get a subscript value out of it.
  ///
  /// Every type is assignable to type any, and type any is assignable to every type.
  ///
  /// With `any` we lose any protection that is normally given to us by static type system.
  ///
  /// Therefore, it should only be used as a last resort
  /// when we can’t use more specific types or `unknown`.
  const HTTypeIntrinsic.any(String id) : this(id, isTop: true, isBottom: true);

  /// A `top` type, basically a type-safe version of the type any.
  ///
  /// Every type is assignable to type unknown.
  ///
  /// Type unknown cannot assign to other types except `any` & `unknown`.
  ///
  /// You cannot do anything with it, unless you do an explicit type assertion.
  const HTTypeIntrinsic.unknown(String id)
      : this(id, isTop: true, isBottom: false);

  /// A `bottom` type. A function whose return type is never cannot return.
  /// For example by throwing an error or looping forever.
  const HTTypeIntrinsic.never(String id)
      : this(id, isTop: false, isBottom: true);

  /// A `empty` type. A function whose return type is empty.
  /// It may contain return statement, but cannot return any value.
  /// And you cannot use the function call result in any operation.
  const HTTypeIntrinsic.vo1d(String id)
      : this(id, isTop: false, isBottom: true);

  /// A `zero` type.
  const HTTypeIntrinsic.nu11(String id)
      : this(id, isTop: false, isBottom: true);

  @override
  bool isA(HTType? other) {
    if (other == null) return true;

    if (id == other.id) {
      return true;
    }

    if (isTop) {
      return true;
    } else if (isBottom) {
      return false;
    }

    return false;
  }
}
