import '../../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../../type/type.dart';
import '../../type/function_type.dart';
import '../namespace.dart';
import '../element.dart';
import 'typed_parameter_declaration.dart';

class HTTypedFunctionDeclaration extends HTElement {
  final String declId;

  final FunctionCategory category;

  Function? externalFunc;

  final String? externalTypeId;

  /// Holds declarations of all parameters.
  final Map<String, HTTypedParameterDeclaration> parameterDeclarations;

  HTType get returnType => type.returnType;

  final HTFunctionType type;

  final bool isVariadic;

  final int minArity;

  final int maxArity;

  HTTypedFunctionDeclaration(
      String id, String moduleFullName, String libraryName,
      {HTNamespace? closure,
      this.declId = '',
      String? classId,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      this.category = FunctionCategory.normal,
      this.externalFunc,
      this.externalTypeId,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0,
      this.parameterDeclarations = const {},
      HTType? returnType})
      : type = HTFunctionType(moduleFullName, libraryName,
            parameterDeclarations: parameterDeclarations.values.toList(),
            returnType: returnType ?? HTType.ANY),
        super(id, moduleFullName, libraryName,
            closure: closure,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst);

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
  HTTypedFunctionDeclaration clone() =>
      HTTypedFunctionDeclaration(id, moduleFullName, libraryName,
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
          maxArity: maxArity);
}
