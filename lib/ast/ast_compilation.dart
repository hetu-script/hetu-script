import '../source/source.dart';
import '../error/error.dart';
import 'ast.dart' show AstNode, ImportStmt;

/// Contains the resolved fullname of a import statement
class ImportInfo {
  final String fullName;

  final String? alias;

  final List<String>? showList;

  ImportInfo(this.fullName, [this.alias, this.showList]);

  ImportInfo.fromAst(ImportStmt stmt, String fullName)
      : this(fullName, stmt.alias, stmt.showList);
}

/// The parse result of a single file
class HTAstModule {
  final HTSource source;

  String get fullName => source.fullName;

  /// The bytecode, stores as uint8 list
  final List<AstNode> nodes;

  final SourceType sourceType;

  final List<ImportStmt> imports;

  final bool createNamespace;

  final bool isLibrary;

  final List<HTError> errors;

  HTAstModule(this.source, this.nodes, this.sourceType,
      {this.imports = const [],
      this.createNamespace = true,
      this.isLibrary = false,
      this.errors = const []});
}

class HTAstCompilation {
  final String name;

  HTAstCompilation(this.name);

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

  void join(HTAstCompilation bundle2) {
    _modules.addAll(bundle2._modules);
  }
}
