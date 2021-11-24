import '../parser/parse_result.dart';
import '../resource/resource_manager.dart';
import '../resource/resource_context.dart';
import '../source/source.dart';
// import '../error/error.dart';
import '../error/error_handler.dart';
import 'analysis_result.dart';
import 'analyzer.dart';

class HTAnalysisManager {
  final HTErrorHandlerCallback? errorHandler;

  /// The underlying context manager for analyzer to access to source.
  final HTResourceManager<HTResourceContext<HTSource>> sourceContextManager;

  final _pathsToAnalyzer = <String, HTAnalyzer>{};

  final _analysisResults = <String, HTModuleAnalysisResult>{};

  final _parseResults = <String, HTModuleParseResult>{};

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

  HTModuleParseResult? getParseResult(String fullName) {
    final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    return _parseResults[normalized];
  }

  HTModuleAnalysisResult analyze(String fullName) {
    final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    final analyzer = _pathsToAnalyzer[normalized]!;
    final source = sourceContextManager.getResource(normalized)!;
    final result = analyzer.evalSource(source);
    for (final module in analyzer.compilation.modules.values) {
      _parseResults[module.fullName] = module;
    }
    _analysisResults[normalized] = result;
    return result;
  }
}
