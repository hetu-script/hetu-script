import 'lexicon.dart';

class HT_Break {}

class HT_Continue {}

enum HT_ErrorType {
  parser,
  resolver,
  compiler,
  interpreter,
  unknown,
}

abstract class HT_Error {
  static void warn(String message) => print('hetu warn:\n' + message);

  final String message;
  final HT_ErrorType type;

  HT_Error(this.message, this.type);
}

class HT_ParserError extends HT_Error {
  HT_ParserError(String message) : super(message, HT_ErrorType.parser);
}

class HT_ResolverError extends HT_Error {
  HT_ResolverError(String message) : super(message, HT_ErrorType.resolver);
}

class HT_CompilerError extends HT_Error {
  HT_CompilerError(String message) : super(message, HT_ErrorType.compiler);
}

class HT_InterpreterError extends HT_Error {
  int line;
  int column;
  String fileName;

  // interpreter会也会处理其他module抛出的异常，因此这里不指定类型
  HT_InterpreterError(String message, HT_ErrorType type, this.fileName, this.line, this.column) : super(message, type);

  @override
  String toString() {
    return '''
    hetu error:
    [source: $type]
    [file: $fileName]
    [line: $line, column: $column]
    $message
    ''';
  }
}

// class HT_Error_Assign extends HT_Error {
//   HT_Error_Assign(String id) : super('${HT_Lexicon.errorAssign} "$id"');
// }

// class HT_Error_Unsupport extends HT_Error {
//   HT_Error_Unsupport(String id) : super('${HT_Lexicon.errorUnsupport} "$id"');
// }

class HT_Error_Expected extends HT_ParserError {
  HT_Error_Expected(String expected, String met)
      : super('"${expected != '\n' ? expected : '\\n'}" ${HT_Lexicon.errorExpected} "${met != '\n' ? met : '\\n'}"');
}

class HT_Error_ConstMustBeStatic extends HT_ParserError {
  HT_Error_ConstMustBeStatic(String id) : super(HT_Lexicon.errorConstMustBeStatic);
}

class HT_Error_Unexpected extends HT_ParserError {
  HT_Error_Unexpected(String id) : super('${HT_Lexicon.errorUnexpected} "${id != '\n' ? id : '\\n'}"');
}

class HT_Error_Return extends HT_ResolverError {
  HT_Error_Return(String id) : super(HT_Lexicon.errorReturn);
}

class HT_Error_PrivateMember extends HT_Error {
  HT_Error_PrivateMember(String id) : super('${HT_Lexicon.errorPrivateMember} "$id"', HT_ErrorType.interpreter);
}

class HT_Error_PrivateDecl extends HT_Error {
  HT_Error_PrivateDecl(String id) : super('${HT_Lexicon.errorPrivateDecl} "$id"', HT_ErrorType.interpreter);
}

class HT_Error_Initialized extends HT_Error {
  HT_Error_Initialized(String id) : super('"$id" ${HT_Lexicon.errorInitialized}', HT_ErrorType.resolver);
}

class HT_Error_Undefined extends HT_Error {
  HT_Error_Undefined(String id) : super('${HT_Lexicon.errorUndefined} "$id"', HT_ErrorType.interpreter);
}

class HT_Error_UndefinedOperator extends HT_Error {
  HT_Error_UndefinedOperator(String id1, String op)
      : super('${HT_Lexicon.errorUndefinedOperator} "$id1" "$op"', HT_ErrorType.interpreter);
}

class HT_Error_UndefinedBinaryOperator extends HT_Error {
  HT_Error_UndefinedBinaryOperator(String id1, String id2, String op)
      : super('${HT_Lexicon.errorUndefinedOperator} "$id1" "$op" "$id2"', HT_ErrorType.interpreter);
}

// class HT_Error_Declared extends HT_Error {
//   HT_Error_Declared(String id) : super('"$id" ${HT_Lexicon.errorDeclared}');
// }

class HT_Error_Defined_Parser extends HT_ParserError {
  HT_Error_Defined_Parser(String id) : super('"$id" ${HT_Lexicon.errorDefined}');
}

class HT_Error_Defined_Runtime extends HT_Error {
  HT_Error_Defined_Runtime(String id) : super('"$id" ${HT_Lexicon.errorDefined}', HT_ErrorType.interpreter);
}

// class HT_Error_Range extends HT_Error {
//   HT_Error_Range(int length) : super('${HT_Lexicon.errorRange} "$length"');
// }

