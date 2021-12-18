import 'parse_result.dart';
import '../resource/resource.dart' show ResourceType;

class HTModuleParseResult {
  final Map<String, HTSourceParseResult> values;

  final Map<String, HTSourceParseResult> sources;

  final ResourceType type;

  HTModuleParseResult(
      {required this.values, required this.sources, required this.type});
}
