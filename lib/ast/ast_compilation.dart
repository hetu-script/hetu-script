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

  final bool hasOwnNamespace;

  final bool isLibrary;

  final List<HTError> errors;

  HTAstModule(this.source, this.nodes, this.sourceType,
      {this.imports = const [],
      this.hasOwnNamespace = true,
      this.isLibrary = false,
      this.errors = const []});
}

class HTAstCompilation {
  final modules = <String, HTAstModule>{};

  void add(HTAstModule module) => modules[module.fullName] = module;

  void join(HTAstCompilation bundle2) {
    modules.addAll(bundle2.modules);
  }
}
