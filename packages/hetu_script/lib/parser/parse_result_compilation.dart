import 'parse_result.dart';
import '../resource/resource.dart' show ResourceType;

class HTModuleParseResult {
  final Map<String, HTSourceParseResult> results;

  final ResourceType type;

  HTModuleParseResult({required this.results, required this.type});
}
