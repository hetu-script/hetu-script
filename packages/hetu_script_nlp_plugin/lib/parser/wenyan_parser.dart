import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/parser.dart';
import 'package:hetu_script/declarations.dart';

/// Default parser implementation used by Hetu.
class WenyanLangParser extends HTParser with TokenReader {
  static var anonymousFunctionIndex = 0;

  @override
  String get name => 'wenyan-lang';

  /// Lexicon definition used by this parser.
  late final HTLexicon lexicon;

  /// Lexer used by this parser, created from [lexicon].
  late final HTLexer _lexer;

  // All import decl in this list must have non-null [fromPath]
  late List<ImportExportDecl> _currentModuleImports;

  List<Comment> _currentPrecedingComments = [];

  HTClassDeclaration? _currentClass;
  FunctionCategory? _currentFunctionCategory;
  String? _currentStructId;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _hasUserDefinedConstructor = false;

  HTSource? _currentSource;

  WenyanLangParser({required this.lexicon}) {
    _lexer = HTLexer(lexicon: lexicon);
  }

  @override
  List<ASTNode> parseToken(Token token,
      {HTSource? source, ParseStyle? style, ParserConfig? config}) {
    // create new list of errors here, old error list is still usable
    errors = <HTError>[];
    final nodes = <ASTNode>[];
    setTokens(token: token);
    _currentSource = source;
    currrentFileName = source?.fullName;
    late ParseStyle parseStyle;
    if (style != null) {
      parseStyle = style;
    } else {
      if (_currentSource != null) {
        final sourceType = _currentSource!.type;
        if (sourceType == HTResourceType.hetuModule) {
          parseStyle = ParseStyle.module;
        } else if (sourceType == HTResourceType.hetuScript ||
            sourceType == HTResourceType.hetuLiteralCode) {
          parseStyle = ParseStyle.script;
        } else if (sourceType == HTResourceType.hetuValue) {
          parseStyle = ParseStyle.expression;
        } else {
          return nodes;
        }
      } else {
        parseStyle = ParseStyle.script;
      }
    }
    while (curTok.type != Semantic.endOfFile) {
      final stmt = _parseStmt(sourceType: parseStyle);
      if (stmt != null) {
        if (stmt is ASTEmptyLine && parseStyle == ParseStyle.expression) {
          continue;
        }
        nodes.add(stmt);
      }
    }
    if (nodes.isEmpty) {
      final empty = ASTEmptyLine(
          source: _currentSource,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.end);
      empty.precedingComments = _currentPrecedingComments;
      _currentPrecedingComments = [];
      nodes.add(empty);
    }
    return nodes;
  }

  @override
  ASTSource parseSource(HTSource source) {
    currrentFileName = source.fullName;
    _currentClass = null;
    _currentFunctionCategory = null;
    _currentModuleImports = <ImportExportDecl>[];
    final tokens = _lexer.lex(source.content);
    final nodes = parseToken(tokens, source: source);
    final result = ASTSource(
        nodes: nodes,
        source: source,
        imports: _currentModuleImports,
        errors: errors); // copy the list);
    return result;
  }
}
