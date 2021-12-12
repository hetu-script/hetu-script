import 'package:recase/recase.dart';

import '../grammar/lexicon.dart';
import '../analyzer/analyzer.dart';
import 'error_severity.dart';

part 'error_processor.dart';

enum ErrorCode {
  bytecode,
  version,

  assertionFailed,
  unexpected,
  external,
  nestedClass,
  outsideReturn,
  setterArity,
  externalMember,
  emptyTypeArgs,
  extendsSelf,
  missingFuncBody,
  externalCtorWithReferCtor,
  nonCotrWithReferCtor,
  sourceProviderError,
  notAbsoluteError,
  invalidLeftValue,
  privateMember,
  constMustBeStatic,
  constMustInit,
  duplicateLibStmt,

  defined,
  outsideThis,
  notMember,
  notClass,
  abstracted,
  interfaceCtor,

  unsupported,
  extern,
  unknownOpCode,
  notInitialized,
  undefined,
  undefinedExternal,
  unknownTypeName,
  undefinedOperator,
  notCallable,
  undefinedMember,
  condition,
  nullObject,
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
  binding,
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
  unresolvedNamedStruct
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

  final String? moduleFullName;

  final int? line;

  final int? column;

  final int? offset;

  final int? length;

  @override
  String toString() {
    final output = StringBuffer();
    if (moduleFullName != null) {
      output.writeln('File: $moduleFullName');
      if (line != null && column != null) {
        output.writeln('Line: $line, Column: $column');
      }
    }
    final recase = ReCase(type.name);
    output.writeln('${recase.sentenceCase}: $name');
    output.writeln('Message: $message');
    if (extra != null) {
      output.writeln(extra);
    }
    return output.toString();
  }

  /// [HTError] can not be created by default constructor.
  HTError(this.code, this.type,
      {String? message,
      this.extra,
      List<Object> interpolations = const [],
      this.correction,
      this.moduleFullName,
      this.line,
      this.column,
      this.offset,
      this.length}) {
    if (message != null) {
      for (var i = 0; i < interpolations.length; ++i) {
        message = message!.replaceAll('{$i}', interpolations[i].toString());
      }
      // ignore: prefer_initializing_formals
      _message = message;
    }
  }

