import '../grammar/lexicon.dart';

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

  unsupported,
  intern,
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
  nullInit,
  nullObject,
  nullable,
  type,
  immutable,
  notType,
  argType,
  argInit,
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
  missingExternalFunc,
  externalCtorWithReferCtor,
  nonCotrWithReferCtor,
  internalFuncWithExternalTypeDef,
  moduleImport,
  classOnInstance,
  version,
  sourceType
}

/// The severity of an [ErrorCode].
class ErrorSeverity implements Comparable<ErrorSeverity> {
  /// The severity representing a non-error. This is never used for any error
  /// code, but is useful for clients.
  static const none = ErrorSeverity('NONE', 0, 'none');

  /// The severity representing an informational level analysis issue.
  static const info = ErrorSeverity('INFO', 1, 'info');

  /// The severity representing a warning. Warnings can become errors if the
  /// `-Werror` command line flag is specified.
  static const warning = ErrorSeverity('WARNING', 2, 'warning');

  /// The severity representing an error.
  static const error = ErrorSeverity('ERROR', 3, 'error');

  static const List<ErrorSeverity> values = [none, info, warning, error];

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
  static const todo = ErrorType('TODO', 0, ErrorSeverity.info);

  /// Extra analysis run over the code to follow best practices, which are not in
  /// the Dart Language Specification.
  static const hint = ErrorType('HINT', 1, ErrorSeverity.info);

  /// Lint warnings describe style and best practice recommendations that can be
  /// used to formalize a project's style guidelines.
  static const lint = ErrorType('LINT', 2, ErrorSeverity.info);

  /// Syntactic errors are errors produced as a result of input that does not
  /// conform to the grammar.
  static const syntacticError =
      ErrorType('SYNTACTIC_ERROR', 3, ErrorSeverity.error);

  static const analysisWarning =
      ErrorType('ANALYSIS_WARNING', 4, ErrorSeverity.warning);

  /// Reported by analyzer.
  static const analysisError =
      ErrorType('ANALYSIS_ERROR', 5, ErrorSeverity.error);

  /// Compile-time errors are errors that preclude execution. A compile time
  /// error must be reported by a compiler before the erroneous code is
  /// executed.
  static const compileError =
      ErrorType('COMPILE_ERROR', 6, ErrorSeverity.error);

  /// Run-time errors are errors that occurred during execution. A run time
  /// error is reported by the interpreter.
  static const runtimeError =
      ErrorType('RUNTIME_ERROR', 7, ErrorSeverity.error);

  /// External errors are errors reported by the dart side.
  static const externalError =
      ErrorType('NATIVE_ERROR', 8, ErrorSeverity.error);

