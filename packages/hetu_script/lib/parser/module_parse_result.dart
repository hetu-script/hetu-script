import 'source_parse_result.dart';
import '../resource/resource.dart' show ResourceType;
import '../error/error.dart';

class HTModuleParseResult {
  final Map<String, HTSourceParseResult> values;

  final Map<String, HTSourceParseResult> sources;

  final ResourceType type;

  final List<HTError> errors;

  HTModuleParseResult(
      {required this.values,
      required this.sources,
      required this.type,
      required this.errors});
}