class HT_Error_InvalidLeftValue extends HT_ParserError {
  HT_Error_InvalidLeftValue(String id) : super('${HT_Lexicon.errorInvalidLeftValue} "$id"');
}

class HT_Error_Setter extends HT_ParserError {
  HT_Error_Setter() : super(HT_Lexicon.errorSetter);
}

class HT_Error_NotClass extends HT_ParserError {
  HT_Error_NotClass(String id) : super('"$id" ${HT_Lexicon.errorNotClass}');
}

class HT_Error_Callable extends HT_Error {
  HT_Error_Callable(String id) : super('"$id" ${HT_Lexicon.errorCallable}', HT_ErrorType.interpreter);
}

class HT_Error_UndefinedMember extends HT_Error {
  HT_Error_UndefinedMember(String id, String type)
      : super('"$id" ${HT_Lexicon.errorUndefinedMember} "$type"', HT_ErrorType.interpreter);
}

class HT_Error_Condition extends HT_Error {
  HT_Error_Condition() : super(HT_Lexicon.errorCondition, HT_ErrorType.interpreter);
}

class HT_Error_Get extends HT_Error {
  HT_Error_Get(String id) : super('"$id" ${HT_Lexicon.errorGet}', HT_ErrorType.interpreter);
}

class HT_Error_SubGet extends HT_Error {
  HT_Error_SubGet(String id) : super('"$id" ${HT_Lexicon.errorSubGet}', HT_ErrorType.interpreter);
}

class HT_Error_Extends extends HT_Error {
  HT_Error_Extends(String id) : super('"$id" ${HT_Lexicon.errorExtends}', HT_ErrorType.interpreter);
}

// class HT_Error_NullObject extends HT_Error {
//   HT_Error_NullObject(String id) : super('"$id" ${HT_Lexicon.errorNullObject}');
// }

class HT_Error_Type extends HT_Error {
  HT_Error_Type(String id, String valueType, String declValue)
      : super(
            '${HT_Lexicon.errorType1} "$id" ${HT_Lexicon.errorOfType} "$declValue" ${HT_Lexicon.errorType2} "$valueType"',
            HT_ErrorType.interpreter);
}

class HT_Error_Immutable extends HT_Error {
  HT_Error_Immutable(String id) : super('"$id" ${HT_Lexicon.errorImmutable}', HT_ErrorType.interpreter);
}

class HT_Error_NotType extends HT_Error {
  HT_Error_NotType(String id) : super('"$id" ${HT_Lexicon.errorNotType}', HT_ErrorType.interpreter);
}

class HT_Error_ArgType extends HT_Error {
  HT_Error_ArgType(String id, String assignValue, String declValue)
      : super(
            '${HT_Lexicon.errorArgType1} "$assignValue" ${HT_Lexicon.errorOfType} "$assignValue" ${HT_Lexicon.errorArgType2} "$declValue"',
            HT_ErrorType.interpreter);
}

class HT_Error_ReturnType extends HT_Error {
  HT_Error_ReturnType(
    String returnedType,
    String funcName,
    String declReturnType,
  ) : super(
            '"$returnedType" ${HT_Lexicon.errorReturnType2}'
            ' "$funcName" ${HT_Lexicon.errorReturnType3} "$declReturnType"',
            HT_ErrorType.interpreter);
}

class HT_Error_MissingFuncDef extends HT_Error {
  HT_Error_MissingFuncDef(String funcName)
      : super('${HT_Lexicon.errorMissingFuncDef} $funcName', HT_ErrorType.interpreter);
}

class HT_Error_Arity extends HT_Error {
  HT_Error_Arity(String id, int argsCount, int paramsCount)
      : super('${HT_Lexicon.errorArity1} [$argsCount] ${HT_Lexicon.errorArity2} [$id] [$paramsCount]',
            HT_ErrorType.interpreter);
}

class HT_Error_Signature extends HT_Error {
  HT_Error_Signature() : super(HT_Lexicon.errorSignature, HT_ErrorType.interpreter);
}

class HT_Error_Int64Table extends HT_Error {
  HT_Error_Int64Table() : super(HT_Lexicon.errorInt64Table, HT_ErrorType.interpreter);
}

class HT_Error_Float64Table extends HT_Error {
  HT_Error_Float64Table() : super(HT_Lexicon.errorFloat64Table, HT_ErrorType.interpreter);
}

class HT_Error_StringTable extends HT_Error {
  HT_Error_StringTable() : super(HT_Lexicon.errorStringTable, HT_ErrorType.interpreter);
}
