import '../../source/source.dart';
import '../../ast/ast.dart' show AstNode, ImportDecl;
import '../error/error.dart';
import '../../source/line_info.dart';

/// Contains the resolved fullname of a import statement
class ImportInfo {
  final String fullName;

  final String? alias;

  final List<String>? showList;

  ImportInfo(this.fullName, [this.alias, this.showList]);

  ImportInfo.fromAst(ImportDecl stmt, String fullName)
      : this(fullName, stmt.alias?.id,
            stmt.showList.map((id) => id.id).toList());
}

/// The parse result of a single file
class HTModuleParseResult {
  final HTSource source;

  String get fullName => source.name;

  SourceType get type => source.type;

  LineInfo get lineInfo => source.lineInfo;

  final String? libraryName;

  final bool isLibraryEntry;

  final List<AstNode> nodes;

  final List<ImportDecl> imports;

  final List<HTError> errors;

  HTModuleParseResult(this.source, this.nodes,
      {this.libraryName,
      this.isLibraryEntry = false,
      this.imports = const [],
      this.errors = const []});
}
