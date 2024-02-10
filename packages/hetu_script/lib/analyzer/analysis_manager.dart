import '../ast/ast.dart';
import '../resource/resource_manager.dart';
import '../resource/resource_context.dart';
import '../source/source.dart';
// import '../error/error.dart';
import '../error/error_handler.dart';
import 'analysis_result.dart';
import 'analyzer.dart';
import '../bundler/bundler.dart';
import '../parser/parser_hetu.dart';

class HTAnalysisManager {
  final HTErrorHandlerCallback? errorHandler;

  /// The underlying context manager for analyzer to access to source.
  final HTSourceManager<HTSource, HTResourceContext<HTSource>>
      sourceContextManager;

  final _pathsToAnalyzer = <String, HTAnalyzer>{};

  final _cachedSourceAnalysisResults = <String, HTSourceAnalysisResult>{};

  Iterable<String> get pathsToAnalyze => _pathsToAnalyzer.keys;

  HTAnalysisManager(this.sourceContextManager, {this.errorHandler}) {
    sourceContextManager.onRootsUpdated = () {
      for (final context in sourceContextManager.contexts) {
        final analyzer = HTAnalyzer(sourceContext: context);
        for (final path in context.included) {
          _pathsToAnalyzer[path] = analyzer;
        }
      }
    };
  }

  ASTSource? getParseResult(String fullName) {
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    return _cachedSourceAnalysisResults[fullName]!.parseResult;
  }

  HTSourceAnalysisResult analyze(String fullName) {
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    final analyzer = _pathsToAnalyzer[fullName]!;
    final source = sourceContextManager.getResource(fullName)!;
    final bundler = HTBundler(sourceContext: analyzer.sourceContext);
    final parser = HTParserHetu();
    final compilation = bundler.bundle(source: source, parser: parser);
    final result = analyzer.analyzeCompilation(compilation);
    _cachedSourceAnalysisResults.addAll(result.sourceAnalysisResults);
    return result.sourceAnalysisResults.values.last;
  }
}
