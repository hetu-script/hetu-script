import 'parse_result.dart';

class HTModuleParseResult {
  final Map<String, HTSourceParseResult> results;

  final bool isScript;

  HTModuleParseResult({required this.results, required this.isScript});
}
