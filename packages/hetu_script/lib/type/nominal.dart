import 'package:quiver/core.dart';

import '../declaration/class/class_declaration.dart';
import 'type.dart';

/// A type checks ids and its super types.
class HTNominalType extends HTType {
  final HTClassDeclaration klass;
  // late final Iterable<HTType> implemented;
  // late final Iterable<HTType> mixined;

  final String _id;

  @override
  String get id => _id;

  HTNominalType(this.klass, {List<HTType> typeArgs = const []})
      : _id = klass.id!,
        super(id: klass.id!, typeArgs: typeArgs);

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
    // hashList.add(isNullable.hashCode);
    for (final typeArg in typeArgs) {
      hashList.add(typeArg);
    }
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

    if (other is! HTNominalType) return false;

    if (this == other) {
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
}
