/// Error type tells who throws this erro
enum HTErrorType {
  parser,
  resolver,
  compiler,
  interpreter,
  import,
  other,
}

/// Base error class, contains static error messages.
abstract class HTError {
  static const _expected = 'expected, ';
  static const _constMustBeStatic = 'Class member constant must be static.';
  static const _unexpected = 'Unexpected identifier';
  static const _outsideReturn = 'Return statement outside of a function.';
  static const _privateMember = 'Could not acess private member';
  static const _privateDecl = 'Could not acess private declaration';
  static const _notInitialized = 'has not initialized';
  static const _undefined = 'Undefined identifier';
  static const _undefinedExtern = 'Undefined external identifier';
  static const _unknownType = 'Unkown type of object:';
  static const _undefinedOperator = 'Undefined operator';
  static const _defined = 'is already defined';
  // static const errorRange = 'Index out of range, should be less than';
  static const _invalidLeftValue = 'Illegal left value.';
  static const _notCallable = 'is not callable';
  static const _undefinedMember = 'isn\'t defined for the class';
  static const _conditionMustBeBool =
      'Condition expression must evaluate to type [bool]';
  static const _missingFuncBody = 'Missing function definition body of';
  static const _notList = 'is not a List or Map';
  static const _notClass = 'is not a class';
  static const _setterArity = 'Setter function\'s arity must be 1';
  static const _errorNullObject = 'Calling method on null object:';
  static const _immutable = 'is immutable';
  static const _notType = 'is not a type.';
  static const _ofType = 'of type';
  static const _typeCheck1 = 'Variable';
  static const _typeCheck2 = 'can\'t be assigned with type';
  static const _argType1 = 'Argument';
  static const _argType2 = 'doesn\'t match parameter type';
  static const _returnType1 = 'can\'t be returned from function';
  static const _returnType2 = 'because it has a return type of';
  static const _arity1 = 'Number of arguments';
  static const _arity2 = 'doesn\'t match parameter requirement of function';
  static const _binding = 'Missing binding extension on dart object';
  static const _externalVar = 'External variable is not allowed.';
  static const _bytesSig = 'Unknown bytecode signature.';
  static const _circleInit =
      'Variable initializer depend on itself being initialized:';
  static const _initialize = 'Missing variable initializer.';
  static const _namedArg = 'Undefined argument name:';
  static const _iterable = 'is not Iterable.';
  static const _unkownValueType = 'Unkown OpCode value type:';
  static const _classOnInstance = 'Don\'t define class on instance!';
  static const _emptyString = 'The script is empty.';
  static const _typecast = '\'s type cannot be cast into';

  /// Print a warning message to standard output, will not throw.
  static void warn(String message) => print('hetu warn:\n' + message);

  /// Error message.
  final String message;

  /// Error type.
  final HTErrorType type;

  @override
  String toString() => message;

  /// Default constructor of [HTError].
  HTError(this.message, this.type);
}

/// [HTError] throws by parser (compiler).
class HTParserError extends HTError {
  HTParserError(String message) : super(message, HTErrorType.parser);
}

/// [HTError] throws by resolver.
class HTResolverError extends HTError {
  HTResolverError(String message) : super(message, HTErrorType.resolver);
}

/// [HTError] throws by module handler.
class HTImportError extends HTError {
  final String fileName;

  HTImportError(String message, this.fileName)
      : super(message, HTErrorType.import);

  @override
  String toString() => 'Hetu error:\n[$type}]\n[File: $fileName]\n$message';
}

/// [HTError] throws by interpreter.
class HTInterpreterError extends HTError {
  final int line;
  final int column;
  final String fileName;

  HTInterpreterError(
      String message, HTErrorType type, this.fileName, this.line, this.column)
      : super(message, type);

  @override
  String toString() =>
      'Hetu error:\n[$type}]\n[File: $fileName]\n[Line: $line, Column: $column]\n$message';
}

/// Expected a token while met another.
class HTErrorExpected extends HTParserError {
  HTErrorExpected(String expected, String met)
      : super(
            '[${expected != '\n' ? expected : '\\n'}] ${HTError._expected} [${met != '\n' ? met : '\\n'}]');
}

