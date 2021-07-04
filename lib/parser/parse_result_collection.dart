import 'parse_result.dart';

abstract class HTParseResultCollection {
  Map<String, HTParseResult> get modules;
}

class HTParseResultCompilation implements HTParseResultCollection {
  @override
  final Map<String, HTParseResult> modules;

  HTParseResultCompilation(this.modules);
}

class HTParseContext implements HTParseResultCollection {
  @override
  final modules = <String, HTParseResult>{};

  void add(HTParseResult module) {
    modules[module.fullName] = module;
  }

  void addAll(HTParseResultCollection collection) {
    modules.addAll(collection.modules);
  }
}
