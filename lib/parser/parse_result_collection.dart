import 'parse_result.dart';

abstract class HTModuleParseResultCollection {
  Map<String, HTModuleParseResult> get modules;
}

class HTModuleParseResultCompilation implements HTModuleParseResultCollection {
  @override
  final Map<String, HTModuleParseResult> modules;

  HTModuleParseResultCompilation(this.modules);
}
