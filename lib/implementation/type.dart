import 'package:quiver/core.dart';

import 'lexicon.dart';
import 'object.dart';
import 'class.dart';
import 'interpreter.dart';
import 'declaration.dart';

abstract class HTType with HTObject {
  static const TYPE = _PrimitiveType(HTLexicon.TYPE);
  static const ANY = _PrimitiveType(HTLexicon.ANY);
  static const NULL = _PrimitiveType(HTLexicon.NULL);
  static const VOID = _PrimitiveType(HTLexicon.VOID);
  static const ENUM = _PrimitiveType(HTLexicon.ENUM);
  static const NAMESPACE = _PrimitiveType(HTLexicon.NAMESPACE);
  static final CLASS = _PrimitiveType(HTLexicon.CLASS);
  static const FUNCTION = _PrimitiveType(HTLexicon.FUNCTION);
  static const unknown = _PrimitiveType(HTLexicon.unknown);

  // static final integer =
  //     HTObjectType(HTLexicon.integer, extended: [HTType.number]);

  // static final float = HTObjectType(HTLexicon.float, extended: [HTType.number]);

  static String parseBaseType(String typeString) {
    final argsStart = typeString.indexOf(HTLexicon.typesBracketLeft);
    if (argsStart != -1) {
      final id = typeString.substring(0, argsStart);
      return id;
    } else {
      return typeString;
    }
  }

  /// A [HTType]'s type is itself.
  @override
  HTValueType get valueType => HTType.TYPE;

  final String id;

  bool get isPrimitive => false;
  bool get isResolved => false;

  const HTType(this.id);
  // {this.typeArgs = const <HTType>[], this.isNullable = false});

  @override
  String toString() {
    var typeString = StringBuffer();
    typeString.write(id);
    // if (typeArgs.isNotEmpty) {
    //   typeString.write(HTLexicon.angleLeft);
    //   for (var i = 0; i < typeArgs.length; ++i) {
    //     typeString.write(typeArgs[i]);
    //     if ((typeArgs.length > 1) && (i != typeArgs.length - 1)) {
    //       typeString.write('${HTLexicon.comma} ');
    //     }
    //   }
    //   typeString.write(HTLexicon.angleRight);
    // }
    // if (isNullable) {
    //   typeString.write(HTLexicon.nullable);
    // }
    return typeString.toString();
  }

  @override
  int get hashCode {
    final hashList = <int>[];
    hashList.add(id.hashCode);
    // hashList.add(isNullable.hashCode);
    // for (final typeArg in typeArgs) {
    //   hashList.add(typeArg.hashCode);
    // }
    final hash = hashObjects(hashList);
    return hash;
  }

  /// Wether object of this [HTType] can be assigned to other [HTType]
  bool isA(Object other) {
    if (this == HTType.unknown) {
      if (other == HTType.ANY || other == HTType.unknown) {
        return true;
      } else {
        return false;
      }
    } else if (other == HTType.ANY) {
      return true;
    } else if (other is HTType) {
      if (this == HTType.NULL) {
        // TODO: 这里是 nullable 功能的开关
        // if (other.isNullable) {
        //   return true;
        // } else {
        //   return false;
        // }
        return true;
      } else if (id != other.id) {
        return false;
      }
      // else if (typeArgs.length != other.typeArgs.length) {
      //   return false;
      // }
      else {
        // for (var i = 0; i < typeArgs.length; ++i) {
        //   if (!typeArgs[i].isA(typeArgs[i])) {
        //     return false;
        //   }
        // }
        return true;
      }
    } else {
      return false;
    }
  }

  /// Wether object of this [HTType] cannot be assigned to other [HTType]
  bool isNotA(Object other) => !isA(other);

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}

class HTDeclarationType extends HTType with HTDeclaration {
  final bool isNullable;
  final Iterable<HTDeclarationType> typeArgs;

  HTDeclarationType(String id,
      {this.typeArgs = const <HTDeclarationType>[], this.isNullable = false})
      : super(id) {
    this.id = id;
  }

  /// initialize the declared type if it's a class name.
  /// only return the [HTClass] when its a non-external class
  HTValueType resolve(Interpreter interpreter) {
    final typeDef = interpreter.curNamespace
        .fetch(id, from: interpreter.curNamespace.fullName);
    if (typeDef is HTClass) {
      return HTNominalType(typeDef,
          typeArgs: typeArgs.map((type) => type.resolve(interpreter)));
    } else {
      // if (typeDef is HTFunctionObjectType)
      return typeDef;
    }
  }
}

abstract class HTValueType extends HTType {
  const HTValueType(String id) : super(id);
}

class _PrimitiveType extends HTValueType {
  @override
  bool get isPrimitive => true;

  @override
  bool get isResolved => true;

  const _PrimitiveType(String id) : super(id);
}

class HTExternalType extends HTValueType {
  const HTExternalType(String id) : super(id);
}

class HTNominalType extends HTValueType {
  final HTClass klass;
  final Iterable<HTValueType> typeArgs;
  // late final Iterable<HTType> implemented;
  // late final Iterable<HTType> mixined;

  HTNominalType(this.klass, {this.typeArgs = const <HTValueType>[]})
      : super(klass.id);

