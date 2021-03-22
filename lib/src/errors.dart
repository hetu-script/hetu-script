class HTBreak {}

class HTContinue {}

enum HTErrorType {
  parser,
  resolver,
  compiler,
  interpreter,
  import,
  other,
}

abstract class HTError {
  // static const errorAssign = 'Could not assgin to';
  // static const errorUnsupport = 'Unsupport value type';
  static const expected = 'expected, ';
  static const constMustBeStatic = 'Class member constant must be static.';
  static const unexpected = 'Unexpected identifier';
  static const outsideReturn = 'Return statement is not allowed outside of a function.';
  static const privateMember = 'Could not acess private member';
  static const privateDecl = 'Could not acess private declaration';
  static const notInitialized = 'has not initialized';
  static const undefined = 'Undefined identifier';
  static const undefinedOperator = 'Undefined operator';
  // static const errorDeclared = 'is already declared';
  static const defined = 'is already defined';
  // static const errorRange = 'Index out of range, should be less than';
  static const invalidLeftValue = 'Illegal left value.';
  static const notCallable = 'is not callable';
  static const externFuncType =
      'External function expected:\n  dynamic Function(List<dynamic> positionalArgs, Map<String, dynamic> namedArgs)\nGot:\n  ';
  static const externFuncParam = 'External function arguments mismatch.';
  static const undefinedMember = 'isn\'t defined for the class';
  static const conditionMustBeBool = 'Condition expression must evaluate to type [bool]';
  static const missingFuncBody = 'Missing function definition body of';
  static const notList = 'is not a List or Map';
  static const notClass = 'is not a class';
  static const setterArity = 'Setter function\'s arity must be 1';
  // static const errorNullObject = 'is null';
  static const immutable = 'is immutable';
  static const notType = 'is not a type.';

  static const ofType = 'of type';

  static const typeCheck1 = 'Variable';
  static const typeCheck2 = 'can\'t be assigned with type';

  static const argType1 = 'Argument';
  static const argType2 = 'doesn\'t match parameter type';

  static const returnType1 = 'Value of type';
  static const returnType2 = 'can\'t be returned from function';
  static const returnType3 = 'because it has a return type of';

  static const arity1 = 'Number of arguments';
  static const arity2 = 'doesn\'t match parameter requirement of function';

  static const binding = 'Missing binding extension on dart object';

  static const externalVar = 'External variable is not allowed.';

  static const bytesSig = 'Unknown bytecode signature.';

  static const circleInit = 'Variable initializer depend on itself being initialized: ';

  static const initialize = 'Missing variable initializer.';

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

class HTImportError extends HTError {
  final String fileName;

  HTImportError(String message, this.fileName) : super(message, HTErrorType.import);

  @override
  String toString() => 'Hetu error:\n[$type}]\n[File: $fileName]\n$message';
}

class HTInterpreterError extends HTError {
  final int line;
  final int column;
  final String fileName;

  // interpreter会也会处理其他module抛出的异常，因此这里不指定类型
  HTInterpreterError(String message, HTErrorType type, this.fileName, this.line, this.column) : super(message, type);

