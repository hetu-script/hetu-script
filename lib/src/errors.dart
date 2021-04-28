import 'lexicon.dart';

enum ErrorCode {
  unexpected,
  constMustBeStatic,
  constMustInit,
  defined,
  invalidLeftValue,
  outsideReturn,
  outsideThis,
  setterArity,
  externMember,
  emptyTypeArgs,
  notMember,
  notClass,
  extendsSelf,
  ctorReturn,
  abstracted,
  abstractCtor,

  extern,
  unknownOpCode,
  privateMember,
  privateDecl,
  notInitialized,
  undefined,
  undefinedExtern,
  unknownTypeName,
  undefinedOperator,
  notCallable,
  undefinedMember,
  condition,
  notList,
  nullObject,
  nullable,
  type,
  immutable,
  notType,
  argType,
  returnType,
  missingFuncBody,
  arity,
  binding,
  externalVar,
  bytesSig,
  circleInit,
  initialize,
  namedArg,
  iterable,
  unkownValueType,
  emptyString,
  typeCast,
  castee,
  clone,
  notSuper,
  missingExternalFuncDef,
  externalCtorWithReferCtor,
  nonCotrWithReferCtor,
  internalFuncWithExternalTypeDef,
  moduleImport,
  classOnInstance
}

/// The severity of an [ErrorCode].
class ErrorSeverity implements Comparable<ErrorSeverity> {
  /// The severity representing a non-error. This is never used for any error
  /// code, but is useful for clients.
  static const NONE = ErrorSeverity('NONE', 0, 'none');

  /// The severity representing an informational level analysis issue.
  static const INFO = ErrorSeverity('INFO', 1, 'info');

  /// The severity representing a warning. Warnings can become errors if the
  /// `-Werror` command line flag is specified.
  static const WARNING = ErrorSeverity('WARNING', 2, 'warning');

  /// The severity representing an error.
  static const ERROR = ErrorSeverity('ERROR', 3, 'error');

  static const List<ErrorSeverity> values = [NONE, INFO, WARNING, ERROR];

  /// The name of this error code.
  final String name;

  /// The weight value of the error code.
  final int weight;

  /// The name of the severity used when producing readable output.
  final String displayName;

  /// Initialize a newly created severity with the given names.
  const ErrorSeverity(this.name, this.weight, this.displayName);

  @override
  int get hashCode => weight;

  @override
  int compareTo(ErrorSeverity other) => weight - other.weight;

  /// Return the severity constant that represents the greatest severity.
  ErrorSeverity max(ErrorSeverity severity) =>
      weight >= severity.weight ? this : severity;

  @override
  String toString() => name;
}

/// The type of an [HTError].
class ErrorType implements Comparable<ErrorType> {
  /// Task (todo) comments in user code.
  static const TODO = ErrorType('TODO', 0, ErrorSeverity.INFO);

  /// Extra analysis run over the code to follow best practices, which are not in
  /// the Dart Language Specification.
  static const HINT = ErrorType('HINT', 1, ErrorSeverity.INFO);

  /// Lint warnings describe style and best practice recommendations that can be
  /// used to formalize a project's style guidelines.
  static const LINT = ErrorType('LINT', 2, ErrorSeverity.INFO);

  /// Static warnings are those warnings reported by the static checker.
  /// They have no effect on execution. Static warnings must be
  /// provided by compilers used during development.
  static const STATIC_WARNING =
      ErrorType('STATIC_WARNING', 3, ErrorSeverity.WARNING);

  /// Syntactic errors are errors produced as a result of input that does not
  /// conform to the grammar.
  static const SYNTACTIC_ERROR =
      ErrorType('SYNTACTIC_ERROR', 5, ErrorSeverity.ERROR);

  /// Compile-time errors are errors that preclude execution. A compile time
  /// error must be reported by a compiler before the erroneous code is
  /// executed.
  static const COMPILE_TIME_ERROR =
      ErrorType('COMPILE_TIME_ERROR', 6, ErrorSeverity.ERROR);

