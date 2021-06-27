import '../declaration/library.dart';
import '../source/source.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTAnalysisResult extends HTLibrary {
  @override
  String toString() => '${errors.length} errors';

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTAnalysisResult(
      String id, Map<String, HTSource> sources, this.analyzer, this.errors)
      : super(id, sources);
}
