import 'lexicon.dart';

class HTBreak {}

class HTContinue {}

enum HTErrorType {
  parser,
  resolver,
  compiler,
  interpreter,
  other,
}

abstract class HTError {
  static void warn(String message) => print('hetu warn:\n' + message);

  final String message;
  final HTErrorType type;

  @override
  String toString() => message;

  HTError(this.message, this.type);
}

class HTParserError extends HTError {
  HTParserError(String message) : super(message, HTErrorType.parser);
}

class HTResolverError extends HTError {
  HTResolverError(String message) : super(message, HTErrorType.resolver);
}

class HTCompilerError extends HTError {
  HTCompilerError(String message) : super(message, HTErrorType.compiler);
}

class HTInterpreterError extends HTError {
  int line;
  int column;
  String fileName;

  // interpreter会也会处理其他module抛出的异常，因此这里不指定类型
  HTInterpreterError(String message, HTErrorType type, this.fileName, this.line, this.column) : super(message, type);

  @override
  String toString() => 'Hetu error:\n[$type}]\n[File: $fileName]\n[Line: $line, Column: $column]\n$message';
}

// class HTErrorAssign extends HTError {
//   HTErrorAssign(String id) : super('${HTLexicon.errorAssign} "$id"');
// }

// class HTErrorUnsupport extends HTError {
//   HTErrorUnsupport(String id) : super('${HTLexicon.errorUnsupport} "$id"');
// }

class HTErrorExpected extends HTParserError {
  HTErrorExpected(String expected, String met)
      : super('"${expected != '\n' ? expected : '\\n'}" ${HTLexicon.errorExpected} "${met != '\n' ? met : '\\n'}"');
}

class HTErrorConstMustBeStatic extends HTParserError {
  HTErrorConstMustBeStatic(String id) : super(HTLexicon.errorConstMustBeStatic);
}

class HTErrorUnexpected extends HTParserError {
  HTErrorUnexpected(String id) : super('${HTLexicon.errorUnexpected} "${id != '\n' ? id : '\\n'}"');
}

class HTErrorReturn extends HTResolverError {
  HTErrorReturn(String id) : super(HTLexicon.errorReturn);
}

class HTErrorPrivateMember extends HTError {
  HTErrorPrivateMember(String id) : super('${HTLexicon.errorPrivateMember} "$id"', HTErrorType.interpreter);
}

class HTErrorPrivateDecl extends HTError {
  HTErrorPrivateDecl(String id) : super('${HTLexicon.errorPrivateDecl} "$id"', HTErrorType.interpreter);
}

class HTErrorInitialized extends HTError {
  HTErrorInitialized(String id) : super('"$id" ${HTLexicon.errorInitialized}', HTErrorType.resolver);
}

class HTErrorUndefined extends HTError {
  HTErrorUndefined(String id) : super('${HTLexicon.errorUndefined} "$id"', HTErrorType.interpreter);
}

class HTErrorUndefinedOperator extends HTError {
  HTErrorUndefinedOperator(String id1, String op)
      : super('${HTLexicon.errorUndefinedOperator} "$id1" "$op"', HTErrorType.interpreter);
}

class HTErrorUndefinedBinaryOperator extends HTError {
  HTErrorUndefinedBinaryOperator(String id1, String id2, String op)
      : super('${HTLexicon.errorUndefinedOperator} "$id1" "$op" "$id2"', HTErrorType.interpreter);
}

// class HTErrorDeclared extends HTError {
//   HTErrorDeclared(String id) : super('"$id" ${HTLexicon.errorDeclared}');
// }

class HTErrorDefined_Parser extends HTParserError {
  HTErrorDefined_Parser(String id) : super('"$id" ${HTLexicon.errorDefined}');
}

class HTErrorDefined_Runtime extends HTError {
  HTErrorDefined_Runtime(String id) : super('"$id" ${HTLexicon.errorDefined}', HTErrorType.interpreter);
}

// class HTErrorRange extends HTError {
//   HTErrorRange(int length) : super('${HTLexicon.errorRange} "$length"');
// }

class HTErrorInvalidLeftValue extends HTParserError {
  HTErrorInvalidLeftValue(String id) : super('${HTLexicon.errorInvalidLeftValue} "$id"');
}

class HTErrorSetter extends HTParserError {
  HTErrorSetter() : super(HTLexicon.errorSetter);
}

