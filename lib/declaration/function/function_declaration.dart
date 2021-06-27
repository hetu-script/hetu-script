import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../../type/type.dart';
import '../../type/function_type.dart';
import '../../source/source.dart';
import '../namespace.dart';
import '../variable/variable_declaration.dart';
import 'abstract_parameter.dart';

class HTFunctionDeclaration extends HTVariableDeclaration {
  final String internalName;

  final FunctionCategory category;

  final String? externalTypeId;

  /// Holds declarations of all parameters.
  final Map<String, AbstractParameter> paramDecls;

  HTType get returnType => declType.returnType;

  @override
  final HTFunctionType declType;

  final bool isVariadic;

  final int minArity;

  final int maxArity;

  HTFunctionDeclaration(this.internalName,
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      this.category = FunctionCategory.normal,
      this.externalTypeId,
      this.isVariadic = false,
      this.minArity = 0,
      this.maxArity = 0,
      this.paramDecls = const {},
      HTType? returnType})
      : declType = HTFunctionType(
            parameterDeclarations: paramDecls.values.toList(),
            returnType: returnType ?? HTType.ANY),
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst);

  /// Print function signature to String with function [id] and parameter [id].
  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.FUNCTION);
    result.write(' $internalName');
    if (declType.typeArgs.isNotEmpty) {
      result.write(HTLexicon.angleLeft);
      for (var i = 0; i < declType.typeArgs.length; ++i) {
        result.write(declType.typeArgs[i]);
        if (i < declType.typeArgs.length - 1) {
          result.write('${HTLexicon.comma} ');
        }
      }
      result.write(HTLexicon.angleRight);
    }
    result.write(HTLexicon.roundLeft);
    var i = 0;
    var optionalStarted = false;
    var namedStarted = false;
    for (final param in paramDecls.values) {
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
      result.write(param.id);
      if (param.declType != null) {
        result.write('${HTLexicon.colon} ${param.declType}');
      }
      if (i < paramDecls.length - 1) {
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
  HTFunctionDeclaration clone() => HTFunctionDeclaration(internalName,
      id: id,
      classId: classId,
      closure: closure,
      source: source,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      category: category,
      externalTypeId: externalTypeId,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
      paramDecls: paramDecls,
      returnType: returnType);
}
