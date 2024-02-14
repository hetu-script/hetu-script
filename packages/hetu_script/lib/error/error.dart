import '../locale/locale.dart';
import '../analyzer/analyzer.dart';
import 'error_severity.dart';

part 'error_processor.dart';

enum ErrorCode {
  // Syntactic errors
  unkownSourceType,
  importListOnNonHetuSource,
  exportNonHetuSource,
  scriptThrows,
  assertionFailed,
  unexpectedToken,
  unexpected,
  delete,
  external,
  nestedClass,
  constInClass,
  misplacedThis,
  misplacedSuper,
  misplacedReturn,
  misplacedContinue,
  misplacedBreak,
  setterArity,
  unexpectedEmptyList,
  extendsSelf,
  missingFuncBody,
  externalCtorWithReferCtor,
  resourceDoesNotExist,
  sourceProviderError,
  notAbsoluteError,
  invalidDeclTypeOfValue,
  invalidLeftValue,
  awaitWithoutAsync,
  nullableAssign,
  privateMember,
  constMustInit,
  awaitExpression,
  getterParam,

  defined,
  outsideThis,
  notMember,
  notClass,
  abstracted,
  abstractFunction,
  interfaceCtor,
  unsupported,

  // Runtime errors
  bytecode,
  version,
  extern,
  unknownOpCode,
  notInitialized,
  undefined,
  undefinedExternal,
  unknownTypeName,
  undefinedOperator,
  notNewable,
  notCallable,
  undefinedMember,
  uninitialized,
  condition,
  nullObject,
  nullSubSetKey,
  subGetKey,
  outOfRange,
  assignType,
  immutable,
  notType,
  argType,
  argInit,
  returnType,
  stringInterpolation,
  arity,
  externalVar,
  bytesSig,
  circleInit,
  namedArg,
  iterable,
  unkownValueType,
  typeCast,
  castee,
  notSuper,
  structMemberId,
  unresolvedNamedStruct,
  binding,
  notStruct,

  // Analysis errors
  constValue,
  importSelf,
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
      ErrorType('TYPE_WARNING', 4, ErrorSeverity.warning);

  /// Reported by analyzer.
  static const staticWarning =
      ErrorType('STATIC_WARNING', 5, ErrorSeverity.warning);

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
  bool operator ==(Object other) {
    return other is HTError && hashCode == other.hashCode;
  }

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

  String? _message;

  String? get message => _message;

  final String? extra;

  final String? correction;

  final String? filename;

  final int? line;

  final int? column;

  final int? offset;

  final int? length;

  @override
  String toString() {
    final output = StringBuffer();
    if (filename != null) {
      output.writeln('${HTLocale.current.file}: $filename');
      if (line != null && column != null) {
        output.writeln(
            '${HTLocale.current.line}: $line, ${HTLocale.current.column}: $column');
      }
    }
    output.writeln(
        '${HTLocale.current.errorType}: ${HTLocale.current.getErrorType(type.name)}($name)');
    output.writeln('${HTLocale.current.message}: $message');
    if (extra != null) {
      output.writeln(extra);
    }
    return output.toString();
  }

  /// [HTError] can not be created by default constructor.
  HTError(this.code, this.type,
      {String? message,
      this.extra,
      List interpolations = const [],
      this.correction,
      this.filename,
      this.line,
      this.column,
      this.offset,
      this.length}) {
    if (message != null) {
      for (var i = 0; i < interpolations.length; ++i) {
        message = message!.replaceAll('{$i}', interpolations[i].toString());
      }
      _message = message;
    }
  }

