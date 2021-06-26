import '../grammar/lexicon.dart';
import '../analyzer/analyzer.dart' show AnalyzerConfig;

part 'error_processor.dart';

enum ErrorCode {
  unexpected,
  externalType,
  nestedClass,
  constMustBeStatic,
  constMustInit,
  defined,
  invalidLeftValue,
  outsideReturn,
  outsideThis,
  setterArity,
  externalMember,
  emptyTypeArgs,
  notMember,
  notClass,
  extendsSelf,
  ctorReturn,
  abstracted,
  abstractCtor,

  unsupported,
  extern,
  unknownOpCode,
  privateMember,
  privateDecl,
  notInitialized,
  undefined,
  undefinedExternal,
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
  stringInterpolation,
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
  sourceType,
  nonExistModule
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

  /// Reported by analyzer.
  static const staticTypeWarning =
      ErrorType('STATIC_TYPE_WARNING', 4, ErrorSeverity.warning);

  /// Reported by analyzer.
  static const staticWarning =
      ErrorType('STATIC_WARNING', 5, ErrorSeverity.error);

  /// Compile-time errors are errors that preclude execution. A compile time
  /// error must be reported by a compiler before the erroneous code is
  /// executed.
  static const compileTimeError =
      ErrorType('COMPILE_TIME_ERROR', 6, ErrorSeverity.error);

  /// Run-time errors are errors that occurred during execution. A run time
  /// error is reported by the interpreter.
  static const runtimeError =
      ErrorType('RUNTIME_ERROR', 7, ErrorSeverity.error);

  /// External errors are errors reported by the dart side.
  static const externalError =
      ErrorType('EXTERNAL_ERROR', 8, ErrorSeverity.error);

