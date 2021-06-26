import '../declaration/namespace.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTAnalysisResult extends HTNamespace {
  @override
  String toString() => '${errors.length} errors';

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTAnalysisResult(this.analyzer, this.errors);
}