  /// Run-time errors are errors that occurred during execution. A run time
  /// error is reported by the interpreter.
  static const RUN_TIME_ERROR =
      ErrorType('RUN_TIME_ERROR', 7, ErrorSeverity.ERROR);

  /// External errors are errors reported by the dart side.
  static const EXTERNAL_ERROR =
      ErrorType('NATIVE_ERROR', 7, ErrorSeverity.ERROR);

  static const values = [
    TODO,
    HINT,
    LINT,
    STATIC_WARNING,
    SYNTACTIC_ERROR,
    COMPILE_TIME_ERROR,
    RUN_TIME_ERROR,
    EXTERNAL_ERROR
  ];

  /// The name of this error type.
  final String name;

  /// The weight value of the error type.
  final int weight;

  /// The severity of this type of error.
  final ErrorSeverity severity;

  /// Initialize a newly created error type to have the given [name] and
  /// [severity].
  const ErrorType(this.name, this.weight, this.severity);

  String get displayName => name.toLowerCase().replaceAll('_', ' ');

  @override
  int get hashCode => weight;

  @override
  int compareTo(ErrorType other) => weight - other.weight;

  @override
  String toString() => name;
}

/// Contains error messages.
class HTError {
  final ErrorCode code;

  /// Error type.
  final ErrorType type;

  ErrorSeverity get severity => type.severity;

  /// Error message.
  late final String message;

  /// moduleFullName when error occured.
  String? moduleFullName;

  /// Line number when error occured.
  int? line;

  /// Column number when error occured.
  int? column;

  @override
  String toString() =>
      '[$code]\n[$type}]\n[File: $moduleFullName]\n[Line: $line, Column: $column]\n$message';

  /// [HTError] can not be created by default constructor.
  HTError(this.code, this.type,
      {String message = '',
      List<String> interpolations = const <String>[],
      this.moduleFullName,
      this.line,
      this.column}) {
    for (var i = 0; i < interpolations.length; ++i) {
      message.replaceAll('{$i}', interpolations[i]);
    }
    this.message = message;
  }

  /// Error: Expected a token while met another.
  HTError.unexpected(String expected, String met)
      : this(ErrorCode.unexpected, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorUnexpected,
            interpolations: [expected, met]);

  /// Error: Const variable in a class must be static.
  HTError.constMustBeStatic(String id)
      : this(ErrorCode.constMustBeStatic, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorConstMustBeStatic, interpolations: [id]);

  /// Error: Const variable must be initialized.
  HTError.constMustInit(String id)
      : this(ErrorCode.constMustInit, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorConstMustInit, interpolations: [id]);

  /// Error: A same name declaration is already existed.
  HTError.definedParser(String id)
      : this(ErrorCode.defined, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorDefined);

  /// Error: Illegal value appeared on left of assignment.
  HTError.invalidLeftValue()
      : this(ErrorCode.invalidLeftValue, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorInvalidLeftValue);

  /// Error: Return appeared outside of a function.
  HTError.outsideReturn()
      : this(ErrorCode.outsideReturn, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorOutsideReturn);

  /// Error: This appeared outside of a function.
  HTError.outsideThis()
      : this(ErrorCode.outsideThis, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorOutsideThis);

  /// Error: Illegal setter declaration.
  HTError.setterArity()
      : this(ErrorCode.setterArity, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorSetterArity);

  /// Error: Illegal external member.
  HTError.externMember()
      : this(ErrorCode.externMember, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorExternMember);

  /// Error: Type arguments is emtpy brackets.
  HTError.emptyTypeArgs()
      : this(ErrorCode.emptyTypeArgs, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorEmptyTypeArgs);

  /// Error: Symbol is not a class member.
  HTError.notMember(String id, String className)
      : this(ErrorCode.notMember, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorNotMember, interpolations: [id, className]);

