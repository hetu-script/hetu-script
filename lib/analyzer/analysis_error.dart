import '../error/error.dart';
import 'diagnostic.dart';

class HTAnalysisError extends HTError {
  final List<HTDiagnosticMessage> contextMessages;

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

  HTAnalysisError(ErrorCode code, ErrorType type, String message,
      {List<String> interpolations = const [],
      String? correction,
      required this.moduleFullName,
      required this.line,
      required this.column,
      this.offset = 0,
      this.length = 0,
      this.contextMessages = const []})
      : super(code, type, message,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTAnalysisError.fromError(HTError error,
      {List<HTDiagnosticMessage> contextMessages = const []})
      : this(error.code, error.type, error.message,
            correction: error.correction,
            moduleFullName: error.moduleFullName!,
            line: error.line!,
            column: error.column!,
            offset: error.offset!,
            length: error.length!,
            contextMessages: contextMessages);
}
