import '../ast/ast.dart';
import '../source/source.dart';
import 'token.dart';
import '../comment/comment.dart';
import '../declaration/class/class_declaration.dart';
import '../grammar/constant.dart';
import '../lexer/lexer.dart';
import '../lexer/lexicon.dart';
import 'token_reader.dart';
import '../error/error.dart';
import '../resource/resource.dart' show HTResourceType;

/// Determines how to parse a piece of code
enum ParseStyle {
  /// Module source can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// A script can have all statements and expressions, kind of like a funciton body plus import & export.
  script,

  /// An expression.
  expression,

  /// Like module, but no import & export allowed.
  namespace,

  /// Class can only have declarations (variables, functions).
  classDefinition,

  /// Struct can not have external members
  structDefinition,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  functionDefinition,
}

class ParserConfig {
  bool explicitEndOfStatement;

  ParserConfig({this.explicitEndOfStatement = false});
}

/// A general parser, with abstract method to parse a token list or string content.
abstract class HTParser with TokenReader {
  static var anonymousFunctionIndex = 0;

  /// the identity name of this parser.
  String get name;

  ParserConfig config;

  /// Lexicon definition used by this parser.
  late final HTLexicon lexicon;

  /// Lexer used by this parser, created from [lexicon].
  late final HTLexer lexer;

  // All import decl in this list must have non-null [fromPath]
  late List<ImportExportDecl> currentModuleImports;

  List<Comment> currentPrecedingComments = [];

  HTClassDeclaration? currentClass;
  FunctionCategory? currentFunctionCategory;
  String? currentStructId;

  var leftValueLegality = false;

  bool hasUserDefinedConstructor = false;

  HTSource? currentSource;

  HTParser({
    ParserConfig? config,
    required this.lexicon,
  })  : config = config ?? ParserConfig(),
        lexer = HTLexer(lexicon: lexicon);

  /// Convert tokens into a list of [ASTNode] by a certain grammar rules set.
  ///
  /// If [source] is not specified, the token will not be binded to a [HTSource].
  ///
  /// If [style] is not specified, will use [source.sourceType] to determine,
  /// if source is null at the same time, will use [ParseStyle.script] by default.
  List<ASTNode> parseToken(Token token, {HTSource? source, ParseStyle? style}) {
    // create new list of errors here, old error list is still usable
    errors = <HTError>[];
    final nodes = <ASTNode>[];
    setTokens(token: token);
    currentSource = source;
    currrentFileName = source?.fullName;
    if (style == null) {
      if (currentSource != null) {
        final sourceType = currentSource!.type;
        if (sourceType == HTResourceType.hetuModule) {
          style = ParseStyle.module;
        } else if (sourceType == HTResourceType.hetuScript ||
            sourceType == HTResourceType.hetuLiteralCode) {
          style = ParseStyle.script;
        } else if (sourceType == HTResourceType.hetuValue) {
          style = ParseStyle.expression;
        } else {
          return nodes;
        }
      } else {
        style = ParseStyle.script;
      }
    }
    while (curTok.type != Semantic.endOfFile) {
      final stmt = parseStmt(style: style);
      if (stmt != null) {
        if (stmt is ASTEmptyLine && style == ParseStyle.expression) {
          continue;
        }
        nodes.add(stmt);
      }
    }
    if (nodes.isEmpty) {
      final empty = ASTEmptyLine(
          source: currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.end);
      empty.precedingComments = currentPrecedingComments;
      currentPrecedingComments = [];
      nodes.add(empty);
    }
    return nodes;
  }

  /// Convert string content into [ASTSource] by a certain grammar rules set.
  ASTSource parseSource(HTSource source) {
    currrentFileName = source.fullName;
    currentClass = null;
    currentFunctionCategory = null;
    currentModuleImports = <ImportExportDecl>[];
    final tokens = lexer.lex(source.content);
    final nodes = parseToken(tokens, source: source);
    final result = ASTSource(
        nodes: nodes,
        source: source,
        imports: currentModuleImports,
        errors: errors); // copy the list);
    return result;
  }

  ASTNode? parseStmt({required ParseStyle style});
}
