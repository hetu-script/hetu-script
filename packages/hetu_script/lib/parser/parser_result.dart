import '../resource/resource.dart';
import '../source/source.dart';
import '../source/line_info.dart';
import '../ast/ast.dart' show ASTNode, ImportExportDecl;
import '../error/error.dart';

/// Parse result of a single file
class HTSourceParseResult {
  final HTSource source;

  String get fullName => source.fullName;

  HTResourceType get resourceType => source.type;

  LineInfo get lineInfo => source.lineInfo;

  final List<ImportExportDecl> imports;

  final List<ASTNode> nodes;

  final List<HTError>? errors;

  HTSourceParseResult(
      {required this.source,
      required this.nodes,
      this.imports = const [],
      this.errors = const []});
}

/// A bundle of all imported sources
class HTModuleParseResult {
  final Map<String, HTSourceParseResult> values;

  final Map<String, HTSourceParseResult> sources;

  final HTResourceType entryResourceType;

  final List<HTError> errors;

  HTModuleParseResult(
      {required this.values,
      required this.sources,
      required this.entryResourceType,
      required this.errors});
}
