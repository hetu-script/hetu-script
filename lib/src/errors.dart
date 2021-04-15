/// Error type tells who throws this erro
enum HTErrorType {
  parser,
  interpreter,
  import,
}

class HTErrorCode {
  static const dartError = 0;

  static const import = 0;
  static const expected = 0;
  static const constMustBeStatic = 0;
  static const constMustInit = 0;
  static const unexpected = 0;
  static const outsideReturn = 0;
  static const privateMember = 0;
  static const privateDecl = 0;
  static const notInitialized = 0;
  static const undefined = 0;
  static const undefinedExtern = 0;
  static const unknownType = 0;
  static const undefinedOperator = 0;
  static const defined = 0;
  static const invalidLeftValue = 0;
  static const notCallable = 0;
  static const undefinedMember = 0;
  static const condition = 0;
  static const missingFuncBody = 0;
  static const notList = 0;
  static const notClass = 0;
  static const notMember = 0;
  static const ctorReturn = 0;
  static const abstracted = 0;
  static const abstractCtor = 0;
  static const setterArity = 0;
  static const externMember = 0;
  static const emptyTypeArgs = 0;
  static const unknownOpCode = 0;
  static const nullObject = 0;
  static const nullable = 0;
  static const immutable = 0;
  static const notType = 0;
  static const ofType = 0;
  static const typeCheck = 0;
  static const argType = 0;
  static const returnType = 0;
  static const arity = 0;
  static const binding = 0;
  static const externalVar = 0;
  static const bytesSig = 0;
  static const circleInit = 0;
  static const initialize = 0;
  static const namedArg = 0;
  static const iterable = 0;
  static const unkownValueType = 0;
  static const classOnInstance = 0;
  static const emptyString = 0;
  static const typeCast = 0;
  static const castee = 0;
  static const clone = 0;
  static const notSuper = 0;
}

/// Base error class, contains static error messages.
class HTError {
  static const _import = 'Module import handler error.';
  static const _expected = 'expected, ';
  static const _constMustBeStatic = 'Constant class member must be static.';
  static const _constMustInit = 'Constant must be initialized.';
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
  static const _undefinedMember = 'isn\'t defined for the class.';
  static const _condition = 'Condition expression must evaluate to type [bool]';
  static const _missingFuncBody = 'Missing function definition body of';
  static const _notList = 'is not a List or Map.';
  static const _notClass = 'is not a class.';
  static const _notMember = 'is not a instance member declaration.';
  static const _ctorReturn = 'Constructor cannot have a return type.';
  static const _abstracted = 'Cannot create instance from abstract class.';
  static const _abstractCtor = 'Cannot create contructor for abstract class.';
  static const _setterArity = 'Setter function\'s arity must be 1.';
  static const _externMember =
      'Non-external class cannot have non-static external members.';
  static const _emptyTypeArgs = 'Empty type arguments.';

  static const _unknownOpCode = 'Unknown opcode:';
  static const _nullObject = 'Calling method on null object:';
  static const _nullable = 'is not nullable.';
  static const _immutable = 'is immutable.';
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
  static const _typeCast = '\'s type cannot be cast into';
  static const _castee = 'Illegal cast target';
  static const _clone = 'Illegal clone on';
  static const _notSuper = 'is not a super class of';

  /// Print a warning message to standard output, will not throw.
  static void warn(String message) => print('hetu warn:\n' + message);

  /// Error message.
  String? message;

  int? code;

  /// Error type.
  HTErrorType? type;

  /// moduleUniqueKey when error occured.
  String? moduleUniqueKey;

  /// Line number when error occured.
  int? line;

  /// Column number when error occured.
  int? column;

  @override
  String toString() =>
      'Hetu error:\n[$type}]\n[File: $moduleUniqueKey]\n[Line: $line, Column: $column]\n$message';

  /// [HTError] can not be created by default constructor.
  HTError(this.message, this.code, this.type,
      [this.moduleUniqueKey, this.line, this.column]);

  /// Error: Module import error
  HTError.import(String id) {
    message = _import;
    type = HTErrorType.import;
    code = HTErrorCode.import;
  }

  /// Error: Expected a token while met another.
  HTError.expected(String expected, String met) {
    message =
        '[${expected != '\n' ? expected : '\\n'}] $_expected [${met != '\n' ? met : '\\n'}]';
    type = HTErrorType.parser;
    code = HTErrorCode.expected;
  }

  /// Error: Const variable in a class must be static.
  HTError.constMustBeStatic(String id) {
    message = _constMustBeStatic;
    type = HTErrorType.parser;
    code = HTErrorCode.constMustBeStatic;
  }

  /// Error: Const variable must be initialized.
  HTError.constMustInit(String id) {
    message = _constMustInit;
    type = HTErrorType.parser;
    code = HTErrorCode.constMustInit;
  }

