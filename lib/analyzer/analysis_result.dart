import '../source/source.dart';
import '../declaration/namespace/library.dart';
import '../declaration/namespace/namespace.dart';
import '../ast/ast_compilation.dart';
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
  final HTAstCompilation compilation;

  final Map<String, HTModuleAnalysisResult> modules;

  HTLibraryAnalysisResult(this.compilation, this.modules,
      {Map<String, HTNamespace>? declarations})
      : super(compilation.libraryName, declarations: declarations);
}
