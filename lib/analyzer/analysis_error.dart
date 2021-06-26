import '../error/error.dart';
import 'diagnostic.dart';

class HTAnalysisError extends HTError {
  final List<HTDiagnosticMessage> contextMessages;

  HTAnalysisError(ErrorCode code, ErrorType type,
      {String message = '',
      List<String> interpolations = const [],
      String? correction,
      String? moduleFullName,
      int? line,
      int? column,
      int? offset,
      int? length,
      this.contextMessages = const []})
      : super(code, type,
            message: message,
            moduleFullName: moduleFullName,
            line: line,
            column: column,
            offset: offset,
            length: length);

  HTAnalysisError.fromError(HTError error, {this.contextMessages = const []})
      : super(error.code, error.type,
            message: error.message,
            moduleFullName: error.moduleFullName,
            line: error.line,
            column: error.column,
            offset: error.offset,
            length: error.length);
}
