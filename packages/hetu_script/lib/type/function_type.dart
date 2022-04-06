import 'package:quiver/core.dart';

import '../declaration/type/abstract_type_declaration.dart';
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

<<<<<<< HEAD
  const HTParameterType(
      {this.id,
      required this.declType,
      required this.isOptional,
      required this.isVariadic});
=======
  const HTParameterType(this.declType,
      {required this.isOptional, required this.isVariadic, this.id});

  @override
  String toString() {
    final output = StringBuffer();
    if (isNamed) {
      output.write('$id${HTLexicon.typeIndicator}$declType');
    } else {
      output.write(declType.toString());
    }
    return output.toString();
  }
>>>>>>> fix structural type checking bug, #53
}

class HTFunctionType extends HTType implements HTAbstractTypeDeclaration {
  @override
  final List<HTGenericTypeParameter> genericTypeParameters;

  final List<HTParameterType> parameterTypes;

  final HTType returnType;

  HTFunctionType(
      {this.genericTypeParameters = const [],
      this.parameterTypes = const [],
<<<<<<< HEAD
      required this.returnType});
=======
      this.returnType = HTType.any})
      : super(HTLexicon.kFun);

  @override
  String toString() {
    final output = StringBuffer();
    output.write('${HTLexicon.typeFunction} ');
    if (genericTypeParameters.isNotEmpty) {
      output.write(HTLexicon.typeParameterStart);
      for (var i = 0; i < genericTypeParameters.length; ++i) {
        output.write(genericTypeParameters[i]);
        if (i < genericTypeParameters.length - 1) {
          output.write('${HTLexicon.comma} ');
        }
      }
      output.write(HTLexicon.typeParameterEnd);
    }

    output.write(HTLexicon.groupExprStart);

    var i = 0;
    var optionalStarted = false;
    var namedStarted = false;
    for (final param in parameterTypes) {
      if (param.isVariadic) {
        output.write(HTLexicon.variadicArgs + ' ');
      }
      if (param.isOptional && !optionalStarted) {
        optionalStarted = true;
        output.write(HTLexicon.listStart);
      } else if (param.isNamed && !namedStarted) {
        namedStarted = true;
        output.write(HTLexicon.functionBlockStart);
      }
      output.write(param.toString());
      if (i < parameterTypes.length - 1) {
        output.write('${HTLexicon.comma} ');
      }
      if (optionalStarted) {
        output.write(HTLexicon.listEnd);
      } else if (namedStarted) {
        namedStarted = true;
        output.write(HTLexicon.functionBlockEnd);
      }
      ++i;
    }
    output.write(
        '${HTLexicon.groupExprEnd} ${HTLexicon.functionReturnTypeIndicator} ' +
            returnType.toString());
    return output.toString();
  }
>>>>>>> fix structural type checking bug, #53

  @override
  bool operator ==(Object other) {
    return other is HTFunctionType && hashCode == other.hashCode;
  }

  @override
  int get hashCode {
    final hashList = [];
    hashList.add(id);
    // for (final typeArg in typeArgs) {
    //   hashList.add(typeArg.hashCode);
    // }
    hashList.add(genericTypeParameters.length.hashCode);
    for (final paramType in parameterTypes) {
      hashList.add(paramType);
    }
    hashList.add(returnType);
    final hash = hashObjects(hashList);
    return hash;
  }

  @override
  bool isA(HTType? other) {
    if (other == null) {
      return true;
    } else if (other is HTTypeAny) {
      return true;
    } else if (other is HTFunctionType) {
      if (genericTypeParameters.length != other.genericTypeParameters.length) {
        return false;
      }

      if (returnType.isNotA(other.returnType)) {
        return false;
      }

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
    } else {
      return false;
    }
  }
}
