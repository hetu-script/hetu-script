import '../declaration/namespace/declaration_namespace.dart';
import '../source/source.dart';
import '../source/line_info.dart';
import '../ast/ast.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTSourceAnalysisResult {
  final ASTSource parseResult;

  HTSource get source => parseResult.source!;

  String get fullName => source.fullName;

  LineInfo get lineInfo => source.lineInfo;

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  final HTDeclarationNamespace namespace;

  HTSourceAnalysisResult({
    required this.parseResult,
    required this.analyzer,
    required this.errors,
    required this.namespace,
  });
}

class HTModuleAnalysisResult {
  final Map<String, HTSourceAnalysisResult> sourceAnalysisResults;

  final List<HTAnalysisError> errors;

  final ASTCompilation compilation;

  HTModuleAnalysisResult({
    required this.sourceAnalysisResults,
    required this.errors,
    required this.compilation,
  });
}