  /// Error: Expected a token while met another.
  HTError.unexpected(String expected, String met,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unexpected, ErrorType.syntacticError,
            message: HTLexicon.errorUnexpected,
            interpolations: [expected, met],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: external type is not allowed.
  HTError.external(String semanticName,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.external, ErrorType.syntacticError,
            message: HTLexicon.errorExternal,
            interpolations: [semanticName],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: external constructor on a normal class.
  // HTError.externalCtor(
  //     {String? extra,
  //     String? correction,
  //     String? moduleFullName,
  //     int? line,
  //     int? column,
  //     int? offset,
  //     int? length})
  //     : this(ErrorCode.external, ErrorType.syntacticError,
  //           message: HTLexicon.errorExternalCtor,
  //           extra: extra,
  //           correction: correction,
  //           moduleFullName: moduleFullName,
  //           line: line,
  //           column: column,
  //           offset: offset,
  //           length: length);

  /// Error: Nested class within another nested class.
  HTError.nestedClass(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nestedClass, ErrorType.syntacticError,
            message: HTLexicon.errorNestedClass,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Return appeared outside of a function.
  HTError.outsideReturn(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.outsideReturn, ErrorType.syntacticError,
            message: HTLexicon.errorOutsideReturn,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal setter declaration.
  HTError.setterArity(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.setterArity, ErrorType.syntacticError,
            message: HTLexicon.errorSetterArity,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal external member.
  HTError.externalMember(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalMember, ErrorType.syntacticError,
            message: HTLexicon.errorExternalMember,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Type arguments is emtpy brackets.
  HTError.emptyTypeArgs(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.emptyTypeArgs, ErrorType.syntacticError,
            message: HTLexicon.errorEmptyTypeArgs,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class name.
  HTError.extendsSelf(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.extendsSelf, ErrorType.syntacticError,
            message: HTLexicon.errorExtendsSelf,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  // HTError.voidReturn(
  //     {String? extra,
  //     String? correction,
  //     String? moduleFullName,
  //     int? line,
  //     int? column,
  //     int? offset,
  //     int? length})
  //     : this(ErrorCode.ctorReturn, ErrorType.syntacticError,
  //           message: HTLexicon.errorCtorReturn,
  //           extra: extra,
  //           correction: correction,
  //           moduleFullName: moduleFullName,
  //           line: line,
  //           column: column,
  //           offset: offset,
  //           length: length);

  /// Error: Try to call a function without definition.
  HTError.missingFuncBody(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.missingFuncBody, ErrorType.syntacticError,
            message: HTLexicon.errorMissingFuncBody,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.externalCtorWithReferCtor(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalCtorWithReferCtor, ErrorType.syntacticError,
            message: HTLexicon.errorExternalCtorWithReferCtor,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.nonCotrWithReferCtor(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nonCotrWithReferCtor, ErrorType.syntacticError,
            message: HTLexicon.errorNonCotrWithReferCtor,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Module import error
  HTError.sourceProviderError(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.sourceProviderError, ErrorType.externalError,
            message: HTLexicon.errorSourceProviderError,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Module import error
  HTError.notAbsoluteError(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notAbsoluteError, ErrorType.externalError,
            message: HTLexicon.errorNotAbsoluteError,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal value appeared on left of assignment.
  HTError.invalidLeftValue(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.invalidLeftValue, ErrorType.syntacticError,
            message: HTLexicon.errorInvalidLeftValue,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Access private member.
  HTError.privateMember(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.privateMember, ErrorType.syntacticError,
            message: HTLexicon.errorPrivateMember,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Const variable in a class must be static.
  HTError.constMustBeStatic(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.constMustBeStatic, ErrorType.syntacticError,
            message: HTLexicon.errorConstMustBeStatic,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Const variable must be initialized.
  HTError.constMustInit(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.constMustInit, ErrorType.syntacticError,
            message: HTLexicon.errorConstMustInit,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Duplicate library statement.
  HTError.duplicateLibStmt(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.duplicateLibStmt, ErrorType.syntacticError,
            message: HTLexicon.errorDuplicateLibStmt,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: A same name declaration is already existed.
  HTError.defined(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.defined, ErrorType.compileTimeError,
            message: HTLexicon.errorDefined,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: This appeared outside of a function.
  HTError.outsideThis(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.outsideThis, ErrorType.compileTimeError,
            message: HTLexicon.errorOutsideThis,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class member.
  HTError.notMember(String id, String className,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notMember, ErrorType.compileTimeError,
            message: HTLexicon.errorNotMember,
            interpolations: [id, className],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a class name.
  HTError.notClass(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notClass, ErrorType.compileTimeError,
            message: HTLexicon.errorNotClass,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Cannot create instance from abstract class.
  HTError.abstracted(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.abstracted, ErrorType.compileTimeError,
            message: HTLexicon.errorAbstracted,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Cannot create contructor for interfaces.
  HTError.interfaceCtor(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.interfaceCtor, ErrorType.compileTimeError,
            message: HTLexicon.errorInterfaceCtor,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTError.assertionFailed(String message,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.assertionFailed, ErrorType.runtimeError,
            message: HTLexicon.errorAssertionFailed,
            interpolations: [message],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: unsupported runtime operation
  HTError.unsupported(String name,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unsupported, ErrorType.syntacticError,
            message: HTLexicon.errorUnsupported,
            interpolations: [name],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: dart error
  HTError.extern(String message,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.extern, ErrorType.runtimeError,
            message: message,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Access private member.
  HTError.unknownOpCode(int opcode,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unknownOpCode, ErrorType.runtimeError,
            message: HTLexicon.errorUnknownOpCode,
            interpolations: [opcode],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a variable before its initialization.
  HTError.notInitialized(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notInitialized, ErrorType.runtimeError,
            message: HTLexicon.errorNotInitialized,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a undefined variable.
  HTError.undefined(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefined, ErrorType.runtimeError,
            message: HTLexicon.errorUndefined,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to use a external variable without its binding.
  HTError.undefinedExternal(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedExternal, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedExternal,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to operate unkown type object.
  HTError.unknownExternalTypeName(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unknownTypeName, ErrorType.runtimeError,
            message: HTLexicon.errorUnknownTypeName,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unknown operator.
  HTError.undefinedOperator(String id, String op,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedOperator, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedOperator,
            interpolations: [id, op],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: A same name declaration is already existed.
  HTError.definedRuntime(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.defined, ErrorType.runtimeError,
            message: HTLexicon.errorDefined,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Object is not callable.
  HTError.notCallable(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notCallable, ErrorType.runtimeError,
            message: HTLexicon.errorNotCallable,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Undefined member of a class/enum.
  HTError.undefinedMember(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.undefinedMember, ErrorType.runtimeError,
            message: HTLexicon.errorUndefinedMember,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: if/while condition expression must be boolean type.
  HTError.condition(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.condition, ErrorType.staticWarning,
            message: HTLexicon.errorCondition,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Calling method on null object.
  HTError.nullObject(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullObject, ErrorType.runtimeError,
            message: HTLexicon.errorNullObject,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Subget key is not int
  HTError.subGetKey(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.nullObject, ErrorType.runtimeError,
            message: HTLexicon.errorNullObject,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Calling method on null object.
  HTError.outOfRange(int index, int range,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.outOfRange, ErrorType.runtimeError,
            message: HTLexicon.errorOutOfRange,
            interpolations: [index, range],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Type check failed.
  HTError.assignType(String id, String valueType, String declValue,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.assignType, ErrorType.staticTypeWarning,
            message: HTLexicon.errorAssignType,
            interpolations: [id, valueType, declValue],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Try to assign a immutable variable.
  HTError.immutable(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.immutable, ErrorType.runtimeError,
            message: HTLexicon.errorImmutable,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Symbol is not a type.
  HTError.notType(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notType, ErrorType.runtimeError,
            message: HTLexicon.errorNotType,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Arguments type check failed.
  HTError.argType(String id, String assignType, String declValue,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.argType, ErrorType.runtimeError,
            message: HTLexicon.errorArgType,
            interpolations: [id, assignType, declValue],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Only optional or named arguments can have initializer.
  HTError.argInit(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.argInit, ErrorType.syntacticError,
            message: HTLexicon.errorArgInit,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Return value type check failed.
  HTError.returnType(
      String returnedType, String funcName, String declReturnType,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.returnType, ErrorType.staticTypeWarning,
            message: HTLexicon.errorReturnType,
            interpolations: [returnedType, funcName, declReturnType],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: String interpolation has to be a single expression.
  HTError.stringInterpolation(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.stringInterpolation, ErrorType.syntacticError,
            message: HTLexicon.errorStringInterpolation,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Function arity check failed.
  HTError.arity(String id, int argsCount, int paramsCount,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.arity, ErrorType.staticWarning,
            message: HTLexicon.errorArity,
            interpolations: [argsCount, id, paramsCount],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Missing binding extension on dart object.
  HTError.binding(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.binding, ErrorType.runtimeError,
            message: HTLexicon.errorBinding,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Can not declare a external variable in global namespace.
  HTError.externalVar(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.externalVar, ErrorType.syntacticError,
            message: HTLexicon.errorExternalVar,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Bytecode signature check failed.
  HTError.bytesSig(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.bytesSig, ErrorType.runtimeError,
            message: HTLexicon.errorBytesSig,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Variable's initialization relies on itself.
  HTError.circleInit(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.circleInit, ErrorType.runtimeError,
            message: HTLexicon.errorCircleInit,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Named arguments does not exist.
  HTError.namedArg(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.namedArg, ErrorType.staticTypeWarning,
            message: HTLexicon.errorNamedArg,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Object is not iterable.
  HTError.iterable(String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.iterable, ErrorType.staticTypeWarning,
            message: HTLexicon.errorIterable,
            interpolations: [id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unknown value type code
  HTError.unkownValueType(int valType,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unkownValueType, ErrorType.runtimeError,
            message: HTLexicon.errorUnkownValueType,
            interpolations: [valType],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal type cast.
  HTError.typeCast(String from, String to,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.typeCast, ErrorType.staticTypeWarning,
            message: HTLexicon.errorTypeCast,
            interpolations: [from, to],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Illegal castee.
  HTError.castee(String varName,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.castee, ErrorType.runtimeError,
            message: HTLexicon.errorCastee,
            interpolations: [varName],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Not a super class of this instance.
  HTError.notSuper(String classId, String id,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.notSuper, ErrorType.staticTypeWarning,
            message: HTLexicon.errorNotSuper,
            interpolations: [classId, id],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unrecognizable bytecode.
  HTError.bytecode(
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.bytecode, ErrorType.runtimeError,
            message: HTLexicon.errorBytecode,
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Incompatible bytecode version.
  HTError.version(String codeVer, String itpVer,
      {String? extra,
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.version, ErrorType.runtimeError,
            message: HTLexicon.errorVersion,
            interpolations: [codeVer, itpVer],
            extra: extra,
            correction: correction,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Struct member id should be symbol or string.
  HTError.structMemberId(
      {String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.structMemberId, ErrorType.runtimeError,
            message: HTLexicon.errorStructMemberId,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  /// Error: Unevalable source type.
  HTError.unresolvedNamedStruct(String id,
      {String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length})
      : this(ErrorCode.unresolvedNamedStruct, ErrorType.runtimeError,
            message: HTLexicon.errorUnresolvedNamedStruct,
            interpolations: [id],
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);
}
