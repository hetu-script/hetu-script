import '../context/context_manager.dart';
import 'analysis_result.dart';
import 'analyzer.dart';

class HTAnalysisContextManager {
  /// The underlying context manager for analyzer to access to source.
  final HTContextManager contextManager;

  final _pathToAnalyzer = <String, HTAnalyzer>{};

  HTAnalysisContextManager(this.contextManager);

  HTModuleAnalysisResult? analyze(String fullName) {
    if (_pathToAnalyzer.containsKey(fullName)) {
      final analyzer = _pathToAnalyzer[fullName]!;
      final source = contextManager.getSource(fullName);
      final result = analyzer.evalSource(source);
      return result;
    } else {
      throw Exception('Could not found context root for file: [$fullName].');
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
