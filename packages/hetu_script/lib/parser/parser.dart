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

  List<ASTAnnotation> currentPrecedings = [];

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
    bool handleComma = true,
    required T? Function() parseFunction,
  }) {
    final List<T> listResult = [];
    final savedPrecedings = savePrecedings();
    while (curTok.lexeme != endToken && curTok.lexeme != Token.endOfFile) {
      // deal with comments or empty liens before spread syntax
      handlePrecedings();
      if (curTok.lexeme == endToken) break;
      final expr = parseFunction();
      if (expr != null) {
        listResult.add(expr);
        handleTrailing(expr,
            handleComma: handleComma, endMarkForCommaExpressions: endToken);
      }
    }
    if (currentPrecedings.isNotEmpty && listResult.isNotEmpty) {
      listResult.last.succeedings = currentPrecedings;
      currentPrecedings = [];
    }
    currentPrecedings = savedPrecedings;
    return listResult;
  }

  // save current preceding comments & empty lines
  List<ASTAnnotation> savePrecedings() {
    final saved = currentPrecedings;
    currentPrecedings = [];
    return saved;
  }

  // set current preceding comments & empty lines on parsed ast.
  bool setPrecedings(ASTNode expr) {
    if (currentPrecedings.isNotEmpty) {
      expr.precedings = currentPrecedings;
      currentPrecedings = [];
      return true;
    }
    return false;
  }

  /// To handle the comments & empty lines before a expr;
  bool handlePrecedings() {
    bool handled = false;
    while (curTok is TokenComment || curTok is TokenEmptyLine) {
      handled = true;
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
      currentPrecedings.add(documentation);
    }
    return handled;
  }

  void _handleTrailing(ASTNode expr, {bool afterComma = false}) {
    if (curTok is TokenComment) {
      final tokenComment = curTok as TokenComment;
      if (tokenComment.isTrailing || expr.isExpression) {
        advance();
        final trailing = ASTComment.fromCommentToken(tokenComment);
        if (afterComma) {
          expr.trailingAfterComma = trailing;
        } else {
          expr.trailing = trailing;
        }
      }
    }
  }

  void handleTrailing(ASTNode expr,
      {bool handleComma = true, String? endMarkForCommaExpressions}) {
    _handleTrailing(expr);
    if (endMarkForCommaExpressions != null &&
        curTok.lexeme != endMarkForCommaExpressions) {
      if (handleComma) match(lexer.lexicon.comma);
      _handleTrailing(expr, afterComma: true);
    }
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
