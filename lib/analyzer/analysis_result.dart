import '../declaration/library.dart';
import '../source/source.dart';
import '../grammar/semantic.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTAnalysisResult extends HTLibrary {
  @override
  String toString() => '${errors.length} errors';

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTAnalysisResult(this.analyzer, this.errors, Map<String, HTSource> sources)
      : super(SemanticNames.analysisResult, sources);
}
