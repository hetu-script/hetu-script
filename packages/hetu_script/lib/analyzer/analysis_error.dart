import '../error/error.dart';
import '../error/error_severity.dart';
import 'diagnostic.dart';

class HTAnalysisError implements HTError {
  @override
  final ErrorCode code;

  @override
  String get name => code.toString().split('.').last;

  @override
  final ErrorType type;

  @override
  ErrorSeverity get severity => type.severity;

  @override
  final String? message;

  @override
  final String? extra;

  @override
  final String? correction;

  @override
  final String moduleFullName;

  @override
  final int line;

  @override
  final int column;

  @override
  final int offset;

  @override
  final int length;

  final List<HTDiagnosticMessage> contextMessages;

  HTAnalysisError(this.code, this.type,
      {this.message,
      this.extra,
      List<String> interpolations = const [],
      this.correction,
      required this.moduleFullName,
      required this.line,
      required this.column,
      this.offset = 0,
      this.length = 0,
      this.contextMessages = const []});

  HTAnalysisError.fromError(HTError error,
      {List<HTDiagnosticMessage> contextMessages = const []})
      : this(error.code, error.type,
            message: error.message,
            correction: error.correction,
            moduleFullName: error.moduleFullName!,
            line: error.line!,
            column: error.column!,
            offset: error.offset!,
            length: error.length!,
            contextMessages: contextMessages);
}
