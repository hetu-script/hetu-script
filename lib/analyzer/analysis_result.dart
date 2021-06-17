part of 'analyzer.dart';

class HTAnalysisResult {
  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTAnalysisResult(this.analyzer, this.errors);
}