  /// Error: Symbol is not a class name.
  HTError.notClass(String id)
      : this(ErrorCode.notClass, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorNotClass, interpolations: [id]);

  /// Error: Symbol is not a class name.
  HTError.extendsSelf()
      : this(ErrorCode.extendsSelf, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorExtendsSelf);

  /// Error: Not a super class of this instance.
  HTError.ctorReturn()
      : this(ErrorCode.ctorReturn, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorCtorReturn);

  /// Error: Not a super class of this instance.
  HTError.abstracted()
      : this(ErrorCode.abstracted, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorAbstracted);

  /// Error: Not a super class of this instance.
  HTError.abstractCtor()
      : this(ErrorCode.abstractCtor, ErrorType.COMPILE_TIME_ERROR,
            message: HTLexicon.errorAbstractCtor);

  /// Error: Access private member.
  HTError.unknownOpCode(int opcode)
      : this(ErrorCode.unknownOpCode, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorUnknownOpCode,
            interpolations: [opcode.toString()]);

  /// Error: Access private member.
  HTError.privateMember(String id)
      : this(ErrorCode.privateMember, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorPrivateMember, interpolations: [id]);

  /// Error: Access private declaration.
  HTError.privateDecl(String id)
      : this(ErrorCode.privateDecl, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorPrivateDecl, interpolations: [id]);

  /// Error: Try to use a variable before its initialization.
  HTError.notInitialized(String id)
      : this(ErrorCode.notInitialized, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNotInitialized, interpolations: [id]);

  /// Error: Try to use a undefined variable.
  HTError.undefined(String id)
      : this(ErrorCode.undefined, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorUndefined, interpolations: [id]);

  /// Error: Try to use a external variable without its binding.
  HTError.undefinedExtern(String id)
      : this(ErrorCode.undefinedExtern, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorUndefinedExtern, interpolations: [id]);

  /// Error: Try to operate unkown type object.
  HTError.unknownTypeName(String id)
      : this(ErrorCode.unknownTypeName, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorUnknownTypeName, interpolations: [id]);

  /// Error: Unknown operator.
  HTError.undefinedOperator(String id, String op)
      : this(ErrorCode.undefinedOperator, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorUndefinedOperator,
            interpolations: [id, op]);

  /// Error: A same name declaration is already existed.
  HTError.definedRuntime(String id)
      : this(ErrorCode.defined, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorDefined, interpolations: [id]);

// HTError.range(int length) { message = '${HTError.errorRange} [$length]';type = HTErrorType.interpreter;
// }

  /// Error: Object is not callable.
  HTError.notCallable(String id)
      : this(ErrorCode.notCallable, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNotCallable, interpolations: [id]);

  /// Error: Undefined member of a class/enum.
  HTError.undefinedMember(String id)
      : this(ErrorCode.undefinedMember, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorUndefinedMember, interpolations: [id]);

  /// Error: if/while condition expression must be boolean type.
  HTError.condition()
      : this(ErrorCode.condition, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorCondition);

  /// Error: Try to use sub get operator on a non-list object.
  HTError.notList(String id)
      : this(ErrorCode.notList, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNotList, interpolations: [id]);

  /// Error: Calling method on null object.
  HTError.nullObject(String id)
      : this(ErrorCode.nullObject, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNullObject, interpolations: [id]);

  /// Error: Type is assign a unnullable varialbe with null.
  HTError.nullable(String id)
      : this(ErrorCode.nullable, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNullable, interpolations: [id]);

  /// Error: Type check failed.
  HTError.type(String id, String valueType, String declValue)
      : this(ErrorCode.type, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorType,
            interpolations: [id, valueType, declValue]);

  /// Error: Try to assign a immutable variable.
  HTError.immutable(String id)
      : this(ErrorCode.immutable, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorImmutable, interpolations: [id]);

  /// Error: Symbol is not a type.
  HTError.notType(String id)
      : this(ErrorCode.notType, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNotType, interpolations: [id]);

