import 'package:quiver/core.dart';

import '../declaration/function/abstract_parameter.dart';
import '../declaration/type/abstract_type_declaration.dart';
import '../grammar/lexicon.dart';
import 'type.dart';
import 'generic_type_parameter.dart';

class HTFunctionType extends HTType implements HTAbstractTypeDeclaration {
  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  final List<HTAbstractParameter> parameterDeclarations;

  final HTType returnType;

  HTFunctionType(
      {this.genericTypeParameters = const [],
      this.parameterDeclarations = const [],
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
    for (final param in parameterDeclarations) {
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
      if (i < parameterDeclarations.length - 1) {
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
    for (final paramType in parameterDeclarations) {
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
        for (var i = 0; i < parameterDeclarations.length; ++i) {
          final param = parameterDeclarations[i];
          HTAbstractParameter? otherParam;
          if (other.parameterDeclarations.length > i) {
            otherParam = other.parameterDeclarations[i];
          }
          if (!param.isOptional && !param.isVariadic) {
            if (otherParam == null ||
                otherParam.isOptional != param.isOptional ||
                otherParam.isVariadic != param.isVariadic ||
                otherParam.isNamed != param.isNamed ||
                ((otherParam.declType != null) &&
                    (otherParam.declType!.isNotA(param.declType)))) {
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
