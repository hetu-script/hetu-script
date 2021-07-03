// import '../source/source.dart';
import 'ast_module.dart';

class HTAstCompilation {
  final modules = <String, HTAstModule>{};

  // final sources = <String, HTSource>{};

  final String libraryName;

  HTAstCompilation(this.libraryName);

  void add(HTAstModule module) {
    modules[module.fullName] = module;
    // sources[module.source.fullName] = module.source;
  }

  void addAll(HTAstCompilation compilation) {
    modules.addAll(compilation.modules);
    // sources.addAll(compilation.sources);
  }
}