  /// Error: Arguments type check failed.
  HTError.argType(String id, String assignType, String declValue)
      : this(ErrorCode.argType, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorArgType,
            interpolations: [id, assignType, declValue]);

  /// Error: Return value type check failed.
  HTError.returnType(
    String returnedType,
    String funcName,
    String declReturnType,
  ) : this(ErrorCode.returnType, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorReturnType,
            interpolations: [returnedType, funcName, declReturnType]);

  /// Error: Try to call a function without definition.
  HTError.missingFuncBody(String id)
      : this(ErrorCode.missingFuncBody, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorMissingFuncBody, interpolations: [id]);

  /// Error: Function arity check failed.
  HTError.arity(String id, int argsCount, int paramsCount)
      : this(ErrorCode.arity, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorArity,
            interpolations: [id, argsCount.toString(), paramsCount.toString()]);

  /// Error: Missing binding extension on dart object.
  HTError.binding(String id)
      : this(ErrorCode.binding, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorBinding, interpolations: [id]);

  /// Error: Can not declare a external variable in global namespace.
  HTError.externalVar()
      : this(ErrorCode.externalVar, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorExternalVar);

  /// Error: Bytecode signature check failed.
  HTError.bytesSig()
      : this(ErrorCode.bytesSig, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorBytesSig);

  /// Error: Variable's initialization relies on itself.
  HTError.circleInit(String id)
      : this(ErrorCode.circleInit, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorCircleInit, interpolations: [id]);

  /// Error: Missing variable initializer.
  HTError.initialize()
      : this(ErrorCode.initialize, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorInitialize);

  /// Error: Named arguments does not exist.
  HTError.namedArg(String id)
      : this(ErrorCode.namedArg, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNamedArg, interpolations: [id]);

  /// Error: Object is not iterable.
  HTError.iterable(String id)
      : this(ErrorCode.iterable, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorIterable, interpolations: [id]);

  /// Error: Unknown value type code
  HTError.unkownValueType(int valType)
      : this(ErrorCode.unkownValueType, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorUnkownValueType,
            interpolations: [valType.toString()]);

  /// Error: Illegal empty string.
  HTError.emptyString([String? message])
      : this(ErrorCode.emptyString, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorEmptyString,
            interpolations: message != null ? [message] : []);

  /// Error: Illegal type cast.
  HTError.typeCast(String object, String type)
      : this(ErrorCode.typeCast, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorTypeCast, interpolations: [object, type]);

  /// Error: Illegal castee.
  HTError.castee(String varName)
      : this(ErrorCode.castee, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorCastee, interpolations: [varName]);

  /// Error: Illegal clone.
  HTError.clone(String varName)
      : this(ErrorCode.clone, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorClone, interpolations: [varName]);

  /// Error: Not a super class of this instance.
  HTError.notSuper(String classId, String id)
      : this(ErrorCode.notSuper, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNotSuper, interpolations: [classId, id]);

  HTError.missingExternalFuncDef(String id)
      : this(ErrorCode.missingExternalFuncDef, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorMissingExternalFuncDef,
            interpolations: [id]);

  HTError.internalFuncWithExternalTypeDef()
      : this(ErrorCode.missingExternalFuncDef, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorInternalFuncWithExternalTypeDef);

  HTError.externalCtorWithReferCtor()
      : this(ErrorCode.externalCtorWithReferCtor, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorExternalCtorWithReferCtor);

  HTError.nonCotrWithReferCtor()
      : this(ErrorCode.nonCotrWithReferCtor, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorNonCotrWithReferCtor);

  /// Error: Module import error
  HTError.moduleImport(String id)
      : this(ErrorCode.moduleImport, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorModuleImport, interpolations: [id]);

  /// Error: Try to define a class on a instance.
  HTError.classOnInstance()
      : this(ErrorCode.classOnInstance, ErrorType.RUN_TIME_ERROR,
            message: HTLexicon.errorClassOnInstance);
}