/// Const variable in a class must be static
class HTErrorConstMustBeStatic extends HTParserError {
  HTErrorConstMustBeStatic(String id) : super(HTError._constMustBeStatic);
}

/// A unexpected token appeared.
class HTErrorUnexpected extends HTParserError {
  HTErrorUnexpected(String id)
      : super('${HTError._unexpected} [${id != '\n' ? id : '\\n'}]');
}

/// A same name declaration is already existed.
class HTErrorDefinedParser extends HTParserError {
  HTErrorDefinedParser(String id) : super('[$id] ${HTError._defined}');
}

/// Illegal value appeared on left of assignment.
class HTErrorIllegalLeftValueParser extends HTParserError {
  HTErrorIllegalLeftValueParser() : super(HTError._invalidLeftValue);
}

/// Return appeared outside of a function.
class HTErrorReturn extends HTResolverError {
  HTErrorReturn() : super(HTError._outsideReturn);
}

/// Access private member.
class HTErrorPrivateMember extends HTError {
  HTErrorPrivateMember(String id)
      : super('${HTError._privateMember} [$id]', HTErrorType.interpreter);
}

/// Access private declaration.
class HTErrorPrivateDecl extends HTError {
  HTErrorPrivateDecl(String id)
      : super('${HTError._privateDecl} [$id]', HTErrorType.interpreter);
}

/// Use a variable before its initialization.
class HTErrorInitialized extends HTError {
  HTErrorInitialized(String id)
      : super('[$id] ${HTError._notInitialized}', HTErrorType.resolver);
}

/// Use a variable without declaration.
class HTErrorUndefined extends HTError {
  HTErrorUndefined(String id)
      : super('${HTError._undefined} [$id]', HTErrorType.interpreter);
}

/// Use a external variable without its binding.
class HTErrorUndefinedExtern extends HTError {
  HTErrorUndefinedExtern(String id)
      : super('${HTError._undefinedExtern} [$id]', HTErrorType.interpreter);
}

/// Try to operate unkown type object.
class HTErrorUnknownType extends HTError {
  HTErrorUnknownType(String id)
      : super('${HTError._unknownType} [$id]', HTErrorType.interpreter);
}

/// Unknown operator.
class HTErrorUndefinedOperator extends HTError {
  HTErrorUndefinedOperator(String id1, String op)
      : super('${HTError._undefinedOperator} [$id1] [$op]',
            HTErrorType.interpreter);
}

/// Illegal setter declaration.
class HTErrorSetter extends HTParserError {
  HTErrorSetter() : super(HTError._setterArity);
}

/// Symbol is not a class name.
class HTErrorNotClass extends HTParserError {
  HTErrorNotClass(String id) : super('[$id] ${HTError._notClass}');
}

/// A same name declaration is already existed.
class HTErrorDefinedRuntime extends HTError {
  HTErrorDefinedRuntime(String id)
      : super('[$id] ${HTError._defined}', HTErrorType.interpreter);
}

// class HTErrorRange extends HTError {
//   HTErrorRange(int length) : super('${HTError.errorRange} [$length]');
// }

/// Object is not callable.
class HTErrorCallable extends HTError {
  HTErrorCallable(String id)
      : super('[$id] ${HTError._notCallable}', HTErrorType.interpreter);
}

/// Undefined member of a class/enum.
class HTErrorUndefinedMember extends HTError {
  HTErrorUndefinedMember(String id, String type)
      : super('[$id] ${HTError._undefinedMember} [$type]',
            HTErrorType.interpreter);
}

/// if/while condition expression must be boolean type.
class HTErrorCondition extends HTError {
  HTErrorCondition()
      : super(HTError._conditionMustBeBool, HTErrorType.interpreter);
}

/// Try to use sub get operator on a non-list object.
class HTErrorSubGet extends HTError {
  HTErrorSubGet(String id)
      : super('[$id] ${HTError._notList}', HTErrorType.interpreter);
}

/// extends Type must be a class.
class HTErrorExtends extends HTError {
  HTErrorExtends(String id)
      : super('[$id] ${HTError._notClass}', HTErrorType.interpreter);
}

/// Calling method on null object.
class HTErrorNullObject extends HTError {
  HTErrorNullObject(String id)
      : super('${HTError._errorNullObject} [$id]', HTErrorType.interpreter);
}

