import '../source/source.dart' show HTSource;
import 'ast.dart' show AstNode;

class HTAstModule extends HTSource {
  /// The bytecode, stores as uint8 list
  final List<AstNode> nodes;

  final bool createNamespace;

  HTAstModule(String fullName, String content, this.nodes,
      {this.createNamespace = true})
      : super(fullName, content);
}

class HTAstLibrary {
  final String name;

  HTAstLibrary(this.name);

  final _symbols = <String, AstNode>{};

  Iterable<String> get symbols => _symbols.keys;

  bool containsSymbol(String id) => _symbols.containsKey(id);

  final _modules = <String, HTAstModule>{};

  Iterable<String> get keys => _modules.keys;

  Iterable<HTAstModule> get modules => _modules.values;

  bool containsModule(String fullName) => _modules.containsKey(fullName);

  HTAstModule getModule(String fullName) {
    if (_modules.containsKey(fullName)) {
      return _modules[fullName]!;
    } else {
      throw 'Unknown module: $fullName';
    }
  }

  void add(HTAstModule module) => _modules[module.fullName] = module;

  void join(HTAstLibrary bundle2) {
    _modules.addAll(bundle2._modules);
  }
}
