import '../declaration/namespace/library.dart';
import '../parser/parse_result_collection.dart';
import '../source/source.dart';
import '../source/line_info.dart';
import '../declaration/namespace/module.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTModuleAnalysisResult {
  final HTSource source;

  String get fullName => source.fullName;

  LineInfo get lineInfo => source.lineInfo;

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTModuleAnalysisResult(this.source, this.analyzer, this.errors);
}

class HTLibraryAnalysisResult extends HTLibrary {
  final HTModuleParseResultCompilation compilation;

  final Map<String, HTModuleAnalysisResult> modules;

  HTLibraryAnalysisResult(String libraryName, this.compilation, this.modules,
      {Map<String, HTModule>? declarations})
      : super(libraryName, declarations: declarations);
}
