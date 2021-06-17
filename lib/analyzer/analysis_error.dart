import '../error/error.dart';
import 'diagnostic.dart';

class HTAnalysisError extends HTError {
  final List<HTDiagnosticMessage> contextMessages;

  HTAnalysisError.fromError(HTError error, {this.contextMessages = const []})
      : super(error.code, error.type,
            message: error.message,
            moduleFullName: error.moduleFullName,
            line: error.line,
            column: error.column,
            offset: error.offset,
            length: error.length);
}
