import 'package:hetu_script/declaration/namespace/namespace.dart';

import '../source/source.dart';
import '../source/line_info.dart';
import '../parser/parse_result.dart';
import 'analyzer.dart';
import 'analysis_error.dart';

class HTModuleAnalysisResult {
  final HTModuleParseResult parseResult;

  HTSource get source => parseResult.source;

  String get fullName => source.name;

  LineInfo get lineInfo => source.lineInfo;

  final HTAnalyzer analyzer;

  final List<HTAnalysisError> errors;

  final HTNamespace namespace;

  HTModuleAnalysisResult(
      this.parseResult, this.analyzer, this.errors, this.namespace);
}
