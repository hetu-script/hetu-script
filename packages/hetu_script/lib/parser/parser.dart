import '../ast/ast.dart';
import '../source/source.dart';
import 'token.dart';
import '../lexicon/lexicon.dart';
import '../lexer/lexer.dart';
import '../lexer/lexer_hetu.dart';
import 'token_reader.dart';
import '../error/error.dart';
import '../resource/resource.dart' show HTResourceType;

/// Determines how to parse a piece of code
enum ParseStyle {
  /// Module source can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  /// module can have external class & function declarations.
  module,

  /// A script can have all statements and expressions, kind of like a funciton body plus import & export.
  /// script can have external class & function declarations.
  script,

  /// An expression.
  expression,

  /// Like module, but no import & export allowed.
  /// explicity namespaces can have external functions, but not external classes.
  explicitNamespace,

  /// Class can only have declarations (variables, functions).
  /// class can have external members.
  classDefinition,

  /// Struct can not have external members
  structDefinition,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  functionDefinition,
}

class ParserConfig {
  bool explicitEndOfStatement;

  bool allowImplicitVariableDeclaration;

  bool printPerformanceStatistics;

  ParserConfig({
    this.explicitEndOfStatement = false,
    this.allowImplicitVariableDeclaration = false,
    this.printPerformanceStatistics = false,
  });
}

/// A general parser, with abstract method to parse a token list or string content.
abstract class HTParser with TokenReader {
  static var anonymousFunctionIndex = 0;

  /// the identity name of this parser.
  String get name;

  ParserConfig config;

  /// Lexer used by this parser.
  HTLexer lexer;

  // All import decl in this list must have non-null [fromPath]
  late List<ImportExportDecl> currentModuleImports;

  HTSource? currentSource;

  HTParser({
    ParserConfig? config,
    HTLexicon? lexicon,
    HTLexer? lexer,
  })  : config = config ?? ParserConfig(),
        lexer = lexer ?? HTLexerHetu(lexicon: lexicon);

  /// A functional programming way to parse expression seperated by comma,
  /// such as parameter list, argumetn list, list, group... etc.
  /// the comma after the last expression is optional.
  /// Note that this method will not consume either the start or the end mark.
  List<T> parseExprList<T extends ASTNode>({
    required String endToken,
    String? separateToken,
    required T? Function() parseFunction,
  }) {
    final List<T> listResult = [];
    while (curTok.lexeme != endToken && curTok.lexeme != Token.endOfFile) {
      // deal with comments or empty liens before spread syntax
      final precedings = savePrecedings();
      if (curTok.lexeme == endToken) break;
      final expr = parseFunction();
      if (expr != null) {
        expr.precedings = precedings;
        listResult.add(expr);
        final hasSeparateToken =
            handleTrailing(expr, separateToken: separateToken);
        if (separateToken != null && !hasSeparateToken) {
          break;
        }
      }
    }
    return listResult;
  }

  // save current preceding comments & empty lines

  /// To handle the comments & empty lines before a expr;
  List<ASTAnnotation> savePrecedings() {
    List<ASTAnnotation> precedings = [];
    while (curTok is TokenComment || curTok is TokenEmptyLine) {
      ASTAnnotation documentation;
      if (curTok is TokenComment) {
        documentation = ASTComment.fromCommentToken(advance() as TokenComment);
      } else {
        final token = advance();
        documentation = ASTEmptyLine(
          source: currentSource,
          line: token.line,
          column: token.column,
          offset: token.offset,
          length: token.length,
        );
      }
      precedings.add(documentation);
    }
    return precedings;
  }

  void _handleTrailing(ASTNode expr, {bool afterSeparator = false}) {
    if (curTok is TokenComment) {
      final tokenComment = curTok as TokenComment;
      if (tokenComment.isTrailing || expr.isExpression) {
        advance();
        final trailing = ASTComment.fromCommentToken(tokenComment);
        if (afterSeparator) {
          expr.trailingAfter = trailing;
        } else {
          expr.trailing = trailing;
        }
      }
    }
  }

  /// return true if [separateToken] is found
  bool handleTrailing(ASTNode expr, {String? separateToken}) {
    _handleTrailing(expr);
    if (curTok.lexeme == separateToken) {
      advance();
      _handleTrailing(expr, afterSeparator: true);
      return true;
    }
    return false;
  }

  /// To read the current token from current position and produce an AST expression.
  /// Normally this is the entry point of recursive descent parsing.
  /// Class that implements [HTParser] must define this method.
  ASTNode parseExpr();

  /// Convert tokens into a list of [ASTNode] by a certain grammar rules set.
  ///
  /// If [source] is not specified, the token will not be binded to a [HTSource].
  ///
  /// If [style] is not specified, will use [source.sourceType] to determine,
  /// if source is null at the same time, will use [ParseStyle.script] by default.
  List<ASTNode> parseTokens(Token token,
      {HTSource? source, ParseStyle? style}) {
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
        } else if (sourceType == HTResourceType.json) {
          style = ParseStyle.expression;
        } else {
          return nodes;
        }
      } else {
        style = ParseStyle.script;
      }
    }

    while (curTok.lexeme != Token.endOfFile) {
      final stmt = parseStmt(style: style);
      if (stmt != null) {
        if (stmt is ASTEmptyLine && style == ParseStyle.expression) {
          continue;
        }
        nodes.add(stmt);
      }
    }
    return nodes;
  }

  /// Convert string content into [ASTSource] by a certain grammar rules set.
  ASTSource parseSource(HTSource source) {
    final tik = DateTime.now().millisecondsSinceEpoch;
    currrentFileName = source.fullName;
    resetFlags();
    currentModuleImports = <ImportExportDecl>[];
    final tokens = lexer.lex(source.content);
    final nodes = parseTokens(tokens, source: source);
    final result = ASTSource(
        nodes: nodes,
        source: source,
        imports: currentModuleImports,
        errors: errors); // copy the list);
    if (config.printPerformanceStatistics) {
      final tok = DateTime.now().millisecondsSinceEpoch;
      print('hetu: ${tok - tik}ms\tto parse\t[${source.fullName}]');
    }
    return result;
  }

  void resetFlags();

  ASTNode? parseStmt({required ParseStyle style});

  bool parseEndOfStmtMark({bool required = false}) {
    bool hasEndOfStmtMark = true;
    if (config.explicitEndOfStatement || required) {
      match(lexer.lexicon.endOfStatementMark);
    } else {
      hasEndOfStmtMark =
          expect([lexer.lexicon.endOfStatementMark], consume: true);
    }
    return hasEndOfStmtMark;
  }
}
