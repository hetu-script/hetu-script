import 'package:quiver/core.dart';

import '../declaration/class/class_declaration.dart';
import 'type.dart';

class HTNominalType extends HTType {
  final HTClassDeclaration klass;
  // late final Iterable<HTType> implemented;
  // late final Iterable<HTType> mixined;

  HTNominalType(this.klass, {List<HTType> typeArgs = const []})
      : super(klass.name, typeArgs: typeArgs);

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
    } else {
      return false;
    }
  }
}
