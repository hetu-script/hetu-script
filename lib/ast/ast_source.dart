import '../source/source.dart' show HTSource;
import '../error/errors.dart';
import 'ast.dart' show AstNode, ImportStmt;

class ImportInfo {
  final String fullName;

  final String? alias;

  final List<String>? showList;

  ImportInfo(this.fullName, [this.alias, this.showList]);

  ImportInfo.fromAst(ImportStmt stmt, String fullName)
      : this(fullName, stmt.alias, stmt.showList);
}

class HTAstModule extends HTSource {
  /// The bytecode, stores as uint8 list
  final List<AstNode> nodes;

  final List<ImportStmt> imports;

  final bool createNamespace;

  final bool isLibrary;

  final List<HTError> errors;

  HTAstModule(String fullName, String content, this.nodes,
      {this.imports = const [],
      this.createNamespace = true,
      this.isLibrary = false,
      this.errors = const []})
      : super(fullName, content);
}

class HTAstLibrary {
  final String name;

  HTAstLibrary(this.name);

  final _modules = <String, HTAstModule>{};

  Iterable<String> get keys => _modules.keys;

  Iterable<HTAstModule> get modules => _modules.values;

  bool containsModule(String fullName) => _modules.containsKey(fullName);

  HTAstModule getModule(String fullName,
      [ErrorType errorType = ErrorType.runtimeError]) {
    if (_modules.containsKey(fullName)) {
      return _modules[fullName]!;
    } else {
      throw HTError.unknownModule(fullName, errorType);
    }
  }

  void add(HTAstModule module) => _modules[module.fullName] = module;

  void join(HTAstLibrary bundle2) {
    _modules.addAll(bundle2._modules);
  }
}
