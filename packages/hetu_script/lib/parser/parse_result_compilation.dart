import 'parse_result.dart';

class HTModuleParseResultCompilation {
  final Map<String, HTModuleParseResult> modules;

  final bool isScript;

  HTModuleParseResultCompilation(
      {required this.modules, required this.isScript});
}
