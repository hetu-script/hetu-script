import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../../type/type.dart';
import '../../type/function_type.dart';
import 'typed_parameter_declaration.dart';
import 'function_declaration.dart';

class TypedFunctionDeclaration extends FunctionDeclaration {
  /// Holds declarations of all parameters.
  final Map<String, TypedParameterDeclaration> parameterDeclarations;

  HTType get returnType => type.returnType;

  final HTFunctionType type;

  TypedFunctionDeclaration(String id, String moduleFullName, String libraryName,
      {String? declId,
      String? classId,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      FunctionCategory category = FunctionCategory.normal,
      Function? externalFunc,
      String? externalTypeId,
      bool isVariadic = false,
      int minArity = 0,
      int maxArity = 0,
      this.parameterDeclarations = const {},
      HTType? returnType})
      : type = HTFunctionType(moduleFullName, libraryName,
            parameterDeclarations: parameterDeclarations.values.toList(),
            returnType: returnType ?? HTType.ANY),
        super(id, moduleFullName, libraryName,
            declId: declId,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            category: category,
            externalFunc: externalFunc,
            externalTypeId: externalTypeId,
            isConst: isConst,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity);

  /// Print function signature to String with function [id] and parameter [id].
  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.FUNCTION);
    result.write(' $id');
    if (type.typeArgs.isNotEmpty) {
      result.write(HTLexicon.angleLeft);
      for (var i = 0; i < type.typeArgs.length; ++i) {
        result.write(type.typeArgs[i]);
        if (i < type.typeArgs.length - 1) {
          result.write('${HTLexicon.comma} ');
        }
      }
      result.write(HTLexicon.angleRight);
    }
    result.write(HTLexicon.roundLeft);
    var i = 0;
    var optionalStarted = false;
    var namedStarted = false;
    for (final param in parameterDeclarations.values) {
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
      result.write(
          param.id + '${HTLexicon.colon} ' + (param.declType.toString()));
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
    result.write('${HTLexicon.roundRight}${HTLexicon.singleArrow} ' +
        returnType.toString());
    return result.toString();
  }

  @override
  TypedFunctionDeclaration clone() =>
      TypedFunctionDeclaration(id, moduleFullName, libraryName,
          declId: declId,
          classId: classId,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          category: category,
          externalFunc: externalFunc,
          externalTypeId: externalTypeId,
          isVariadic: isVariadic,
          minArity: minArity,
          maxArity: maxArity,
          parameterDeclarations: parameterDeclarations,
          returnType: returnType);
}
