import 'package:quiver/core.dart';

import 'lexicon.dart';
import 'object.dart';

class HTType with HTObject {
  static const TYPE = HTType(HTLexicon.TYPE);
  static const ANY = HTType(HTLexicon.ANY);
  static const NULL = HTType(HTLexicon.NULL);
  static const VOID = HTType(HTLexicon.VOID);
  static const CLASS = HTType(HTLexicon.CLASS);
  static const ENUM = HTType(HTLexicon.ENUM);
  static const NAMESPACE = HTType(HTLexicon.NAMESPACE);
  static const object = HTType(HTLexicon.object);
  static const function = HTType(HTLexicon.function);
  static const unknown = HTType(HTLexicon.unknown);
  static const number = HTType(HTLexicon.number);
  static const boolean = HTType(HTLexicon.boolean);
  static const string = HTType(HTLexicon.string);
  static const list = HTType(HTLexicon.list);
  static const map = HTType(HTLexicon.map);

  @override
  HTType get type => HTType.TYPE;

  static String parseBaseType(String typeString) {
    final argsStart = typeString.indexOf(HTLexicon.typesBracketLeft);
    if (argsStart != -1) {
      final id = typeString.substring(0, argsStart);
      return id;
    } else {
      return typeString;
    }
  }

  final String typeName;
  final List<HTType> typeArgs;
  final bool isNullable;

  const HTType(this.typeName,
      {this.typeArgs = const [], this.isNullable = false});

  @override
  String toString() {
    var typename = StringBuffer();
    typename.write(typeName);
    if (typeArgs.isNotEmpty) {
      typename.write(HTLexicon.angleLeft);
      for (var i = 0; i < typeArgs.length; ++i) {
        typename.write(typeArgs[i]);
        if ((typeArgs.length > 1) && (i != typeArgs.length - 1)) {
          typename.write('${HTLexicon.comma} ');
        }
      }
      typename.write(HTLexicon.angleRight);
    }
    if (isNullable) {
      typename.write(HTLexicon.nullable);
    }
    return typename.toString();
  }

  @override
  int get hashCode {
    final hashList = <int>[];
    hashList.add(typeName.hashCode);
    hashList.add(isNullable.hashCode);
    for (final typeArg in typeArgs) {
      hashList.add(typeArg.hashCode);
    }
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
      }
      if (typeName != other.typeName) {
        return false;
      } else if (typeArgs.length != other.typeArgs.length) {
        return false;
      } else {
        for (var i = 0; i < typeArgs.length; ++i) {
          if (!typeArgs[i].isA(typeArgs[i])) {
            return false;
          }
        }
        return true;
      }
    } else {
      return false;
    }
  }

  bool isNotA(Object other) => !isA(other);
}

class HTInstanceType extends HTType {
  final String moduleUniqueKey;
  final List<HTType> extended;
  final List<HTType> implemented;
  final List<HTType> mixined;

  const HTInstanceType(String typeName, this.moduleUniqueKey,
      {List<HTType> typeArgs = const [],
      this.extended = const [],
      this.implemented = const [],
      this.mixined = const []})
      : super(typeName, typeArgs: typeArgs, isNullable: false);

  @override
  int get hashCode {
    final hashList = <int>[];
    hashList.add(typeName.hashCode);
    hashList.add(isNullable.hashCode);
    for (final typeArg in typeArgs) {
      hashList.add(typeArg.hashCode);
    }
    for (final type in extended) {
      hashList.add(type.hashCode);
    }
    for (final type in implemented) {
      hashList.add(type.hashCode);
    }
    for (final type in mixined) {
      hashList.add(type.hashCode);
    }
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool isA(Object other) {
    if (other is HTType) {
      if (other == HTType.ANY) {
        return true;
      } else if (other is HTInstanceType &&
          moduleUniqueKey != other.moduleUniqueKey) {
        return false;
      }
      for (var i = 0; i < extended.length; ++i) {
        if (extended[i].isA(other)) {
          return true;
        }
      }
      for (var i = 0; i < implemented.length; ++i) {
        if (implemented[i].isA(other)) {
          return true;
        }
      }
      for (var i = 0; i < mixined.length; ++i) {
        if (mixined[i].isA(other)) {
          return true;
        }
      }
      return false;
    } else {
      return false;
    }
  }
}

class HTParameterType extends HTType {
  HTParameterType(String id, HTType type) : super(type.typeName);
}

/// [HTFunctionType] is equivalent to Dart's function typedef,
class HTFunctionType extends HTType {
  final List<String> typeParameters;
  final Map<String, HTParameterType> parameterTypes;
  final HTType returnType;

  const HTFunctionType(
      {this.typeParameters = const [],
      this.parameterTypes = const {},
      this.returnType = HTType.ANY})
      : super(HTLexicon.function);

  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.function);
    if (typeParameters.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < typeParameters.length; ++i) {
        result.write(typeParameters[i]);
        if ((typeParameters.length > 1) && (i != typeParameters.length - 1)) {
          result.write(', ');
        }
      }
      result.write('>');
    }

    result.write('(');

    for (final paramType in positionalParameterTypes) {
      result.write(paramType.toString());
      //if (param.initializer != null)
      if (positionalParameterTypes.length > 1) result.write(', ');
    }
    result.write(') -> ' + returnType.toString());
    return result.toString();
  }

  @override
  int get hashCode {
    final hashList = <int>[];
    hashList.add(typeName.hashCode);
    hashList.add(isNullable.hashCode);
    for (final typeArg in typeArgs) {
      hashList.add(typeArg.hashCode);
    }
    hashList.add(typeParameters.length.hashCode);
    for (final paramType in positionalParameterTypes) {
      hashList.add(paramType.hashCode);
    }
    hashList.add(returnType.hashCode);
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool isA(Object other) {
    if (other == HTType.ANY) {
      return true;
    } else if (other is HTFunctionType) {
      if (typeParameters.length != other.typeParameters.length) {
        return false;
      } else if (positionalParameterTypes.length !=
          other.positionalParameterTypes.length) {
        return false;
      } else {
        if (returnType.isNotA(other.returnType)) {
          return false;
        }
        for (var i = 0; i < positionalParameterTypes.length; ++i) {
          if (other.positionalParameterTypes[i]
              .isNotA(positionalParameterTypes[i])) {
            return false;
          }
        }
      }
      return true;
    } else {
      return false;
    }
  }
}
