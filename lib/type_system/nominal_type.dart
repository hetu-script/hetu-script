import 'package:quiver/core.dart';

import '../core/declaration/abstract_class.dart';
import 'type.dart';
import 'value_type.dart';

class HTNominalType extends HTValueType {
  final AbstractClass klass;
  // late final Iterable<HTType> implemented;
  // late final Iterable<HTType> mixined;

  HTNominalType(this.klass, {List<HTType> typeArgs = const []})
      : super(klass.id, typeArgs: typeArgs);

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
  int get hashCode {
    final hashList = <int>[];
    hashList.add(id.hashCode);
    // hashList.add(isNullable.hashCode);
    for (final typeArg in typeArgs) {
      hashList.add(typeArg.hashCode);
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
  bool isA(dynamic other) {
    if (other is HTType) {
      if (other == HTType.ANY) {
        return true;
      } else if (this == other) {
        return true;
      } else {
        // var curSuperType = klass.superType;
        // var curSuperClass = klass.superClass;
        // while (curSuperClass != null) {
        //   if (curSuperType!.isA(other)) {
        //     return true;
        //   }
        //   curSuperType = curSuperClass.superType;
        //   curSuperClass = curSuperClass.superClass;
        // }
        return false;
      }
    } else {
      return false;
    }
  }
}
