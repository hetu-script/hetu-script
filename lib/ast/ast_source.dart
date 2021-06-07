import '../source/source.dart' show HTSource;
import 'ast.dart' show AstNode, ImportStmt;

class ImportInfo {
  final String key;

  final String fullName;

  final String? alias;

  final List<String>? showList;

  ImportInfo(this.key, this.fullName, [this.alias, this.showList]);

  ImportInfo.fromAst(ImportStmt stmt, String fullName)
      : this(stmt.key, fullName, stmt.alias, stmt.showList);
}

class HTAstModule extends HTSource {
  /// The bytecode, stores as uint8 list
  final List<AstNode> nodes;

  final List<ImportInfo> imports;

  final bool createNamespace;

  final bool isLibrary;

  HTAstModule(String fullName, String content, this.nodes, this.imports,
      {this.createNamespace = true, this.isLibrary = false})
      : super(fullName, content);
}

class HTAstLibrary {
  final String name;

  HTAstLibrary(this.name);

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
