import '../context/context_manager.dart';
import 'analysis_result.dart';
import 'analyzer.dart';

class HTAnalysisContextManager extends HTContextManager {
  final _pathToAnalyzer = <String, HTAnalyzer>{};

  HTModuleAnalysisResult? analyze(String fullName) {
    if (_pathToAnalyzer.containsKey(fullName)) {
      final analyzer = _pathToAnalyzer[fullName]!;
      final source = getSource(fullName);
      final result = analyzer.evalSource(source);
      return result;
    } else {
      throw Exception('Could not found context root for file: [$fullName].');
    }
  }

  @override
  void afterRootsUpdated() {
    for (final context in contextRoots.values) {
      final analyzer = HTAnalyzer(context: context);
      for (final path in context.included) {
        _pathToAnalyzer[path] = analyzer;
      }
    }
  }
}