  HTError.unkownSourceType(String ext,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unkownSourceType, ErrorType.syntacticError,
            message: HTLocale.current.errorUnkownSourceType,
            interpolations: [ext],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.importListOnNonHetuSource(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.importListOnNonHetuSource, ErrorType.syntacticError,
            message: HTLocale.current.errorUnkownSourceType,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.exportNonHetuSource(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.exportNonHetuSource, ErrorType.syntacticError,
            message: HTLocale.current.errorExportNonHetuSource,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Expected a token while met another.
  HTError.unexpectedToken(String expected, String met,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unexpected, ErrorType.syntacticError,
            message: HTLocale.current.errorUnexpectedToken,
            interpolations: [expected, met],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Expected a token while met another.
  HTError.unexpected(String whileParsing, String expected, String met,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unexpected, ErrorType.syntacticError,
            message: HTLocale.current.errorUnexpected,
            interpolations: [whileParsing, expected, met],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Can only delete a identifier.
  HTError.delete(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.delete, ErrorType.syntacticError,
            message: HTLocale.current.errorDelete,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: external type is not allowed.
  HTError.external(String semanticName,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.external, ErrorType.syntacticError,
            message: HTLocale.current.errorExternal,
            interpolations: [semanticName],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: external constructor on a normal class.
  // HTError.externalCtor(
  //     {String? extra,
  //     String? correction,
  //     String? filename,
  //     int? line,
  //     int? column,
  //     int? offset,
  //     int? length})
  //     : this(ErrorCode.external, ErrorType.syntacticError,
  //           message: HTLocale.current.errorExternalCtor,
  //           extra: extra,
  //           correction: correction,
  //           filename: filename,
  //           line: line,
  //           column: column,
  //           offset: offset,
  //           length: length);

  /// Error: Nested class within another nested class.
  HTError.nestedClass(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nestedClass, ErrorType.syntacticError,
            message: HTLocale.current.errorNestedClass,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Const value in class must be also static.
  HTError.constInClass(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.constInClass, ErrorType.syntacticError,
            message: HTLocale.current.errorConstInClass,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: this appeared outside of a instance method.
  HTError.misplacedThis(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.misplacedThis, ErrorType.syntacticError,
            message: HTLocale.current.errorMisplacedThis,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: super appeared outside of a inherited class's instance method.
  HTError.misplacedSuper(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.misplacedSuper, ErrorType.syntacticError,
            message: HTLocale.current.errorMisplacedSuper,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Return appeared outside of a function.
  HTError.misplacedReturn(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.misplacedReturn, ErrorType.syntacticError,
            message: HTLocale.current.errorMisplacedReturn,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Continue appeared outside of a function.
  HTError.misplacedContinue(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.misplacedContinue, ErrorType.syntacticError,
            message: HTLocale.current.errorMisplacedContinue,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Break appeared outside of a loop.
  HTError.misplacedBreak(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.misplacedBreak, ErrorType.syntacticError,
            message: HTLocale.current.errorMisplacedBreak,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal setter declaration.
  HTError.setterArity(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.setterArity, ErrorType.syntacticError,
            message: HTLocale.current.errorSetterArity,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Type arguments is emtpy brackets.
  HTError.unexpectedEmptyList(String listName,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unexpectedEmptyList, ErrorType.syntacticError,
            message: HTLocale.current.errorUnexpectedEmptyList,
            interpolations: [listName],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class name.
  HTError.extendsSelf(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.extendsSelf, ErrorType.syntacticError,
            message: HTLocale.current.errorExtendsSelf,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  // HTError.voidReturn(
  //     {String? extra,
  //     String? correction,
  //     String? filename,
  //     int? line,
  //     int? column,
  //     int? offset,
  //     int? length})
  //     : this(ErrorCode.ctorReturn, ErrorType.syntacticError,
  //           message: HTLocale.current.errorCtorReturn,
  //           extra: extra,
  //           correction: correction,
  //           filename: filename,
  //           line: line,
  //           column: column,
  //           offset: offset,
  //           length: length);

  /// Error: Try to call a function without definition.
  HTError.missingFuncBody(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.missingFuncBody, ErrorType.syntacticError,
            message: HTLocale.current.errorMissingFuncBody,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.externalCtorWithReferCtor(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalCtorWithReferCtor, ErrorType.syntacticError,
            message: HTLocale.current.errorExternalCtorWithReferCtor,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Resource does not exit.
  HTError.resourceDoesNotExist(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.resourceDoesNotExist, ErrorType.externalError,
            message: HTLocale.current.errorResourceDoesNotExist,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Module import error
  HTError.sourceProviderError(String id, String from,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.sourceProviderError, ErrorType.externalError,
            message: HTLocale.current.errorSourceProviderError,
            interpolations: [id, from],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Module import error
  HTError.notAbsoluteError(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notAbsoluteError, ErrorType.externalError,
            message: HTLocale.current.errorNotAbsoluteError,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Cannot ssign to a nullable value.
  HTError.nullableAssign(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullableAssign, ErrorType.syntacticError,
            message: HTLocale.current.errorNullableAssign,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal value appeared on left of assignment.
  HTError.invalidDeclTypeOfValue(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.invalidDeclTypeOfValue, ErrorType.syntacticError,
            message: HTLocale.current.errorInvalidDeclTypeOfValue,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Await appeared outside an async function.
  HTError.awaitWithoutAsync({
    String? extra,
    String? correction,
    String? filename,
    int? line,
    int? column,
    int? offset,
    int? length,
  }) : this(
          ErrorCode.awaitWithoutAsync,
          ErrorType.syntacticError,
          message: HTLocale.current.errorAwaitWithoutAsync,
          extra: extra,
          correction: correction,
          filename: filename,
          line: line,
          column: column,
          offset: offset,
          length: length,
        );

  /// Error: Illegal value appeared on left of assignment.
  HTError.invalidLeftValue(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.invalidLeftValue, ErrorType.syntacticError,
            message: HTLocale.current.errorInvalidLeftValue,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Access private member.
  HTError.privateMember(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.privateMember, ErrorType.syntacticError,
            message: HTLocale.current.errorPrivateMember,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Const variable must be initialized.
  HTError.constMustInit(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.constMustInit, ErrorType.syntacticError,
            message: HTLocale.current.errorConstMustInit,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal await expression appeared outside of async function.
  HTError.awaitExpression(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.awaitExpression, ErrorType.syntacticError,
            message: HTLocale.current.errorAwaitExpression,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Getter should have empty parameters list.
  HTError.getterParam(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.getterParam, ErrorType.syntacticError,
            message: HTLocale.current.errorGetterParam,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: A same name declaration is already existed.
  HTError.defined(String id, ErrorType type,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.defined, type,
            message: HTLocale.current.errorDefined,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: A same name declaration is already existed.
  HTError.definedImportSymbol(String id, String from, String exist,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.defined, ErrorType.runtimeError,
            message: HTLocale.current.errorDefinedImportSymbol,
            interpolations: [id, from, exist],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: This appeared outside of a function.
  HTError.outsideThis(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.outsideThis, ErrorType.compileTimeError,
            message: HTLocale.current.errorOutsideThis,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class member.
  HTError.notMember(String id, String className,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notMember, ErrorType.compileTimeError,
            message: HTLocale.current.errorNotMember,
            interpolations: [id, className],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class name.
  HTError.notClass(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notClass, ErrorType.compileTimeError,
            message: HTLocale.current.errorNotClass,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Cannot create instance from abstract class.
  HTError.abstracted(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.abstracted, ErrorType.compileTimeError,
            message: HTLocale.current.errorAbstracted,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Cannot call an abstract function.
  HTError.abstractFunction(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.abstractFunction, ErrorType.compileTimeError,
            message: HTLocale.current.errorAbstractFunction,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: unsupported runtime operation
  HTError.unsupported(String name, String version,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unsupported, ErrorType.syntacticError,
            message: HTLocale.current.errorUnsupported,
            interpolations: [name, version],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.scriptThrows(Object message,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.scriptThrows, ErrorType.runtimeError,
            message: message.toString(),
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.assertionFailed(String message,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.assertionFailed, ErrorType.runtimeError,
            message: HTLocale.current.errorAssertionFailed,
            interpolations: [message],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: dart error
  HTError.extern(String message,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.extern, ErrorType.runtimeError,
            message: message,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Access private member.
  HTError.unknownOpCode(int opcode,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unknownOpCode, ErrorType.runtimeError,
            message: HTLocale.current.errorUnknownOpCode,
            interpolations: [opcode],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a variable before its initialization.
  HTError.notInitialized(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notInitialized, ErrorType.runtimeError,
            message: HTLocale.current.errorNotInitialized,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a undefined variable.
  HTError.undefined(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefined, ErrorType.runtimeError,
            message: HTLocale.current.errorUndefined,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a external variable without its binding.
  HTError.undefinedExternal(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedExternal, ErrorType.runtimeError,
            message: HTLocale.current.errorUndefinedExternal,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to operate unkown type object.
  HTError.unknownExternalTypeName(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unknownTypeName, ErrorType.runtimeError,
            message: HTLocale.current.errorUnknownTypeName,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unknown operator.
  HTError.undefinedOperator(String id, String op,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedOperator, ErrorType.runtimeError,
            message: HTLocale.current.errorUndefinedOperator,
            interpolations: [id, op],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Can not use new on this.
  HTError.notNewable(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notNewable, ErrorType.runtimeError,
            message: HTLocale.current.errorNotNewable,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Object is not callable.
  HTError.notCallable(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notCallable, ErrorType.runtimeError,
            message: HTLocale.current.errorNotCallable,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Undefined member of a class/enum.
  HTError.undefinedMember(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedMember, ErrorType.runtimeError,
            message: HTLocale.current.errorUndefinedMember,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Undefined member of a class/enum.
  HTError.uninitialized(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.uninitialized, ErrorType.runtimeError,
            message: HTLocale.current.errorUninitialized,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: if/while condition expression must be boolean type.
  HTError.condition(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.condition, ErrorType.staticWarning,
            message: HTLocale.current.errorCondition,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Calling method on null object.
  HTError.nullObject(String symbol, String method,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullObject, ErrorType.runtimeError,
            message: HTLocale.current.errorNullObject,
            interpolations: [symbol, method],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.nullSubSetKey(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullSubSetKey, ErrorType.runtimeError,
            message: HTLocale.current.errorNullSubSetKey,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Subget key is not int
  HTError.subGetKey(dynamic key,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.subGetKey, ErrorType.runtimeError,
            message: HTLocale.current.errorSubGetKey,
            interpolations: [key],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Calling method on null object.
  HTError.outOfRange(int index, int range,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.outOfRange, ErrorType.runtimeError,
            message: HTLocale.current.errorOutOfRange,
            interpolations: [index, range],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Type check failed.
  HTError.assignType(String id, String valueType, String declValue,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.assignType, ErrorType.staticTypeWarning,
            message: HTLocale.current.errorAssignType,
            interpolations: [id, valueType, declValue],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to assign a immutable variable.
  HTError.immutable(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.immutable, ErrorType.runtimeError,
            message: HTLocale.current.errorImmutable,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a type.
  HTError.notType(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notType, ErrorType.runtimeError,
            message: HTLocale.current.errorNotType,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Arguments type check failed.
  HTError.argType(String id, String assignType, String declValue,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.argType, ErrorType.runtimeError,
            message: HTLocale.current.errorArgType,
            interpolations: [id, assignType, declValue],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Only optional or named arguments can have initializer.
  HTError.argInit(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.argInit, ErrorType.syntacticError,
            message: HTLocale.current.errorArgInit,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Return value type check failed.
  HTError.returnType(
      String returnedType, String funcName, String declReturnType,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.returnType, ErrorType.staticTypeWarning,
            message: HTLocale.current.errorReturnType,
            interpolations: [returnedType, funcName, declReturnType],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: String interpolation has to be a single expression.
  HTError.stringInterpolation(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.stringInterpolation, ErrorType.syntacticError,
            message: HTLocale.current.errorStringInterpolation,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Function arity check failed.
  HTError.arity(String id, int argsCount, int paramsCount,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.arity, ErrorType.staticWarning,
            message: HTLocale.current.errorArity,
            interpolations: [argsCount, id, paramsCount],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Can not declare a external variable in global namespace.
  HTError.externalVar(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalVar, ErrorType.syntacticError,
            message: HTLocale.current.errorExternalVar,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Bytecode signature check failed.
  HTError.bytesSig(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.bytesSig, ErrorType.runtimeError,
            message: HTLocale.current.errorBytesSig,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Variable's initialization relies on itself.
  HTError.circleInit(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.circleInit, ErrorType.runtimeError,
            message: HTLocale.current.errorCircleInit,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Named arguments does not exist.
  HTError.namedArg(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.namedArg, ErrorType.staticTypeWarning,
            message: HTLocale.current.errorNamedArg,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Object is not iterable.
  HTError.iterable(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.iterable, ErrorType.staticTypeWarning,
            message: HTLocale.current.errorIterable,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unknown value type code
  HTError.unkownValueType(int valType,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unkownValueType, ErrorType.runtimeError,
            message: HTLocale.current.errorUnkownValueType,
            interpolations: [valType],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal type cast.
  HTError.typeCast(String from, String to,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.typeCast, ErrorType.staticTypeWarning,
            message: HTLocale.current.errorTypeCast,
            interpolations: [from, to],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal castee.
  HTError.castee(String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.castee, ErrorType.runtimeError,
            message: HTLocale.current.errorCastee,
            interpolations: [id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  HTError.notSuper(String classId, String id,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notSuper, ErrorType.staticTypeWarning,
            message: HTLocale.current.errorNotSuper,
            interpolations: [classId, id],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unrecognizable bytecode.
  HTError.bytecode(
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.bytecode, ErrorType.runtimeError,
            message: HTLocale.current.errorBytecode,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Incompatible bytecode version.
  HTError.version(String codeVer, String itpVer,
      {String? extra,
      String? correction,
      String? filename,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.version, ErrorType.runtimeError,
            message: HTLocale.current.errorVersion,
            interpolations: [codeVer, itpVer],
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Struct member id should be symbol or string.
  HTError.structMemberId(String met,
      {String? filename, int? line, int? column, int? offset, int? length})
      : this(ErrorCode.structMemberId, ErrorType.runtimeError,
            message: HTLocale.current.errorStructMemberId,
            interpolations: [met],
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unevalable source type.
  HTError.unresolvedNamedStruct(String id,
      {String? filename, int? line, int? column, int? offset, int? length})
      : this(ErrorCode.unresolvedNamedStruct, ErrorType.runtimeError,
            message: HTLocale.current.errorUnresolvedNamedStruct,
            interpolations: [id],
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Bind a non literal function is not allowed.
  HTError.binding(
      {String? filename, int? line, int? column, int? offset, int? length})
      : this(ErrorCode.binding, ErrorType.runtimeError,
            message: HTLocale.current.errorBinding,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Bind a non literal function is not allowed.
  HTError.notStruct(
      {String? filename, int? line, int? column, int? offset, int? length})
      : this(ErrorCode.notStruct, ErrorType.runtimeError,
            message: HTLocale.current.errorNotStruct,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);
}
