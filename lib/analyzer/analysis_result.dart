import 'package:hetu_script/declaration/namespace/module.dart';

import '../declaration/namespace/library.dart';
import '../parser/parse_result_collection.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTModuleAnalysisResult {
  final String fullName;

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  HTModuleAnalysisResult(this.fullName, this.analyzer, this.errors);
}

class HTLibraryAnalysisResult extends HTLibrary {
  final HTParseContext compilation;

  final Map<String, HTModuleAnalysisResult> modules;

  HTLibraryAnalysisResult(String libraryName, this.compilation, this.modules,
      {Map<String, HTModule>? declarations})
      : super(libraryName, declarations: declarations);
}