class HTErrorNotClass extends HTParserError {
  HTErrorNotClass(String id) : super('"$id" ${HTLexicon.errorNotClass}');
}

class HTErrorCallable extends HTError {
  HTErrorCallable(String id) : super('"$id" ${HTLexicon.errorCallable}', HTErrorType.interpreter);
}

class HTErrorExternFunc extends HTError {
  HTErrorExternFunc(String func) : super('${HTLexicon.errorExternFunc}$func', HTErrorType.interpreter);
}

class HTErrorExternParams extends HTError {
  HTErrorExternParams() : super('${HTLexicon.errorExternFuncParams}', HTErrorType.interpreter);
}

class HTErrorUndefinedMember extends HTError {
  HTErrorUndefinedMember(String id, String type)
      : super('"$id" ${HTLexicon.errorUndefinedMember} "$type"', HTErrorType.interpreter);
}

class HTErrorCondition extends HTError {
  HTErrorCondition() : super(HTLexicon.errorCondition, HTErrorType.interpreter);
}

// class HTErrorGet extends HTError {
//   HTErrorGet(String id) : super('"$id" ${HTLexicon.errorGet}', HTErrorType.interpreter);
// }

class HTErrorSubGet extends HTError {
  HTErrorSubGet(String id) : super('"$id" ${HTLexicon.errorSubGet}', HTErrorType.interpreter);
}

class HTErrorExtends extends HTError {
  HTErrorExtends(String id) : super('"$id" ${HTLexicon.errorExtends}', HTErrorType.interpreter);
}

// class HTErrorNullObject extends HTError {
//   HTErrorNullObject(String id) : super('"$id" ${HTLexicon.errorNullObject}');
// }

class HTErrorTypeCheck extends HTError {
  HTErrorTypeCheck(String id, String valueType, String declValue)
      : super(
            '${HTLexicon.errorTypeCheck1} "$id" ${HTLexicon.errorOfType} "$declValue" ${HTLexicon.errorTypeCheck2} "$valueType"',
            HTErrorType.interpreter);
}

class HTErrorImmutable extends HTError {
  HTErrorImmutable(String id) : super('"$id" ${HTLexicon.errorImmutable}', HTErrorType.interpreter);
}

class HTErrorNotType extends HTError {
  HTErrorNotType(String id) : super('"$id" ${HTLexicon.errorNotType}', HTErrorType.interpreter);
}

class HTErrorArgType extends HTError {
  HTErrorArgType(String id, String assignValue, String declValue)
      : super(
            '${HTLexicon.errorArgType1} "$assignValue" ${HTLexicon.errorOfType} "$assignValue" ${HTLexicon.errorArgType2} "$declValue"',
            HTErrorType.interpreter);
}

class HTErrorReturnType extends HTError {
  HTErrorReturnType(
    String returnedType,
    String funcName,
    String declReturnType,
  ) : super(
            '"$returnedType" ${HTLexicon.errorReturnType2}'
            ' "$funcName" ${HTLexicon.errorReturnType3} "$declReturnType"',
            HTErrorType.interpreter);
}

class HTErrorMissingFuncDef extends HTError {
  HTErrorMissingFuncDef(String funcName) : super('${HTLexicon.errorMissingFuncDef} $funcName', HTErrorType.interpreter);
}

class HTErrorArity extends HTError {
  HTErrorArity(String id, int argsCount, int paramsCount)
      : super('${HTLexicon.errorArity1} [$argsCount] ${HTLexicon.errorArity2} [$id] [$paramsCount]',
            HTErrorType.interpreter);
}

class HTErrorBinding extends HTError {
  HTErrorBinding(String id) : super('${HTLexicon.errorBinding} [$id]', HTErrorType.interpreter);
}

class HTErrorSignature extends HTError {
  HTErrorSignature() : super(HTLexicon.errorSignature, HTErrorType.interpreter);
}

class HTErrorInt64Table extends HTError {
  HTErrorInt64Table() : super(HTLexicon.errorInt64Table, HTErrorType.interpreter);
}

class HTErrorFloat64Table extends HTError {
  HTErrorFloat64Table() : super(HTLexicon.errorFloat64Table, HTErrorType.interpreter);
}

class HTErrorStringTable extends HTError {
  HTErrorStringTable() : super(HTLexicon.errorStringTable, HTErrorType.interpreter);
}
