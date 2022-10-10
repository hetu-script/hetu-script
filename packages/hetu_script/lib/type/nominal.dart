import 'package:quiver/core.dart';

import '../error/error.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/namespace/declaration_namespace.dart';
import '../declaration/type/type_alias_declaration.dart';
import 'type.dart';

/// A type checks ids and its super types.
///
/// Unresolved nominal type are type name generated in parsing process.
/// Which could lead to a type alias or a type within a namespace or a simple nominal type.
/// It would be syntactically correct, but not neccessarily actually exist.
/// Thus it needs to be resolved to become a concrete type.
class HTNominalType extends HTType {
  bool _isResolved;

  @override
  bool get isResolved => _isResolved;

  HTType? _resolvedType;

  final HTClassDeclaration? klass;
  // late final Iterable<HTType> implemented;
  // late final Iterable<HTType> mixined;

  final List<HTType> typeArgs;
  final bool isNullable;
  final List<String> namespacesWithin;

  HTNominalType({
    String? id,
    this.klass,
    this.typeArgs = const [],
    this.isNullable = false,
    this.namespacesWithin = const [],
  })  : _isResolved = klass != null,
        super(klass?.id ?? id) {
    assert(super.id != null);
  }

  // HTNominalType.fromClass(HTClass klass,
  //     {Iterable<HTValueType> typeArgs = const [],
  //     bool isNullable = false})
  //     : this(klass.id);
  // {
  // HTClass? curKlass = klass;
  // extended = <HTType>[];
  // while (curKlass != null) {
  //   if (curKlass.extendedType != null) {
  //     extended.add(curKlass.extendedType!);
  //   }
  //   curKlass = curKlass.superClass;
  // }
  // }

  @override
  bool operator ==(Object other) {
    return other is HTNominalType && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    final hashList = [];
    hashList.add(id);
    hashList.add(isNullable);
    hashList.addAll(typeArgs);
    // if (superType != null) {
    //   hashList.add(superType.hashCode);
    // }
    // for (final type in extended) {
    //   hashList.add(type.hashCode);
    // }
    // for (final type in implemented) {
    //   hashList.add(type.hashCode);
    // }
    // for (final type in mixined) {
    //   hashList.add(type.hashCode);
    // }
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool isA(HTType? other) {
    assert(other?.isResolved ?? true);

    if (other == null) return true;

    if (other.isTop) return true;

    if (other.isBottom) return false;

    if (other is HTNominalType) {
      if (isNullable != other.isNullable) return false;
      if (typeArgs.length != other.typeArgs.length) return false;
      for (var i = 0; i < typeArgs.length; ++i) {
        final arg = typeArgs[i];
        if (arg.isNotA(other.typeArgs[i])) return false;
      }

      if (id == other.id) {
        return true;
      } else if (klass != null) {
        var curSuperType = klass!.superType;
        while (curSuperType != null) {
          final curSuperClass = (curSuperType as HTNominalType).klass!;
          if (curSuperType.isA(other)) {
            return true;
          }
          curSuperType = curSuperClass.superType;
        }
        return false;
      }
    }

    return false;
  }

  @override
  HTType resolve(HTDeclarationNamespace namespace) {
    if (_isResolved) return _resolvedType ?? this;

    assert(id != null);
    assert(klass == null);

    HTDeclarationNamespace nsp = namespace;
    if (namespacesWithin.isNotEmpty) {
      for (final id in namespacesWithin) {
        nsp = nsp.memberGet(id, from: namespace.fullName, isRecursive: true);
      }
    }
    var type = nsp.memberGet(id!, from: namespace.fullName, isRecursive: true);
    if (type is HTType) {
      _resolvedType = type.resolve(nsp);
    } else if (type is HTTypeAliasDeclaration) {
      type.resolve();
      _resolvedType = type.declType;
    } else if (type is HTClassDeclaration) {
      _resolvedType = HTNominalType(
        klass: type,
        typeArgs: typeArgs.map((e) => e.resolve(nsp)).toList(),
        isNullable: isNullable,
      );
    } else {
      throw HTError.notType(id!);
    }

    _isResolved = true;
    return _resolvedType!;
  }
}