  /// Error: A unexpected token appeared.
  HTError.unexpected(String id) {
    message = '${HTError._unexpected} [${id != '\n' ? id : '\\n'}]';
    type = HTErrorType.parser;
    code = HTErrorCode.unexpected;
  }

  /// Error: A same name declaration is already existed.
  HTError.definedParser(String id) {
    message = '[$id] ${HTError._defined}';
    type = HTErrorType.parser;
    code = HTErrorCode.defined;
  }

  /// Error: Illegal value appeared on left of assignment.
  HTError.invalidLeftValue() {
    message = HTError._invalidLeftValue;
    type = HTErrorType.parser;
    code = HTErrorCode.invalidLeftValue;
  }

  /// Error: Return appeared outside of a function.
  HTError.outsideReturn() {
    message = HTError._outsideReturn;
    type = HTErrorType.parser;
    code = HTErrorCode.outsideReturn;
  }

  /// Error: Illegal setter declaration.
  HTError.setterArity() {
    message = HTError._setterArity;
    type = HTErrorType.parser;
    code = HTErrorCode.setterArity;
  }

  /// Error: Illegal external member.
  HTError.externMember() {
    message = HTError._externMember;
    type = HTErrorType.parser;
    code = HTErrorCode.externMember;
  }

  /// Error: Type arguments is emtpy brackets.
  HTError.emptyTypeArgs() {
    message = HTError._emptyTypeArgs;
    type = HTErrorType.parser;
    code = HTErrorCode.emptyTypeArgs;
  }

  /// Error: Symbol is not a class name.
  HTError.notClass(String id) {
    message = '[$id] ${HTError._notClass}';
    type = HTErrorType.parser;
    code = HTErrorCode.notClass;
  }

  /// Error: Symbol is not a class name.
  HTError.notMember(String id) {
    message = '[$id] ${HTError._notMember}';
    type = HTErrorType.parser;
    code = HTErrorCode.notMember;
  }

  /// Error: Not a super class of this instance.
  HTError.ctorReturn() {
    message = HTError._ctorReturn;
    type = HTErrorType.parser;
    code = HTErrorCode.ctorReturn;
  }

  /// Error: Not a super class of this instance.
  HTError.abstracted() {
    message = HTError._abstracted;
    type = HTErrorType.parser;
    code = HTErrorCode.abstracted;
  }

  /// Error: Not a super class of this instance.
  HTError.abstractCtor() {
    message = HTError._abstractCtor;
    type = HTErrorType.parser;
    code = HTErrorCode.abstractCtor;
  }

  /// Error: Access private member.
  HTError.unknownOpCode(int opcode) {
    message = '${HTError._unknownOpCode} [$opcode]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.unknownOpCode;
  }

  /// Error: Access private member.
  HTError.privateMember(String id) {
    message = '${HTError._privateMember} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.privateMember;
  }

  /// Error: Access private declaration.
  HTError.privateDecl(String id) {
    message = '${HTError._privateDecl} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.privateDecl;
  }

  /// Error: Try to use a variable before its initialization.
  HTError.notInitialized(String id) {
    message = '[$id] ${HTError._notInitialized}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.notInitialized;
  }

  /// Error: Try to use a undefined variable.
  HTError.undefined(String id) {
    message = '${HTError._undefined} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.undefined;
  }

  /// Error: Try to use a external variable without its binding.
  HTError.undefinedExtern(String id) {
    message = '${HTError._undefinedExtern} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.undefinedExtern;
  }

  /// Error: Try to operate unkown type object.
  HTError.unknownType(String id) {
    message = '${HTError._unknownType} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.unknownType;
  }

  /// Error: Unknown operator.
  HTError.undefinedOperator(String id1, String op) {
    message = '${HTError._undefinedOperator} [$id1] [$op]';
    HTErrorType.interpreter;
    code = HTErrorCode.undefinedOperator;
  }

  /// Error: A same name declaration is already existed.
  HTError.definedRuntime(String id) {
    message = '[$id] ${HTError._defined}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.defined;
  }

// HTError.range(int length) { message = '${HTError.errorRange} [$length]';type = HTErrorType.interpreter;
// }

  /// Error: Object is not callable.
  HTError.notCallable(String id) {
    message = '[$id] ${HTError._notCallable}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.notCallable;
  }

  /// Error: Undefined member of a class/enum.
  HTError.undefinedMember(String id) {
    message = '[$id] ${HTError._undefinedMember}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.undefinedMember;
  }

  /// Error: if/while condition expression must be boolean type.
  HTError.condition() {
    message = HTError._condition;
    type = HTErrorType.interpreter;
    code = HTErrorCode.condition;
  }