  @override
  String toString() => 'Hetu error:\n[$type}]\n[File: $fileName]\n[Line: $line, Column: $column]\n$message';
}

class HTErrorExpected extends HTParserError {
  HTErrorExpected(String expected, String met)
      : super('[${expected != '\n' ? expected : '\\n'}] ${HTError.expected} [${met != '\n' ? met : '\\n'}]');
}

class HTErrorConstMustBeStatic extends HTParserError {
  HTErrorConstMustBeStatic(String id) : super(HTError.constMustBeStatic);
}

class HTErrorUnexpected extends HTParserError {
  HTErrorUnexpected(String id) : super('${HTError.unexpected} [${id != '\n' ? id : '\\n'}]');
}

class HTErrorDefinedParser extends HTParserError {
  HTErrorDefinedParser(String id) : super('[$id] ${HTError.defined}');
}

class HTErrorInvalidLeftValueParser extends HTParserError {
  HTErrorInvalidLeftValueParser(String id) : super('${HTError.invalidLeftValue} [$id]');
}

class HTErrorReturn extends HTResolverError {
  HTErrorReturn(String id) : super(HTError.outsideReturn);
}

class HTErrorInvalidLeftValueCompiler extends HTCompilerError {
  HTErrorInvalidLeftValueCompiler() : super(HTError.invalidLeftValue);
}

// class HTErrorAssign extends HTError {
//   HTErrorAssign(String id) : super('${HTError.errorAssign} [$id]');
// }

// class HTErrorUnsupport extends HTError {
//   HTErrorUnsupport(String id) : super('${HTError.errorUnsupport} [$id]');
// }

class HTErrorPrivateMember extends HTError {
  HTErrorPrivateMember(String id) : super('${HTError.privateMember} [$id]', HTErrorType.interpreter);
}

class HTErrorPrivateDecl extends HTError {
  HTErrorPrivateDecl(String id) : super('${HTError.privateDecl} [$id]', HTErrorType.interpreter);
}

class HTErrorInitialized extends HTError {
  HTErrorInitialized(String id) : super('[$id] ${HTError.notInitialized}', HTErrorType.resolver);
}

class HTErrorUndefined extends HTError {
  HTErrorUndefined(String id) : super('${HTError.undefined} [$id]', HTErrorType.interpreter);
}

class HTErrorUndefinedOperator extends HTError {
  HTErrorUndefinedOperator(String id1, String op)
      : super('${HTError.undefinedOperator} [$id1] [$op]', HTErrorType.interpreter);
}

class HTErrorUndefinedBinaryOperator extends HTError {
  HTErrorUndefinedBinaryOperator(String id1, String id2, String op)
      : super('${HTError.undefinedOperator} [$id1] [$op] [$id2]', HTErrorType.interpreter);
}

// class HTErrorDeclared extends HTError {
//   HTErrorDeclared(String id) : super('[$id] ${HTError.errorDeclared}');
// }

class HTErrorSetter extends HTParserError {
  HTErrorSetter() : super(HTError.setterArity);
}

class HTErrorNotClass extends HTParserError {
  HTErrorNotClass(String id) : super('[$id] ${HTError.notClass}');
}

class HTErrorDefinedRuntime extends HTError {
  HTErrorDefinedRuntime(String id) : super('[$id] ${HTError.defined}', HTErrorType.interpreter);
}

// class HTErrorRange extends HTError {
//   HTErrorRange(int length) : super('${HTError.errorRange} [$length]');
// }

class HTErrorCallable extends HTError {
  HTErrorCallable(String id) : super('[$id] ${HTError.notCallable}', HTErrorType.interpreter);
}

class HTErrorExternFunc extends HTError {
  HTErrorExternFunc(String func) : super('${HTError.externFuncType}$func', HTErrorType.interpreter);
}

class HTErrorExternParams extends HTError {
  HTErrorExternParams() : super('${HTError.externFuncParam}', HTErrorType.interpreter);
}

class HTErrorUndefinedMember extends HTError {
  HTErrorUndefinedMember(String id, String type)
      : super('[$id] ${HTError.undefinedMember} [$type]', HTErrorType.interpreter);
}

class HTErrorCondition extends HTError {
  HTErrorCondition() : super(HTError.conditionMustBeBool, HTErrorType.interpreter);
}

// class HTErrorGet extends HTError {
//   HTErrorGet(String id) : super('[$id] ${HTError.errorGet}', HTErrorType.interpreter);
// }

class HTErrorSubGet extends HTError {
  HTErrorSubGet(String id) : super('[$id] ${HTError.notList}', HTErrorType.interpreter);
}

class HTErrorExtends extends HTError {
  HTErrorExtends(String id) : super('[$id] ${HTError.notClass}', HTErrorType.interpreter);
}

// class HTErrorNullObject extends HTError {
//   HTErrorNullObject(String id) : super('[$id] ${HTError.errorNullObject}');
// }

class HTErrorTypeCheck extends HTError {
  HTErrorTypeCheck(String id, String valueType, String declValue)
      : super('${HTError.typeCheck1} [$id] ${HTError.ofType} [$declValue] ${HTError.typeCheck2} [$valueType]',
            HTErrorType.interpreter);
}

class HTErrorImmutable extends HTError {
  HTErrorImmutable(String id) : super('[$id] ${HTError.immutable}', HTErrorType.interpreter);
}

class HTErrorNotType extends HTError {
  HTErrorNotType(String id) : super('[$id] ${HTError.notType}', HTErrorType.interpreter);
}

class HTErrorArgType extends HTError {
  HTErrorArgType(String id, String assignValue, String declValue)
      : super('${HTError.argType1} [$assignValue] ${HTError.ofType} [$assignValue] ${HTError.argType2} [$declValue]',
            HTErrorType.interpreter);
}

class HTErrorReturnType extends HTError {
  HTErrorReturnType(
    String returnedType,
    String funcName,
    String declReturnType,
  ) : super(
            '[$returnedType] ${HTError.returnType2}'
            ' [$funcName] ${HTError.returnType3} [$declReturnType]',
            HTErrorType.interpreter);
}

class HTErrorMissingFuncDef extends HTError {
  HTErrorMissingFuncDef(String funcName) : super('${HTError.missingFuncBody} [$funcName]', HTErrorType.interpreter);
}

class HTErrorArity extends HTError {
  HTErrorArity(String id, int argsCount, int paramsCount)
      : super('${HTError.arity1} [$argsCount] ${HTError.arity2} [$id] [$paramsCount]', HTErrorType.interpreter);
}

class HTErrorBinding extends HTError {
  HTErrorBinding(String id) : super('${HTError.binding} [$id]', HTErrorType.interpreter);
}

class HTErrorExternalVar extends HTError {
  HTErrorExternalVar() : super(HTError.externalVar, HTErrorType.parser);
}

class HTErrorSignature extends HTError {
  HTErrorSignature() : super(HTError.bytesSig, HTErrorType.interpreter);
}

class HTErrorCircleInit extends HTError {
  HTErrorCircleInit(String id) : super('${HTError.circleInit} [$id]', HTErrorType.interpreter);
}

class HTErrorInitialize extends HTError {
  HTErrorInitialize() : super(HTError.initialize, HTErrorType.interpreter);
}
