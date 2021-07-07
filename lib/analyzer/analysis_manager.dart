import 'package:hetu_script/context/context.dart';
import 'package:hetu_script/parser/parse_result.dart';

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

  final _analysisResults = <String, HTModuleAnalysisResult>{};

  final _parseResults = <String, HTModuleParseResult>{};

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

  HTModuleParseResult? getParseResult(String fullName) {
    final normalized = HTContext.getAbsolutePath(key: fullName);
    return _parseResults[normalized];
  }

  HTModuleAnalysisResult analyze(String fullName) {
    final normalized = HTContext.getAbsolutePath(key: fullName);
    final analyzer = _pathsToAnalyzer[normalized]!;
    final source = contextManager.getSource(normalized)!;
    final result = analyzer.evalSource(source);
    for (final module in analyzer.compilation.modules.values) {
      _parseResults[module.fullName] = module;
    }
    _analysisResults[normalized] = result;
    return result;
  }
}
