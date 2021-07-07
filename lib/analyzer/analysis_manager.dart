import 'package:hetu_script/context/context.dart';

import '../context/context_manager.dart';
// import '../error/error.dart';
import '../error/error_handler.dart';
import '../context/context.dart';
import 'analysis_result.dart';
import 'analyzer.dart';

class HTAnalysisManager {
  final HTErrorHandlerCallback? errorHandler;

  /// The underlying context manager for analyzer to access to source.
  final HTContextManager contextManager;

  final _pathsToAnalyzer = <String, HTAnalyzer>{};

  Iterable<String> get pathsToAnalyze => _pathsToAnalyzer.keys;

  HTAnalysisManager(this.contextManager, {this.errorHandler}) {
    contextManager.onRootsUpdated = () {
      for (final context in contextManager.contexts) {
        final analyzer = HTAnalyzer(context: context);
        for (final path in context.included) {
          _pathsToAnalyzer[path] = analyzer;
        }
      }
    };
  }

  HTModuleAnalysisResult? analyze(String fullName) {
    final normalized = HTContext.getAbsolutePath(key: fullName);
    if (_pathsToAnalyzer.containsKey(normalized)) {
      final analyzer = _pathsToAnalyzer[normalized]!;
      try {
        final source = contextManager.getSource(normalized)!;
        final result = analyzer.evalSource(source);
        return result;
      } catch (error, stackTrace) {
        if (errorHandler != null) {
          errorHandler!(error, externalStackTrace: stackTrace);
        } else {
          rethrow;
        }
      }
    } else {
      throw 'Could not find analyzer for: [$normalized]\nCurrent analyzers:\n$_pathsToAnalyzer';
    }
  }
}
