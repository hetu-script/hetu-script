import '../error/errors.dart';
import '../source/source.dart';

class AnalysisError extends HTError {
  final HTSource source;

  AnalysisError.fromError(this.source, HTError error)
      : super(error.code, error.type,
            message: error.message,
            moduleFullName: error.moduleFullName,
            line: error.line,
            column: error.column);
}