  static const values = [
    todo,
    hint,
    lint,
    syntacticError,
    analysisWarning,
    analysisError,
    compileError,
    runtimeError,
    externalError
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
  late String message;

  /// moduleFullName when error occured.
  String? moduleFullName;

  /// Line number when error occured.
  int? line;

  /// Column number when error occured.
  int? column;

  @override
  String toString() {
    final output = StringBuffer();
    output.write('[$code]\n[$type}]\n');
    if (moduleFullName != null) {
      output.write('[File: $moduleFullName]\n');
    }
    if (line != null && column != null) {
      output.write('[Line: $line, Column: $column]\n');
    }
    output.write('$message\n');
    return output.toString();
  }

  /// [HTError] can not be created by default constructor.
  HTError(this.code, this.type,
      {String message = '',
      List<String> interpolations = const [],
      this.moduleFullName,
      this.line,
      this.column}) {
    for (var i = 0; i < interpolations.length; ++i) {
      message = message.replaceAll('{$i}', interpolations[i]);
    }
    this.message = message;
  }

  /// Error: Expected a token while met another.
  HTError.unexpected(String expected, String met)
      : this(ErrorCode.unexpected, ErrorType.syntacticError,
            message: HTLexicon.errorUnexpected,
            interpolations: [expected, met]);

  /// Error: Const variable in a class must be static.
  HTError.constMustBeStatic(String id)
      : this(ErrorCode.constMustBeStatic, ErrorType.compileError,
            message: HTLexicon.errorConstMustBeStatic, interpolations: [id]);

  /// Error: Const variable must be initialized.
  HTError.constMustInit(String id)
      : this(ErrorCode.constMustInit, ErrorType.compileError,
            message: HTLexicon.errorConstMustInit, interpolations: [id]);

  /// Error: A same name declaration is already existed.
  HTError.definedParser(String id)
      : this(ErrorCode.defined, ErrorType.compileError,
            message: HTLexicon.errorDefined, interpolations: [id]);

  /// Error: Illegal value appeared on left of assignment.
  HTError.invalidLeftValue()
      : this(ErrorCode.invalidLeftValue, ErrorType.compileError,
            message: HTLexicon.errorInvalidLeftValue);

  /// Error: Return appeared outside of a function.
  HTError.outsideReturn()
      : this(ErrorCode.outsideReturn, ErrorType.syntacticError,
            message: HTLexicon.errorOutsideReturn);

  /// Error: This appeared outside of a function.
  HTError.outsideThis()
      : this(ErrorCode.outsideThis, ErrorType.compileError,
            message: HTLexicon.errorOutsideThis);

  /// Error: Illegal setter declaration.
  HTError.setterArity()
      : this(ErrorCode.setterArity, ErrorType.syntacticError,
            message: HTLexicon.errorSetterArity);

  /// Error: Illegal external member.
  HTError.externMember()
      : this(ErrorCode.externMember, ErrorType.syntacticError,
            message: HTLexicon.errorExternMember);

  /// Error: Type arguments is emtpy brackets.
  HTError.emptyTypeArgs()
      : this(ErrorCode.emptyTypeArgs, ErrorType.syntacticError,
            message: HTLexicon.errorEmptyTypeArgs);

  /// Error: Symbol is not a class member.
  HTError.notMember(String id, String className)
      : this(ErrorCode.notMember, ErrorType.compileError,
            message: HTLexicon.errorNotMember, interpolations: [id, className]);

  /// Error: Symbol is not a class name.
  HTError.notClass(String id)
      : this(ErrorCode.notClass, ErrorType.compileError,
            message: HTLexicon.errorNotClass, interpolations: [id]);

  /// Error: Symbol is not a class name.
  HTError.extendsSelf()
      : this(ErrorCode.extendsSelf, ErrorType.syntacticError,
            message: HTLexicon.errorExtendsSelf);

  /// Error: Not a super class of this instance.
  HTError.ctorReturn()
      : this(ErrorCode.ctorReturn, ErrorType.syntacticError,
            message: HTLexicon.errorCtorReturn);

  /// Error: Not a super class of this instance.
  HTError.abstracted()
      : this(ErrorCode.abstracted, ErrorType.compileError,
            message: HTLexicon.errorAbstracted);

  /// Error: Not a super class of this instance.
  HTError.abstractCtor()
      : this(ErrorCode.abstractCtor, ErrorType.compileError,
            message: HTLexicon.errorAbstractCtor);

  /// Error: unsupported method
  HTError.unsupported(String name)
      : this(ErrorCode.unsupported, ErrorType.runtimeError,
            message: HTLexicon.errorUnsupported, interpolations: [name]);

  /// Error: Access private member.
  HTError.unknownOpCode(int opcode)
      : this(ErrorCode.unknownOpCode, ErrorType.runtimeError,
            message: HTLexicon.errorUnknownOpCode,
            interpolations: [opcode.toString()]);

  /// Error: Access private member.
  HTError.privateMember(String id)
      : this(ErrorCode.privateMember, ErrorType.runtimeError,
            message: HTLexicon.errorPrivateMember, interpolations: [id]);

  /// Error: Access private declaration.
  HTError.privateDecl(String id)
      : this(ErrorCode.privateDecl, ErrorType.runtimeError,
            message: HTLexicon.errorPrivateDecl, interpolations: [id]);

  /// Error: Try to use a variable before its initialization.
  HTError.notInitialized(String id)
      : this(ErrorCode.notInitialized, ErrorType.runtimeError,
            message: HTLexicon.errorNotInitialized, interpolations: [id]);

  /// Error: Try to use a undefined variable.
  HTError.undefined(String id)
      : this(ErrorCode.undefined, ErrorType.runtimeError,
            message: HTLexicon.errorUndefined, interpolations: [id]);

  /// Error: Try to use a external variable without its binding.
  HTError.undefinedExtern(String id)
      : this(ErrorCode.undefinedExtern, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedExtern, interpolations: [id]);

  /// Error: Try to operate unkown type object.
  HTError.unknownTypeName(String id)
      : this(ErrorCode.unknownTypeName, ErrorType.runtimeError,
            message: HTLexicon.errorUnknownTypeName, interpolations: [id]);

  /// Error: Unknown operator.
  HTError.undefinedOperator(String id, String op)
      : this(ErrorCode.undefinedOperator, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedOperator,
            interpolations: [id, op]);

  /// Error: A same name declaration is already existed.
  HTError.definedRuntime(String id)
      : this(ErrorCode.defined, ErrorType.runtimeError,
            message: HTLexicon.errorDefined, interpolations: [id]);

// HTError.range(int length) { message = '${HTError.errorRange} [$length]';type = HTErrorType.interpreter;
// }

  /// Error: Object is not callable.
  HTError.notCallable(String id)
      : this(ErrorCode.notCallable, ErrorType.runtimeError,
            message: HTLexicon.errorNotCallable, interpolations: [id]);

  /// Error: Undefined member of a class/enum.
  HTError.undefinedMember(String id)
      : this(ErrorCode.undefinedMember, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedMember, interpolations: [id]);

  /// Error: if/while condition expression must be boolean type.
  HTError.condition()
      : this(ErrorCode.condition, ErrorType.runtimeError,
            message: HTLexicon.errorCondition);

  /// Error: Try to use sub get operator on a non-list object.
  HTError.notList(String id)
      : this(ErrorCode.notList, ErrorType.runtimeError,
            message: HTLexicon.errorNotList, interpolations: [id]);

  /// Error: Calling method on null object.
  HTError.errorNullInit()
      : this(ErrorCode.nullInit, ErrorType.runtimeError,
            message: HTLexicon.errorNullInit);

  /// Error: Calling method on null object.
  HTError.nullObject(String id)
      : this(ErrorCode.nullObject, ErrorType.runtimeError,
            message: HTLexicon.errorNullObject, interpolations: [id]);

  /// Error: Type is assign a unnullable varialbe with null.
  HTError.nullable(String id)
      : this(ErrorCode.nullable, ErrorType.runtimeError,
            message: HTLexicon.errorNullable, interpolations: [id]);

  /// Error: Type check failed.
  HTError.type(String id, String valueType, String declValue)
      : this(ErrorCode.type, ErrorType.runtimeError,
            message: HTLexicon.errorType,
            interpolations: [id, valueType, declValue]);

  /// Error: Try to assign a immutable variable.
  HTError.immutable(String id)
      : this(ErrorCode.immutable, ErrorType.runtimeError,
            message: HTLexicon.errorImmutable, interpolations: [id]);

  /// Error: Symbol is not a type.
  HTError.notType(String id)
      : this(ErrorCode.notType, ErrorType.runtimeError,
            message: HTLexicon.errorNotType, interpolations: [id]);

  /// Error: Arguments type check failed.
  HTError.argType(String id, String assignType, String declValue)
      : this(ErrorCode.argType, ErrorType.runtimeError,
            message: HTLexicon.errorArgType,
            interpolations: [id, assignType, declValue]);

  /// Error: Only optional or named arguments can have initializer.
  HTError.argInit()
      : this(ErrorCode.argInit, ErrorType.syntacticError,
            message: HTLexicon.errorArgInit);

  /// Error: Return value type check failed.
  HTError.returnType(
    String returnedType,
    String funcName,
    String declReturnType,
  ) : this(ErrorCode.returnType, ErrorType.runtimeError,
            message: HTLexicon.errorReturnType,
            interpolations: [returnedType, funcName, declReturnType]);

  /// Error: Try to call a function without definition.
  HTError.missingFuncBody(String id)
      : this(ErrorCode.missingFuncBody, ErrorType.syntacticError,
            message: HTLexicon.errorMissingFuncBody, interpolations: [id]);

  /// Error: Function arity check failed.
  HTError.arity(String id, int argsCount, int paramsCount)
      : this(ErrorCode.arity, ErrorType.runtimeError,
            message: HTLexicon.errorArity,
            interpolations: [id, argsCount.toString(), paramsCount.toString()]);

  /// Error: Missing binding extension on dart object.
  HTError.binding(String id)
      : this(ErrorCode.binding, ErrorType.runtimeError,
            message: HTLexicon.errorBinding, interpolations: [id]);

  /// Error: Can not declare a external variable in global namespace.
  HTError.externalVar()
      : this(ErrorCode.externalVar, ErrorType.syntacticError,
            message: HTLexicon.errorExternalVar);

  /// Error: Bytecode signature check failed.
  HTError.bytesSig()
      : this(ErrorCode.bytesSig, ErrorType.runtimeError,
            message: HTLexicon.errorBytesSig);

  /// Error: Variable's initialization relies on itself.
  HTError.circleInit(String id)
      : this(ErrorCode.circleInit, ErrorType.runtimeError,
            message: HTLexicon.errorCircleInit, interpolations: [id]);

  /// Error: Missing variable initializer.
  HTError.initialize()
      : this(ErrorCode.initialize, ErrorType.runtimeError,
            message: HTLexicon.errorInitialize);

  /// Error: Named arguments does not exist.
  HTError.namedArg(String id)
      : this(ErrorCode.namedArg, ErrorType.runtimeError,
            message: HTLexicon.errorNamedArg, interpolations: [id]);

  /// Error: Object is not iterable.
  HTError.iterable(String id)
      : this(ErrorCode.iterable, ErrorType.runtimeError,
            message: HTLexicon.errorIterable, interpolations: [id]);

  /// Error: Unknown value type code
  HTError.unkownValueType(int valType)
      : this(ErrorCode.unkownValueType, ErrorType.runtimeError,
            message: HTLexicon.errorUnkownValueType,
            interpolations: [valType.toString()]);

  /// Error: Illegal empty string.
  HTError.emptyString([String? message])
      : this(ErrorCode.emptyString, ErrorType.runtimeError,
            message: HTLexicon.errorEmptyString,
            interpolations: message != null ? [message] : []);

  /// Error: Illegal type cast.
  HTError.typeCast(String object, String type)
      : this(ErrorCode.typeCast, ErrorType.runtimeError,
            message: HTLexicon.errorTypeCast, interpolations: [object, type]);

  /// Error: Illegal castee.
  HTError.castee(String varName)
      : this(ErrorCode.castee, ErrorType.runtimeError,
            message: HTLexicon.errorCastee, interpolations: [varName]);

  /// Error: Illegal clone.
  HTError.clone(String varName)
      : this(ErrorCode.clone, ErrorType.runtimeError,
            message: HTLexicon.errorClone, interpolations: [varName]);

  /// Error: Not a super class of this instance.
  HTError.notSuper(String classId, String id)
      : this(ErrorCode.notSuper, ErrorType.runtimeError,
            message: HTLexicon.errorNotSuper, interpolations: [classId, id]);

  HTError.missingExternalFunc(String id)
      : this(ErrorCode.missingExternalFunc, ErrorType.runtimeError,
            message: HTLexicon.errorMissingExternalFunc, interpolations: [id]);

  HTError.internalFuncWithExternalTypeDef()
      : this(ErrorCode.missingExternalFunc, ErrorType.syntacticError,
            message: HTLexicon.errorInternalFuncWithExternalTypeDef);

  HTError.externalCtorWithReferCtor()
      : this(ErrorCode.externalCtorWithReferCtor, ErrorType.syntacticError,
            message: HTLexicon.errorExternalCtorWithReferCtor);

  HTError.nonCotrWithReferCtor()
      : this(ErrorCode.nonCotrWithReferCtor, ErrorType.syntacticError,
            message: HTLexicon.errorNonCotrWithReferCtor);

  /// Error: Module import error
  HTError.moduleImport(String id)
      : this(ErrorCode.moduleImport, ErrorType.runtimeError,
            message: HTLexicon.errorModuleImport, interpolations: [id]);

  /// Error: Try to define a class on a instance.
  HTError.classOnInstance()
      : this(ErrorCode.classOnInstance, ErrorType.runtimeError,
            message: HTLexicon.errorClassOnInstance);

  /// Error: Incompatible bytecode version.
  HTError.version(String codeVer, String itpVer)
      : this(ErrorCode.version, ErrorType.runtimeError,
            message: HTLexicon.errorVersion, interpolations: [codeVer, itpVer]);

  /// Error: Unevalable source type.
  HTError.sourceType()
      : this(ErrorCode.sourceType, ErrorType.runtimeError,
            message: HTLexicon.errorSourceType);
}