  static const values = [
    todo,
    hint,
    lint,
    syntacticError,
    staticTypeWarning,
    staticWarning,
    compileTimeError,
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

class HTError {
  final ErrorCode code;

  String get name => code.toString().split('.').last;

  final ErrorType type;

  ErrorSeverity get severity => type.severity;

  String? message;

  String? correction;

  String? moduleFullName;

  int? line;

  int? column;

  int? offset;

  int? length;

  @override
  String toString() {
    final output = StringBuffer();
    if (moduleFullName != null) {
      output.write('File: $moduleFullName');
      if (line != null && column != null) {
        output.writeln(':$line:$column');
      }
    }
    output.writeln('$type: $name');
    if (message != null) {
      output.write('Message: $message');
    }
    return output.toString();
  }

  /// [HTError] can not be created by default constructor.
  HTError(this.code, this.type,
      {String? message,
      List<String> interpolations = const [],
      this.correction,
      this.moduleFullName,
      this.line,
      this.column,
      this.offset,
      this.length}) {
    if (message != null) {
      for (var i = 0; i < interpolations.length; ++i) {
        message = message!.replaceAll('{$i}', interpolations[i]);
      }
      this.message = message;
    }
  }

  /// Error: Expected a token while met another.
  HTError.unexpected(String expected, String met,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unexpected, ErrorType.syntacticError,
            message: HTLexicon.errorUnexpected,
            interpolations: [expected, met],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: external type is not allowed.
  HTError.externalType(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalType, ErrorType.syntacticError,
            message: HTLexicon.errorExternalType,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Nested class within another nested class.
  HTError.nestedClass(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nestedClass, ErrorType.syntacticError,
            message: HTLexicon.errorNestedClass,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Const variable in a class must be static.
  HTError.constMustBeStatic(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.constMustBeStatic, ErrorType.compileTimeError,
            message: HTLexicon.errorConstMustBeStatic,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Const variable must be initialized.
  HTError.constMustInit(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.constMustInit, ErrorType.compileTimeError,
            message: HTLexicon.errorConstMustInit,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: A same name declaration is already existed.
  HTError.definedParser(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.defined, ErrorType.compileTimeError,
            message: HTLexicon.errorDefined,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal value appeared on left of assignment.
  HTError.invalidLeftValue(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.invalidLeftValue, ErrorType.compileTimeError,
            message: HTLexicon.errorInvalidLeftValue,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Return appeared outside of a function.
  HTError.outsideReturn(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.outsideReturn, ErrorType.syntacticError,
            message: HTLexicon.errorOutsideReturn,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: This appeared outside of a function.
  HTError.outsideThis(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.outsideThis, ErrorType.compileTimeError,
            message: HTLexicon.errorOutsideThis,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal setter declaration.
  HTError.setterArity(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.setterArity, ErrorType.syntacticError,
            message: HTLexicon.errorSetterArity,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal external member.
  HTError.externalMember(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalMember, ErrorType.syntacticError,
            message: HTLexicon.errorExternMember,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Type arguments is emtpy brackets.
  HTError.emptyTypeArgs(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.emptyTypeArgs, ErrorType.syntacticError,
            message: HTLexicon.errorEmptyTypeArgs,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class member.
  HTError.notMember(String id, String className,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notMember, ErrorType.compileTimeError,
            message: HTLexicon.errorNotMember,
            interpolations: [id, className],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class name.
  HTError.notClass(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notClass, ErrorType.compileTimeError,
            message: HTLexicon.errorNotClass,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class name.
  HTError.extendsSelf(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.extendsSelf, ErrorType.syntacticError,
            message: HTLexicon.errorExtendsSelf,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  HTError.ctorReturn(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.ctorReturn, ErrorType.syntacticError,
            message: HTLexicon.errorCtorReturn,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  HTError.abstracted(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.abstracted, ErrorType.compileTimeError,
            message: HTLexicon.errorAbstracted,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  HTError.abstractCtor(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.abstractCtor, ErrorType.compileTimeError,
            message: HTLexicon.errorAbstractCtor,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: unsupported method
  HTError.unsupported(String name,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unsupported, ErrorType.runtimeError,
            message: HTLexicon.errorUnsupported,
            interpolations: [name],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Access private member.
  HTError.unknownOpCode(int opcode,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unknownOpCode, ErrorType.runtimeError,
            message: HTLexicon.errorUnknownOpCode,
            interpolations: [opcode.toString()],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Access private member.
  HTError.privateMember(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.privateMember, ErrorType.runtimeError,
            message: HTLexicon.errorPrivateMember,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Access private declaration.
  HTError.privateDecl(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.privateDecl, ErrorType.runtimeError,
            message: HTLexicon.errorPrivateDecl,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a variable before its initialization.
  HTError.notInitialized(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notInitialized, ErrorType.runtimeError,
            message: HTLexicon.errorNotInitialized,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a undefined variable.
  HTError.undefined(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefined, ErrorType.runtimeError,
            message: HTLexicon.errorUndefined,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a external variable without its binding.
  HTError.undefinedExternal(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedExternal, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedExternal,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to operate unkown type object.
  HTError.unknownTypeName(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unknownTypeName, ErrorType.runtimeError,
            message: HTLexicon.errorUnknownTypeName,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unknown operator.
  HTError.undefinedOperator(String id, String op,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedOperator, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedOperator,
            interpolations: [id, op],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: A same name declaration is already existed.
  HTError.definedRuntime(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.defined, ErrorType.runtimeError,
            message: HTLexicon.errorDefined,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

// HTError.range(int length) { message = '${HTError.errorRange} [$length]';type = HTErrorType.interpreter;
// }

  /// Error: Object is not callable.
  HTError.notCallable(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notCallable, ErrorType.runtimeError,
            message: HTLexicon.errorNotCallable,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Undefined member of a class/enum.
  HTError.undefinedMember(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedMember, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedMember,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: if/while condition expression must be boolean type.
  HTError.condition(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.condition, ErrorType.runtimeError,
            message: HTLexicon.errorCondition,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use sub get operator on a non-list object.
  HTError.notList(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notList, ErrorType.runtimeError,
            message: HTLexicon.errorNotList,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Calling method on null object.
  HTError.errorNullInit(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullInit, ErrorType.runtimeError,
            message: HTLexicon.errorNullInit,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Calling method on null object.
  HTError.nullObject(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullObject, ErrorType.runtimeError,
            message: HTLexicon.errorNullObject,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Type is assign a unnullable varialbe with null.
  HTError.nullable(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullable, ErrorType.runtimeError,
            message: HTLexicon.errorNullable,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Type check failed.
  HTError.type(String id, String valueType, String declValue,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.type, ErrorType.runtimeError,
            message: HTLexicon.errorType,
            interpolations: [id, valueType, declValue],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to assign a immutable variable.
  HTError.immutable(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.immutable, ErrorType.runtimeError,
            message: HTLexicon.errorImmutable,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a type.
  HTError.notType(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notType, ErrorType.runtimeError,
            message: HTLexicon.errorNotType,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Arguments type check failed.
  HTError.argType(String id, String assignType, String declValue,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.argType, ErrorType.runtimeError,
            message: HTLexicon.errorArgType,
            interpolations: [id, assignType, declValue],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Only optional or named arguments can have initializer.
  HTError.argInit(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.argInit, ErrorType.syntacticError,
            message: HTLexicon.errorArgInit,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Return value type check failed.
  HTError.returnType(
      String returnedType, String funcName, String declReturnType,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.returnType, ErrorType.runtimeError,
            message: HTLexicon.errorReturnType,
            interpolations: [returnedType, funcName, declReturnType],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to call a function without definition.
  HTError.missingFuncBody(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.missingFuncBody, ErrorType.syntacticError,
            message: HTLexicon.errorMissingFuncBody,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: String interpolation has to be a single expression.
  HTError.stringInterpolation(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.stringInterpolation, ErrorType.syntacticError,
            message: HTLexicon.errorStringInterpolation,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Function arity check failed.
  HTError.arity(String id, int argsCount, int paramsCount,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.arity, ErrorType.runtimeError,
            message: HTLexicon.errorArity,
            interpolations: [argsCount.toString(), id, paramsCount.toString()],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Missing binding extension on dart object.
  HTError.binding(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.binding, ErrorType.runtimeError,
            message: HTLexicon.errorBinding,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Can not declare a external variable in global namespace.
  HTError.externalVar(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalVar, ErrorType.syntacticError,
            message: HTLexicon.errorExternalVar,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Bytecode signature check failed.
  HTError.bytesSig(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.bytesSig, ErrorType.runtimeError,
            message: HTLexicon.errorBytesSig,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Variable's initialization relies on itself.
  HTError.circleInit(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.circleInit, ErrorType.runtimeError,
            message: HTLexicon.errorCircleInit,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Missing variable initializer.
  HTError.initialize(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.initialize, ErrorType.runtimeError,
            message: HTLexicon.errorInitialize,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Named arguments does not exist.
  HTError.namedArg(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.namedArg, ErrorType.runtimeError,
            message: HTLexicon.errorNamedArg,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Object is not iterable.
  HTError.iterable(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.iterable, ErrorType.runtimeError,
            message: HTLexicon.errorIterable,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unknown value type code
  HTError.unkownValueType(int valType,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unkownValueType, ErrorType.runtimeError,
            message: HTLexicon.errorUnkownValueType,
            interpolations: [valType.toString()],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal empty string.
  HTError.emptyString(
      {ErrorType type = ErrorType.runtimeError,
      String? info,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.emptyString, type,
            message: HTLexicon.errorEmptyString,
            interpolations: info != null ? [info] : const [],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal type cast.
  HTError.typeCast(String object, String type,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.typeCast, ErrorType.runtimeError,
            message: HTLexicon.errorTypeCast,
            interpolations: [object, type],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal castee.
  HTError.castee(String varName,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.castee, ErrorType.runtimeError,
            message: HTLexicon.errorCastee,
            interpolations: [varName],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal clone.
  HTError.clone(String varName,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.clone, ErrorType.runtimeError,
            message: HTLexicon.errorClone,
            interpolations: [varName],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  HTError.notSuper(String classId, String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notSuper, ErrorType.runtimeError,
            message: HTLexicon.errorNotSuper,
            interpolations: [classId, id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.missingExternalFunc(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.missingExternalFunc, ErrorType.runtimeError,
            message: HTLexicon.errorMissingExternalFunc,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.internalFuncWithExternalTypeDef(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.missingExternalFunc, ErrorType.syntacticError,
            message: HTLexicon.errorInternalFuncWithExternalTypeDef,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.externalCtorWithReferCtor(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalCtorWithReferCtor, ErrorType.syntacticError,
            message: HTLexicon.errorExternalCtorWithReferCtor,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.nonCotrWithReferCtor(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nonCotrWithReferCtor, ErrorType.syntacticError,
            message: HTLexicon.errorNonCotrWithReferCtor,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Module import error
  HTError.moduleImport(String id,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.moduleImport, ErrorType.runtimeError,
            message: HTLexicon.errorModuleImport,
            interpolations: [id],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to define a class on a instance.
  HTError.classOnInstance(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.classOnInstance, ErrorType.runtimeError,
            message: HTLexicon.errorClassOnInstance,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Incompatible bytecode version.
  HTError.version(String codeVer, String itpVer,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.version, ErrorType.runtimeError,
            message: HTLexicon.errorVersion,
            interpolations: [codeVer, itpVer],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unevalable source type.
  HTError.sourceType(
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.sourceType, ErrorType.runtimeError,
            message: HTLexicon.errorSourceType,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.nonExistModule(String key, ErrorType type,
      {String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nonExistModule, type,
            message: HTLexicon.errorNonExistModule,
            interpolations: [key],
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);
}
