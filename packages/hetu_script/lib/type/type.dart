import '../value/entity.dart';
import '../declaration/namespace/declaration_namespace.dart';

/// Type is basically a set of things.
/// It is used to check errors in code.
abstract class HTType with HTEntity {
  bool get isResolved => true;

  /// Every type is assignable to a top type,
  bool get isTop => false;

  /// This type is assignable to all other types.
  bool get isBottom => false;

  HTType resolve(HTDeclarationNamespace namespace) => this;

  final String? id;

  const HTType([this.id]);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      other is HTType && hashCode == other.hashCode;

  /// Check wether value of this [HTType] can be assigned to other [HTType].
  bool isA(HTType? other);

  /// Wether object of this [HTType] cannot be assigned to other [HTType]
  bool isNotA(HTType? other) => !isA(other);
}

/// Types that predefined by the interpreter.
class HTIntrinsicType extends HTType {
  @override
  final bool isTop;

  @override
  final bool isBottom;

  const HTIntrinsicType(super.id,
      {required this.isTop, required this.isBottom});

  @override
  bool isA(HTType? other) {
    if (other == null) return true;

    if (other.isTop) return true;

    if (other.isBottom && isBottom) return true;

    if (id == other.id) return true;

    return false;
  }
}

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
/// Every type is assignable to type any (the meaning of `top`),
/// and type any is assignable to every type (the meaning of `bottom`).
///
/// With `any` we lose any protection that is normally given to us by static type system.
///
/// Therefore, it should only be used as a last resort
/// when we can’t use more specific types or `unknown`.
class HTTypeAny extends HTIntrinsicType {
  const HTTypeAny(super.id) : super(isTop: true, isBottom: true);
}

/// A `top` type, basically a type-safe version of the type any.
///
/// Every type is assignable to type unknown (the meaning of `top`).
///
/// Type unknown cannot assign to other types except `any` & `unknown`.
///
/// You cannot do anything with it, unless you do an explicit type assertion.
class HTTypeUnknown extends HTIntrinsicType {
  const HTTypeUnknown(super.id) : super(isTop: true, isBottom: false);
}

/// A `bottom` type. A function whose return type is never cannot return.
/// For example by throwing an error or looping forever.
class HTTypeNever extends HTIntrinsicType {
  const HTTypeNever(super.id) : super(isTop: false, isBottom: true);
}

/// A `empty` type. A function whose return type is empty.
/// It may contain return statement, but cannot return any value.
/// And you cannot use the function call result in any operation.
class HTTypeVoid extends HTIntrinsicType {
  const HTTypeVoid(super.id) : super(isTop: false, isBottom: true);
}

/// A `zero` type. It's the type of runtime null value.
/// You cannot get this type via expression or declaration.
class HTTypeNull extends HTIntrinsicType {
  const HTTypeNull(super.id) : super(isTop: false, isBottom: false);
}

class HTTypeType extends HTIntrinsicType {
  const HTTypeType(super.id) : super(isTop: false, isBottom: false);
}

/// A `function` type. It's the same to type `() -> any`.
class HTTypeFunction extends HTIntrinsicType {
  const HTTypeFunction(super.id) : super(isTop: false, isBottom: false);
}

class HTTypeNamespace extends HTIntrinsicType {
  const HTTypeNamespace(super.id) : super(isTop: false, isBottom: false);
}
