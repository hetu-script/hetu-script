import 'package:hetu_script/type/unresolved.dart';
import 'package:quiver/core.dart';

import '../declaration/class/class_declaration.dart';
import 'type.dart';

/// A type checks ids and its super types.
class HTNominalType extends HTType {
  final HTClassDeclaration klass;
  // late final Iterable<HTType> implemented;
  // late final Iterable<HTType> mixined;

  final List<HTType> typeArgs;
  final bool isNullable;

  @override
  String get id => super.id!;

  HTNominalType(this.klass, {this.typeArgs = const [], this.isNullable = false})
      : super(klass.id!);

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
    if (other == null) return true;

    if (other.isTop) return true;

    if (other.isBottom) return false;

    if (other is HTUnresolvedType || other is HTNominalType) {
      if (other is HTNominalType) {
        if (isNullable != other.isNullable) return false;
        if (typeArgs.length != other.typeArgs.length) return false;
        for (var i = 0; i < typeArgs.length; ++i) {
          final arg = typeArgs[i];
          if (arg.isNotA(other.typeArgs[i])) return false;
        }
      }

      if (id == other.id) {
        return true;
      } else {
        var curSuperType = klass.superType;
        while (curSuperType != null) {
          var curSuperClass = (curSuperType as HTNominalType).klass;
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
}
