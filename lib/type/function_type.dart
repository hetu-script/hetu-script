import 'package:quiver/core.dart';

import '../element/function/typed_parameter_declaration.dart';
import '../../grammar/lexicon.dart';
import 'type.dart';
// import '../ast/ast.dart' show ParamDeclExpr;

// class HTParameterType extends HTType implements ParameterDeclaration {
//   @override
//   HTType get declType => this;

//   @override
//   final String id;

//   @override
//   final bool isOptional;

//   @override
//   final bool isNamed;

//   @override
//   final bool isVariadic;

//   const HTParameterType(String typeid,
//       {this.id = '',
//       List<HTType> typeArgs = const [],
//       bool isNullable = false,
//       this.isOptional = false,
//       this.isNamed = false,
//       this.isVariadic = false})
//       : super(typeid, typeArgs: typeArgs, isNullable: isNullable);

//   HTParameterType.fromType(String paramId,
//       {HTType? paramType,
//       bool isOptional = false,
//       bool isNamed = false,
//       bool isVariadic = false})
//       : this(paramType?.id ?? HTLexicon.ANY,
//             id: paramId,
//             typeArgs: paramType?.typeArgs ?? const [],
//             isNullable: paramType?.isNullable ?? false,
//             isOptional: isOptional,
//             isNamed: isNamed,
//             isVariadic: isVariadic);

//   HTParameterType.fromAst(ParamDeclExpr ast)
//       : this.fromType(ast.id,
//             paramType: HTType.fromAst(ast.declType),
//             isOptional: ast.isOptional,
//             isNamed: ast.isNamed,
//             isVariadic: ast.isVariadic);

//   @override
//   String toString() {
//     var typeString = StringBuffer();
//     if (isNamed) {
//       typeString.write('$id: ');
//     }
//     typeString.write(super.toString());
//     return typeString.toString();
//   }

//   @override
//   int get hashCode {
//     final hashList = <int>[];
//     hashList.add(super.hashCode);
//     hashList.add(isOptional.hashCode);
//     hashList.add(isNamed.hashCode);
//     hashList.add(isVariadic.hashCode);
//     final hash = hashObjects(hashList);
//     return hash;
//   }

//   @override
//   bool isA(dynamic other) {
//     if (other == HTType.ANY) {
//       return true;
//     } else if (other.id == HTLexicon.ANY) {
//       if ((isOptional == other.isOptional) ||
//           (isNamed == other.isNamed) ||
//           (isVariadic == other.isVariadic)) {
//         return true;
//       } else {
//         return false;
//       }
//     } else if (other is HTParameterType) {
//       if (isNamed && (id != other.id)) {
//         return false;
//       } else if ((isOptional != other.isOptional) ||
//           (isNamed != other.isNamed) ||
//           (isVariadic != other.isVariadic)) {
//         return false;
//       }
//       // ignore: unnecessary_cast
//       else if (!super.isA(other)) {
//         return false;
//       } else {
//         return true;
//       }
//     } else {
//       return false;
//     }
//   }
// }

class HTFunctionType extends HTType {
  @override
  bool get isResolved => true;

  final Iterable<HTType> genericTypeParameters;
  final List<HTTypedParameterDeclaration> parameterDeclarations;
  final HTType returnType;

  HTFunctionType(String moduleFullName, String libraryName,
      {this.genericTypeParameters = const [],
      this.parameterDeclarations = const [],
      this.returnType = HTType.ANY})
      : super(HTLexicon.function, moduleFullName, libraryName);

  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.function);
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
          HTTypedParameterDeclaration? otherParam;
          if (other.parameterDeclarations.length > i) {
            otherParam = other.parameterDeclarations[i];
          }
          if (!param.isOptional && !param.isVariadic) {
            if (otherParam == null ||
                otherParam.isOptional != param.isOptional ||
                otherParam.isVariadic != param.isVariadic ||
                otherParam.isNamed != param.isNamed ||
                otherParam.declType.isNotA(param.declType)) {
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
