import 'package:hetu_script/ast/ast.dart';

import '../ast/ast.dart';
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
  final HTSourceManager<HTSource, HTResourceContext<HTSource>>
      sourceContextManager;

  final _pathsToAnalyzer = <String, HTAnalyzer>{};

  final _analysisResults = <String, HTModuleAnalysisResult>{};

  final _parseResults = <String, AstCompilationUnit>{};

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

  AstCompilationUnit? getParseResult(String fullName) {
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    return _parseResults[fullName];
  }

  HTModuleAnalysisResult analyze(String fullName) {
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    final analyzer = _pathsToAnalyzer[fullName]!;
    final source = sourceContextManager.getResource(fullName)!;
    final result = analyzer.evalSource(source);
    for (final result in analyzer.compilation.sources.values) {
      _parseResults[result.fullName] = result;
    }
    _analysisResults[fullName] = result;
    return result;
  }
}
