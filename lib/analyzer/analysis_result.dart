import '../source/source.dart';
import '../declaration/library.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTModuleAnalysisResult extends HTSource {
  @override
  String toString() => '${errors.length} errors';

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTModuleAnalysisResult(String content, this.analyzer, this.errors,
      {String? fullName})
      : super(content, fullName: fullName);
}

class HTLibraryAnalysisResult extends HTLibrary {
  final modules = <String, HTModuleAnalysisResult>{};

  HTLibraryAnalysisResult(String id) : super(id);
}
