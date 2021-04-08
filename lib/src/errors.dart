/// Error type tells who throws this erro
enum HTErrorType {
  parser,
  interpreter,
  import,
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
  static const _conditionMustBeBool =
      'Condition expression must evaluate to type [bool]';
  static const _missingFuncBody = 'Missing function definition body of';
  static const _notList = 'is not a List or Map.';
  static const _notClass = 'is not a class.';
  static const _notMember = 'is not a instance member declaration.';
  static const _ctorReturn = 'Constructor cannot have a return type.';
  static const _abstract = 'Cannot create instance from abstract class.';
  static const _abstractCtor = 'Cannot create contructor for abstract class.';

  static const _setterArity = 'Setter function\'s arity must be 1.';
  static const _errorNullObject = 'Calling method on null object:';
  static const _immutable = 'is immutable.';
  static const _notType = 'is not a type.';
  static const _ofType = 'of type';
  static const _nullable = 'is not nullable.';
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
  static const _castee = 'Illegal cast target';
  static const _clone = 'Illegal clone on';
  static const _notSuper = 'is not a super class of';

  /// Print a warning message to standard output, will not throw.
  static void warn(String message) => print('hetu warn:\n' + message);

  /// Error message.
  String? message;

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
  HTError(this.message, this.type,
      [this.moduleUniqueKey, this.line, this.column]);

  /// Error: Module import error
  HTError.import(String id) {
    message = _import;
    type = HTErrorType.import;
  }

  /// Error: Expected a token while met another.
  HTError.expected(String expected, String met) {
    message =
        '[${expected != '\n' ? expected : '\\n'}] $_expected [${met != '\n' ? met : '\\n'}]';
    type = HTErrorType.parser;
  }

  /// Error: Const variable in a class must be static.
  HTError.constMustBeStatic(String id) {
    message = _constMustBeStatic;
    type = HTErrorType.parser;
  }

  /// Error: Const variable must be initialized.
  HTError.constMustInit(String id) {
    message = _constMustInit;
    type = HTErrorType.parser;
  }

  /// Error: A unexpected token appeared.
  HTError.unexpected(String id) {
    message = '${HTError._unexpected} [${id != '\n' ? id : '\\n'}]';
    type = HTErrorType.parser;
  }

  /// Error: A same name declaration is already existed.
  HTError.definedParser(String id) {
    message = '[$id] ${HTError._defined}';
    type = HTErrorType.parser;
  }

  /// Error: Illegal value appeared on left of assignment.
  HTError.illegalLeftValueParser() {
    message = HTError._invalidLeftValue;
    type = HTErrorType.parser;
  }

  /// Error: Return appeared outside of a function.
  HTError.outsideReturn() {
    message = HTError._outsideReturn;
    type = HTErrorType.parser;
  }

  /// Error: Illegal setter declaration.
  HTError.setter() {
    message = HTError._setterArity;
    type = HTErrorType.parser;
  }

  /// Error: Symbol is not a class name.
  HTError.notClass(String id) {
    message = '[$id] ${HTError._notClass}';
    type = HTErrorType.parser;
  }

  /// Error: Symbol is not a class name.
  HTError.notMember(String id) {
    message = '[$id] ${HTError._notMember}';
    type = HTErrorType.parser;
  }

  /// Error: Not a super class of this instance.
  HTError.ctorNotSuper() {
    message = HTError._ctorReturn;
    type = HTErrorType.parser;
  }

  /// Error: Not a super class of this instance.
  HTError.abstracted() {
    message = HTError._abstract;
    type = HTErrorType.parser;
  }

  /// Error: Not a super class of this instance.
  HTError.abstractedCtor() {
    message = HTError._abstractCtor;
    type = HTErrorType.parser;
  }

