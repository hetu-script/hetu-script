import '../../source/source.dart';
import '../../ast/ast.dart' show AstNode, ImportExportDecl;
import '../error/error.dart';
import '../../source/line_info.dart';
import '../../resource/resource.dart';

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
class HTSourceParseResult {
  final HTSource source;

  String get fullName => source.name;

  ResourceType get type => source.type;

  LineInfo get lineInfo => source.lineInfo;

  final List<AstNode> nodes;

  final List<ImportExportDecl> imports;

  final List<HTError> errors;

  HTSourceParseResult(this.source, this.nodes,
      {this.imports = const [], this.errors = const []});
}
