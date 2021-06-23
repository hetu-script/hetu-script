import 'analyzer.dart';
import 'analysis_error.dart';
import '../element/namespace.dart';

class HTAnalysisResult extends HTNamespace {
  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTAnalysisResult(this.analyzer, this.errors);
}