  /// Error: Access private member.
  HTError.privateMember(String id) {
    message = '${HTError._privateMember} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Access private declaration.
  HTError.privateDecl(String id) {
    message = '${HTError._privateDecl} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Try to use a variable before its initialization.
  HTError.initialized(String id) {
    message = '[$id] ${HTError._notInitialized}';
    type = HTErrorType.interpreter;
  }

  /// Error: Try to use a undefined variable.
  HTError.undefined(String id) {
    message = '${HTError._undefined} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Try to use a external variable without its binding.
  HTError.undefinedExtern(String id) {
    message = '${HTError._undefinedExtern} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Try to operate unkown type object.
  HTError.unknownType(String id) {
    message = '${HTError._unknownType} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Unknown operator.
  HTError.undefinedOperator(String id1, String op) {
    message = '${HTError._undefinedOperator} [$id1] [$op]';
    HTErrorType.interpreter;
  }

  /// Error: A same name declaration is already existed.
  HTError.definedRuntime(String id) {
    message = '[$id] ${HTError._defined}';
    type = HTErrorType.interpreter;
  }

// HTError.range(int length) { message = '${HTError.errorRange} [$length]';type = HTErrorType.interpreter;
// }

  /// Error: Object is not callable.
  HTError.callable(String id) {
    message = '[$id] ${HTError._notCallable}';
    type = HTErrorType.interpreter;
  }

  /// Error: Undefined member of a class/enum.
  HTError.undefinedMember(String id) {
    message = '[$id] ${HTError._undefinedMember}';
    type = HTErrorType.interpreter;
  }

  /// Error: if/while condition expression must be boolean type.
  HTError.condition() {
    message = HTError._conditionMustBeBool;
    type = HTErrorType.interpreter;
  }

  /// Error: Try to use sub get operator on a non-list object.
  HTError.subGet(String id) {
    message = '[$id] ${HTError._notList}';
    type = HTErrorType.interpreter;
  }

  /// Error: extends Type must be a class.
  HTError.extendsNotAClass(String id) {
    message = '[$id] ${HTError._notClass}';
    type = HTErrorType.interpreter;
  }

  /// Error: Calling method on null object.
  HTError.nullObject(String id) {
    message = '${HTError._errorNullObject} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Type check failed.
  HTError.typeCheck(String id, String valueType, String declValue) {
    message =
        '${HTError._typeCheck1} [$id] ${HTError._ofType} [$declValue] ${HTError._typeCheck2} [$valueType]';
    HTErrorType.interpreter;
  }

  /// Error: Type is assign a unnullable varialbe with null.
  HTError.nullable(String id) {
    message = '[$id] ${HTError._nullable}';
    type = HTErrorType.interpreter;
  }

  /// Error: Try to assign a immutable variable.
  HTError.immutable(String id) {
    message = '[$id] ${HTError._immutable}';
    type = HTErrorType.interpreter;
  }

  /// Error: Symbol is not a type.
  HTError.notType(String id) {
    message = '[$id] ${HTError._notType}';
    type = HTErrorType.interpreter;
  }

  /// Error: Arguments type check failed.
  HTError.argType(String id, String assignValue, String declValue) {
    message =
        '${HTError._argType1} [$assignValue] ${HTError._ofType} [$assignValue] ${HTError._argType2} [$declValue]';
    HTErrorType.interpreter;
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
  }

  /// Error: Try to call a function without definition.
  HTError.missingFuncDef(String funcName) {
    message = '${HTError._missingFuncBody} [$funcName]';
    type = HTErrorType.interpreter;
  }

  /// Error: Function arity check failed.
  HTError.arity(String id, int argsCount, int paramsCount) {
    message =
        '${HTError._arity1} [$argsCount] ${HTError._arity2} [$id] [$paramsCount]';
    HTErrorType.interpreter;
  }

  /// Error: Missing binding extension on dart object.
  HTError.binding(String id) {
    message = '${HTError._binding} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Can not declare a external variable in global namespace.
  HTError.externVar() {
    message = HTError._externalVar;
    type = HTErrorType.parser;
  }

  /// Error: Bytecode signature check failed.
  HTError.signature() {
    message = HTError._bytesSig;
    type = HTErrorType.interpreter;
  }

  /// Error: Variable's initialization relies on itself.
  HTError.circleInit(String id) {
    message = '${HTError._circleInit} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Missing variable initializer.
  HTError.initialize() {
    message = HTError._initialize;
    type = HTErrorType.interpreter;
  }

  /// Error: Named arguments does not exist.
  HTError.namedArg(String id) {
    message = '${HTError._namedArg} [$id]';
    type = HTErrorType.interpreter;
  }

  /// Error: Object is not iterable.
  HTError.iterable(String id) {
    message = '[$id] ${HTError._iterable}';
    type = HTErrorType.interpreter;
  }

  /// Error: Object is not iterable.
  HTError.unkownValueType(int valType) {
    message = '${HTError._unkownValueType} [$valType]';
    type = HTErrorType.interpreter;
  }

  /// Error: Unkown opcode value type.
  HTError.classOnInstance() {
    message = HTError._classOnInstance;
    type = HTErrorType.interpreter;
  }

  /// Error: Illegal empty string.
  HTError.empty([String fileName = '']) {
    message = '${HTError._emptyString} [$fileName]';
    type = HTErrorType.interpreter;
  }

  /// Error: Illegal type cast.
  HTError.typeCast(String object, String type) {
    message = '[$object] ${HTError._typecast} [$type]';
    HTErrorType.interpreter;
  }

  /// Error: Illegal castee.
  HTError.castee(String varName) {
    message = '${HTError._castee} [$varName]';
    type = HTErrorType.interpreter;
  }

  /// Error: Illegal clone.
  HTError.clone(String varName) {
    message = '${HTError._clone} [$varName]';
    type = HTErrorType.interpreter;
  }

  /// Error: Not a super class of this instance.
  HTError.notSuper(String classId, String id) {
    message = '[$classId] ${HTError._notSuper} [$id]';
    type = HTErrorType.interpreter;
  }
}