  /// Error: Try to use sub get operator on a non-list object.
  HTError.notList(String id) {
    message = '[$id] ${HTError._notList}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.notList;
  }

  /// Error: Calling method on null object.
  HTError.nullObject(String id) {
    message = '${HTError._nullObject} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.nullObject;
  }

  /// Error: Type check failed.
  HTError.typeCheck(String id, String valueType, String declValue) {
    message =
        '${HTError._typeCheck1} [$id] ${HTError._ofType} [$declValue] ${HTError._typeCheck2} [$valueType]';
    HTErrorType.interpreter;
    code = HTErrorCode.typeCheck;
  }

  /// Error: Type is assign a unnullable varialbe with null.
  HTError.nullable(String id) {
    message = '[$id] ${HTError._nullable}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.nullable;
  }

  /// Error: Try to assign a immutable variable.
  HTError.immutable(String id) {
    message = '[$id] ${HTError._immutable}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.immutable;
  }

  /// Error: Symbol is not a type.
  HTError.notType(String id) {
    message = '[$id] ${HTError._notType}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.notType;
  }

  /// Error: Arguments type check failed.
  HTError.argType(String id, String assignValue, String declValue) {
    message =
        '${HTError._argType1} [$assignValue] ${HTError._ofType} [$assignValue] ${HTError._argType2} [$declValue]';
    HTErrorType.interpreter;
    code = HTErrorCode.argType;
  }

  /// Error: Return value type check failed.
  HTError.returnType(
    String returnedType,
    String funcName,
    String declReturnType,
  ) {
    message = '[$returnedType] ${HTError._returnType1}'
        ' [$funcName] ${HTError._returnType2} [$declReturnType]';
    HTErrorType.interpreter;
    code = HTErrorCode.returnType;
  }

  /// Error: Try to call a function without definition.
  HTError.missingFuncBody(String funcName) {
    message = '${HTError._missingFuncBody} [$funcName]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.missingFuncBody;
  }

  /// Error: Function arity check failed.
  HTError.arity(String id, int argsCount, int paramsCount) {
    message =
        '${HTError._arity1} [$argsCount] ${HTError._arity2} [$id] [$paramsCount]';
    HTErrorType.interpreter;
    code = HTErrorCode.arity;
  }

  /// Error: Missing binding extension on dart object.
  HTError.binding(String id) {
    message = '${HTError._binding} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.binding;
  }

  /// Error: Can not declare a external variable in global namespace.
  HTError.externalVar() {
    message = HTError._externalVar;
    type = HTErrorType.parser;
    code = HTErrorCode.externalVar;
  }

  /// Error: Bytecode signature check failed.
  HTError.bytesSig() {
    message = HTError._bytesSig;
    type = HTErrorType.interpreter;
    code = HTErrorCode.bytesSig;
  }

  /// Error: Variable's initialization relies on itself.
  HTError.circleInit(String id) {
    message = '${HTError._circleInit} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.circleInit;
  }

  /// Error: Missing variable initializer.
  HTError.initialize() {
    message = HTError._initialize;
    type = HTErrorType.interpreter;
    code = HTErrorCode.initialize;
  }

  /// Error: Named arguments does not exist.
  HTError.namedArg(String id) {
    message = '${HTError._namedArg} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.namedArg;
  }

  /// Error: Object is not iterable.
  HTError.iterable(String id) {
    message = '[$id] ${HTError._iterable}';
    type = HTErrorType.interpreter;
    code = HTErrorCode.iterable;
  }

  /// Error: Object is not iterable.
  HTError.unkownValueType(int valType) {
    message = '${HTError._unkownValueType} [$valType]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.unkownValueType;
  }

  /// Error: Unkown opcode value type.
  HTError.classOnInstance() {
    message = HTError._classOnInstance;
    type = HTErrorType.interpreter;
    code = HTErrorCode.classOnInstance;
  }

  /// Error: Illegal empty string.
  HTError.emptyString([String message = '']) {
    message = '${HTError._emptyString} [$message]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.emptyString;
  }

  /// Error: Illegal type cast.
  HTError.typeCast(String object, String type) {
    message = '[$object] ${HTError._typeCast} [$type]';
    HTErrorType.interpreter;
    code = HTErrorCode.typeCast;
  }

  /// Error: Illegal castee.
  HTError.castee(String varName) {
    message = '${HTError._castee} [$varName]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.castee;
  }

  /// Error: Illegal clone.
  HTError.clone(String varName) {
    message = '${HTError._clone} [$varName]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.clone;
  }

  /// Error: Not a super class of this instance.
  HTError.notSuper(String classId, String id) {
    message = '[$classId] ${HTError._notSuper} [$id]';
    type = HTErrorType.interpreter;
    code = HTErrorCode.notSuper;
  }
}
