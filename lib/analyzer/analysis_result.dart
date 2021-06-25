import '../declaration/namespace.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTAnalysisResult extends HTNamespace implements HTErrorHandler {
  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  @override
  void handle(HTError error) {
    final analysisError = HTAnalysisError.fromError(error);
    errors.add(analysisError);
  }

  HTAnalysisResult(this.analyzer, this.errors);
}