  // HTNominalType.fromClass(HTClass klass,
  //     {Iterable<HTValueType> typeArgs = const <HTValueType>[],
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
  bool isA(Object other) {
    if (other is HTType) {
      if (other == HTType.ANY) {
        return true;
      } else if (this == other) {
        return true;
      } else {
        // for (final type in extended) {
        //   if (type.isA(other)) {
        //     return true;
        //   }
        // }
        // for (var i = 0; i < implemented.length; ++i) {
        //   if (implemented[i].isA(other)) {
        //     return true;
        //   }
        // }
        // for (var i = 0; i < mixined.length; ++i) {
        //   if (mixined[i].isA(other)) {
        //     return true;
        //   }
        // }
        return false;
      }
    } else {
      return false;
    }
  }
}

class HTParameterType {
  final String id;

  final HTDeclarationType? declType;

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a named parameter.
  final bool isNamed;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  HTParameterType(this.id,
      {this.declType,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false});

  bool isA(Object other) {
    if (other is HTParameterType) {
      if (isNamed && (id != other.id)) {
        return false;
      } else if ((isOptional != other.isOptional) ||
          (isNamed != other.isNamed) ||
          (isVariadic != other.isVariadic)) {
        return false;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  bool isNotA(Object other) => !isA(other);
}

class HTFunctionDeclarationType extends HTDeclarationType {
  final Iterable<String> genericTypeParameters;
  final Map<String, HTParameterType> parameterTypes;
  final HTType returnType;

  HTFunctionDeclarationType(
      {this.parameterTypes = const {}, this.returnType = HTType.ANY})
      : super(HTLexicon.FUNCTION);
}

class HTFunctionValueType extends HTValueType {
  final Map<String, HTParameterType> parameterTypes;
  final HTType returnType;

  HTFunctionValueType(
      {this.parameterTypes = const {}, this.returnType = HTType.ANY})
      : super(HTLexicon.FUNCTION);

  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.FUNCTION);
    // if (valueType.typeArgs.isNotEmpty) {
    //   result.write(HTLexicon.angleLeft);
    //   for (var i = 0; i < valueType.typeArgs.length; ++i) {
    //     result.write(valueType.typeArgs[i]);
    //     if (i < valueType.typeArgs.length - 1) {
    //       result.write('${HTLexicon.comma} ');
    //     }
    //   }
    //   result.write(HTLexicon.angleRight);
    // }

    result.write(HTLexicon.roundLeft);

    var i = 0;
    var optionalStarted = false;
    var namedStarted = false;
    for (final param in parameterTypes.values) {
      if (param.isVariadic) {
        result.write(HTLexicon.varargs + ' ');
      }
      if (param.isOptional && !optionalStarted) {
        optionalStarted = true;
        result.write(HTLexicon.squareLeft);
      } else if (param.isNamed && !namedStarted) {
        namedStarted = true;
        result.write(HTLexicon.curlyLeft);
      }
      result.write(param.toString());
      if (i < parameterTypes.length - 1) {
        result.write('${HTLexicon.comma} ');
      }
      if (optionalStarted) {
        result.write(HTLexicon.squareRight);
      } else if (namedStarted) {
        namedStarted = true;
        result.write(HTLexicon.curlyRight);
      }
      ++i;
    }
    result.write(
        '${HTLexicon.roundRight} ${HTLexicon.arrow} ' + returnType.toString());
    return result.toString();
  }

  @override
  int get hashCode {
    final hashList = <int>[];
    hashList.add(id.hashCode);
    // hashList.add(isNullable.hashCode);
    // for (final typeArg in typeArgs) {
    //   hashList.add(typeArg.hashCode);
    // }
    hashList.add(genericTypeParameters.length.hashCode);
    for (final paramType in parameterTypes.keys) {
      hashList.add(paramType.hashCode);
      hashList.add(parameterTypes[paramType].hashCode);
    }
    hashList.add(returnType.hashCode);
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool isA(Object other) {
    if (other == HTType.ANY) {
      return true;
    } else if (other is HTFunctionValueType) {
      if (genericTypeParameters.length != other.genericTypeParameters.length) {
        return false;
      } else if (returnType.isNotA(other.returnType)) {
        return false;
      } else {
        var i = 0;
        for (final paramKey in parameterTypes.keys) {
          final param = parameterTypes[paramKey]!;
          HTParameterType? otherParam;
          if (param.isNamed) {
            otherParam = other.parameterTypes[paramKey];
          } else {
            otherParam = other.parameterTypes.values.elementAt(i);
          }
          if (!param.isOptional && !param.isVariadic) {
            if (otherParam == null || param.isNotA(otherParam)) {
              return false;
            }
          }
          ++i;
        }
        return true;
      }
    } else if (other == HTType.FUNCTION) {
      return true;
    } else {
      return false;
    }
  }
}

String conveobjectTypeArgsToString(List<HTType> typeArgs) {
  final sb = StringBuffer();
  if (typeArgs.isNotEmpty) {
    sb.write(HTLexicon.angleLeft);
    for (final arg in typeArgs) {
      sb.write(arg.toString());
    }
    sb.write(HTLexicon.angleRight);
  }
  return sb.toString();
}
