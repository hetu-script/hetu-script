part of 'analyzer.dart';

class ModuleAnalysisResult {
  final HTAstModule module;

  final HTAnalyzer analyzer;

  final errors = <AnalysisError>[];

  ModuleAnalysisResult(this.module, this.analyzer, List<AnalysisError> errors) {
    this.errors.addAll(errors);
  }
}