/// Type check failed.
class HTErrorTypeCheck extends HTError {
  HTErrorTypeCheck(String id, String valueType, String declValue)
      : super(
            '${HTError._typeCheck1} [$id] ${HTError._ofType} [$declValue] ${HTError._typeCheck2} [$valueType]',
            HTErrorType.interpreter);
}

/// Try to assign a immutable variable.
class HTErrorImmutable extends HTError {
  HTErrorImmutable(String id)
      : super('[$id] ${HTError._immutable}', HTErrorType.interpreter);
}

/// Symbol is not a type.
class HTErrorNotType extends HTError {
  HTErrorNotType(String id)
      : super('[$id] ${HTError._notType}', HTErrorType.interpreter);
}

/// Arguments type check failed.
class HTErrorArgType extends HTError {
  HTErrorArgType(String id, String assignValue, String declValue)
      : super(
            '${HTError._argType1} [$assignValue] ${HTError._ofType} [$assignValue] ${HTError._argType2} [$declValue]',
            HTErrorType.interpreter);
}

/// Return value type check failed.
class HTErrorReturnType extends HTError {
  HTErrorReturnType(
    String returnedType,
    String funcName,
    String declReturnType,
  ) : super(
            '[$returnedType] ${HTError._returnType1}'
            ' [$funcName] ${HTError._returnType2} [$declReturnType]',
            HTErrorType.interpreter);
}

/// Try to call a function without definition.
class HTErrorMissingFuncDef extends HTError {
  HTErrorMissingFuncDef(String funcName)
      : super(
            '${HTError._missingFuncBody} [$funcName]', HTErrorType.interpreter);
}

/// Function arity check failed.
class HTErrorArity extends HTError {
  HTErrorArity(String id, int argsCount, int paramsCount)
      : super(
            '${HTError._arity1} [$argsCount] ${HTError._arity2} [$id] [$paramsCount]',
            HTErrorType.interpreter);
}

/// Missing binding extension on dart object.
class HTErrorBinding extends HTError {
  HTErrorBinding(String id)
      : super('${HTError._binding} [$id]', HTErrorType.interpreter);
}

/// Can not declare a external variable in global namespace.
class HTErrorExternVar extends HTError {
  HTErrorExternVar() : super(HTError._externalVar, HTErrorType.parser);
}

/// Bytecode signature check failed.
class HTErrorSignature extends HTError {
  HTErrorSignature() : super(HTError._bytesSig, HTErrorType.interpreter);
}

/// Variable's initialization relies on itself.
class HTErrorCircleInit extends HTError {
  HTErrorCircleInit(String id)
      : super('${HTError._circleInit} [$id]', HTErrorType.interpreter);
}

/// Missing variable initializer.
class HTErrorInitialize extends HTError {
  HTErrorInitialize() : super(HTError._initialize, HTErrorType.interpreter);
}

/// Named arguments does not exist.
class HTErrorNamedArg extends HTError {
  HTErrorNamedArg(String id)
      : super('${HTError._namedArg} [$id]', HTErrorType.interpreter);
}

/// Object is not iterable.
class HTErrorIterable extends HTError {
  HTErrorIterable(String id)
      : super('[$id] ${HTError._iterable}', HTErrorType.interpreter);
}

/// Object is not iterable.
class HTErrorUnkownValueType extends HTError {
  HTErrorUnkownValueType(int type)
      : super('${HTError._unkownValueType} [$type]', HTErrorType.interpreter);
}

/// Unkown opcode value type.
class HTErrorClassOnInstance extends HTError {
  HTErrorClassOnInstance()
      : super(HTError._classOnInstance, HTErrorType.interpreter);
}

/// Illegal empty string.
class HTErrorEmpty extends HTError {
  HTErrorEmpty([String fileName = ''])
      : super('${HTError._emptyString} [$fileName]', HTErrorType.interpreter);
}

/// Illegal type cast.
class HTErrorTypeCast extends HTError {
  HTErrorTypeCast(String varName, String typeid)
      : super('[$varName] ${HTError._typecast} [$typeid]',
            HTErrorType.interpreter);
}
