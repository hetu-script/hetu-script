import 'package:quiver/core.dart';

import '../declaration/type/abstract_type_declaration.dart';
import '../grammar/lexicon.dart';
import 'type.dart';
import '../declaration/generic/generic_type_parameter.dart';

class HTParameterType {
  final HTType declType;

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  bool get isNamed => id != null;

  /// Wether this is a named parameter.
  final String? id;

  const HTParameterType(this.declType,
      {required this.isOptional, required this.isVariadic, this.id});
}

class HTFunctionType extends HTType implements HTAbstractTypeDeclaration {
  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  final List<HTParameterType> parameterTypes;

  final HTType returnType;

  HTFunctionType(
      {this.genericTypeParameters = const [],
      this.parameterTypes = const [],
      this.returnType = HTType.ANY})
      : super(HTLexicon.function);

  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.function);
    if (genericTypeParameters.isNotEmpty) {
      result.write(HTLexicon.angleLeft);
      for (var i = 0; i < genericTypeParameters.length; ++i) {
        result.write(genericTypeParameters[i]);
        if (i < genericTypeParameters.length - 1) {
          result.write('${HTLexicon.comma} ');
        }
      }
      result.write(HTLexicon.angleRight);
    }

    result.write(HTLexicon.roundLeft);

    var i = 0;
    var optionalStarted = false;
    var namedStarted = false;
    for (final param in parameterTypes) {
      if (param.isVariadic) {
        result.write(HTLexicon.variadicArgs + ' ');
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
    result.write('${HTLexicon.roundRight} ${HTLexicon.singleArrow} ' +
        returnType.toString());
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
    for (final paramType in parameterTypes) {
      hashList.add(paramType.hashCode);
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
        for (var i = 0; i < parameterTypes.length; ++i) {
          final param = parameterTypes[i];
          HTParameterType? otherParam;
          if (other.parameterTypes.length > i) {
            otherParam = other.parameterTypes[i];
          }
          if (!param.isOptional && !param.isVariadic) {
            if (otherParam == null ||
                otherParam.isOptional != param.isOptional ||
                otherParam.isVariadic != param.isVariadic ||
                otherParam.isNamed != param.isNamed ||
                (otherParam.declType.isNotA(param.declType))) {
              return false;
            }
          }
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
