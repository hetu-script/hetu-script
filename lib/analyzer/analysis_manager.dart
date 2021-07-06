import 'package:hetu_script/context/context.dart';

import '../context/context_manager.dart';
import '../error/error.dart';
import '../context/context.dart';
import 'analysis_result.dart';
import 'analyzer.dart';

class HTAnalysisManager {
  /// The underlying context manager for analyzer to access to source.
  final HTContextManager contextManager;

  final _pathToAnalyzer = <String, HTAnalyzer>{};

  HTAnalysisManager(this.contextManager);

  HTModuleAnalysisResult? analyze(String fullName) {
    final normalized = HTContext.getAbsolutePath(key: fullName);
    if (_pathToAnalyzer.containsKey(normalized)) {
      final analyzer = _pathToAnalyzer[normalized]!;
      final source = contextManager.getSource(normalized)!;
      final result = analyzer.evalSource(source);
      return result;
    } else {
      throw HTError.sourceProviderError(fullName);
    }
  }

  void afterRootsUpdated() {
    for (final context in contextManager.contexts) {
      final analyzer = HTAnalyzer(context: context);
      for (final path in context.included) {
        _pathToAnalyzer[path] = analyzer;
      }
    }
  }
}
