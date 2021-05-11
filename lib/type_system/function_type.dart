import 'package:quiver/core.dart';

import '../common/lexicon.dart';
import 'type.dart';

class HTParameterType extends HTType {
  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a named parameter.
  final bool isNamed;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  HTParameterType(String id,
      {List<HTType> typeArgs = const [],
      bool isNullable = false,
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(id, typeArgs: typeArgs, isNullable: isNullable);

  @override
  bool isA(dynamic other) {
    if (other == HTType.ANY) {
      return true;
    } else if (other is HTParameterType) {
      if (isNamed && (id != other.id)) {
        return false;
      } else if ((isOptional != other.isOptional) ||
          (isNamed != other.isNamed) ||
          (isVariadic != other.isVariadic)) {
        return false;
      } else if (super.isNotA(other)) {
        return false;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }
}

class HTFunctionType extends HTType {
  final Iterable<String> genericTypeParameters;
  final Map<String, HTParameterType> parameterTypes;
  final HTType returnType;

  HTFunctionType(
      {this.genericTypeParameters = const [],
      this.parameterTypes = const {},
      this.returnType = HTType.ANY})
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
  bool isA(dynamic other) {
    if (other == HTType.ANY) {
      return true;
    } else if (other is HTFunctionType) {
      if (genericTypeParameters.length != other.genericTypeParameters.length) {
        return false;
      } else if (returnType.isNotA(other.returnType)) {
        return false;
      } else {
        var i = 0;
        for (final paramKey in parameterTypes.keys) {
          final param = parameterTypes[paramKey]!;
          HTParameterType? otherParam;
          if (other.parameterTypes.length > i) {
            otherParam = other.parameterTypes[paramKey];
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
    } else if (other == HTType.function) {
      return true;
    } else {
      return false;
    }
  }
}
