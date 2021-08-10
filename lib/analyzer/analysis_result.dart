import '../declaration/namespace/library.dart';
import '../parser/parse_result_compilation.dart';
import '../source/source.dart';
import '../source/line_info.dart';
import '../declaration/namespace/module.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTModuleAnalysisResult {
  final HTSource source;
  // HTSource get source => parseResult.source;

  // final HTModuleParseResult parseResult;

  String get fullName => source.fullName;

  LineInfo get lineInfo => source.lineInfo;

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTModuleAnalysisResult(this.source, this.analyzer, this.errors);
}

class HTLibraryAnalysisResult extends HTLibrary {
  final HTModuleParseResultCompilation compilation;

  final Map<String, HTModuleAnalysisResult> modules;

  final List<HTAnalysisError> errors;

  HTLibraryAnalysisResult(
      String libraryName, this.compilation, this.modules, this.errors,
      {Map<String, HTModule>? declarations})
      : super(libraryName, declarations: declarations);
}
