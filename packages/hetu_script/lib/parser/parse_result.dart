import '../../source/source.dart';
import '../../ast/ast.dart' show AstNode, ImportExportDecl;
import '../error/error.dart';
import '../../source/line_info.dart';

/// Contains the resolved fullname of a import statement
class ImportInfo {
  final String fullName;

  final String? alias;

  final List<String>? showList;

  ImportInfo(this.fullName, [this.alias, this.showList]);

  ImportInfo.fromAst(ImportExportDecl stmt, String fullName)
      : this(fullName, stmt.alias?.id,
            stmt.showList.map((id) => id.id).toList());
}

/// The parse result of a single file
class HTModuleParseResult {
  final HTSource source;

  String get fullName => source.name;

  bool get isScript => source.isScript;

  LineInfo get lineInfo => source.lineInfo;

  final String? libraryName;

  final bool isLibraryEntry;

  final List<AstNode> nodes;

  final List<ImportExportDecl> imports;

  final List<HTError> errors;

  HTModuleParseResult(this.source, this.nodes,
      {this.libraryName,
      this.isLibraryEntry = false,
      this.imports = const [],
      this.errors = const []});
}
