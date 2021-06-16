import '../grammar/lexicon.dart';
import '../source/source.dart';
import '../core/abstract_parser.dart';
import '../core/lexer.dart';
import '../core/declaration/class_declaration.dart';
import '../grammar/semantic.dart';
import '../error/errors.dart';
import '../source/source_provider.dart';
import 'ast.dart';
import 'ast_compilation.dart';
import '../core/token.dart';

class HTAstParser extends AbstractParser {
  final _curModuleImports = <ImportStmt>[];

  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  late String _curLibraryName;
  @override
  String get curLibraryName => _curLibraryName;

  ClassDeclaration? _curClass;
  FunctionCategory? _curFuncType;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  bool _isLibrary = false;
  late String _libraryName;

  late HTSource _curSource;

  HTAstParser({ParserConfig config = const ParserConfig()}) : super(config);

  List<AstNode> parse(List<Token> tokens, HTSource source,
      {ParserConfig? config}) {
    _curSource = source;

    final savedConfig = this.config;
    if (config != null) {
      this.config = config;
    }

    addTokens(tokens);
    final nodes = <AstNode>[];
    while (curTok.type != HTLexicon.endOfFile) {
      final stmt = _parseStmt(sourceType: this.config.sourceType);
      nodes.add(stmt);
    }

    this.config = savedConfig;

    return nodes;
  }

  HTAstModule parseSource(HTSource source,
      {bool createNamespace = true, ParserConfig? config}) {
    _curModuleFullName = source.fullName;
    _curClass = null;
    _curFuncType = null;

    final savedConfig = this.config;
    if (config != null) {
      this.config = config;
    }

    final tokens = Lexer().lex(source.content, _curModuleFullName);
    final nodes = parse(tokens, source);

    final module = HTAstModule(source, nodes, this.config.sourceType,
        imports: _curModuleImports.toList(), // copy the list
        createNamespace: createNamespace,
        isLibrary: _isLibrary);

    _curModuleImports.clear();

    this.config = savedConfig;

    return module;
  }

  /// Parse a string content and generate a library,
  /// will import other files.
  Future<HTAstCompilation> parseToCompilation(
      HTSource source, SourceProvider sourceProvider,
      {bool createNamespace = true,
      String? libraryName,
      ParserConfig? config}) async {
    final fullName = source.fullName;
    _curLibraryName = libraryName ?? fullName;

    final module =
        parseSource(source, createNamespace: createNamespace, config: config);

    final compilation = HTAstCompilation(_curLibraryName);
    for (final stmt in module.imports) {
      final importFullName =
          sourceProvider.resolveFullName(stmt.key, module.fullName);
      if (!sourceProvider.hasModule(importFullName)) {
        final source2 = await sourceProvider.getSource(importFullName,
            curModuleFullName: _curModuleFullName);
        final compilation2 = await parseToCompilation(source2, sourceProvider,
            config: ParserConfig(sourceType: SourceType.module));
        _curModuleFullName = fullName;
        compilation.join(compilation2);
      }
    }

    compilation.add(module);

    return compilation;
  }

  AstNode _parseStmt({SourceType sourceType = SourceType.function}) {
    switch (sourceType) {
      case SourceType.script:
        if (curTok.lexeme == HTLexicon.IMPORT) {
          return _parseImportStmt();
        } else {
          switch (curTok.type) {
            case SemanticType.singleLineComment:
            case SemanticType.multiLineComment:
              return _parseExprStmt();
            case HTLexicon.EXPORT:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  return _parseClassDecl(
                      isAbstract: true, isExternal: true, isExported: true);
                case HTLexicon.CLASS:
                  return _parseClassDecl(isExternal: true, isExported: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(isExternal: true, isExported: true);
                case HTLexicon.VAR:
                  return _parseVarDecl(isMutable: true, isExported: true);
                case HTLexicon.LET:
                  return _parseVarDecl(
                      typeInferrence: true, isMutable: true, isExported: true);
                case HTLexicon.CONST:
                  return _parseVarDecl(typeInferrence: true, isExported: true);
                case HTLexicon.FUNCTION:
                  return _parseFuncDecl(isExternal: true, isExported: true);
                default:
                  throw HTError.unexpected(
                      SemanticType.declStmt, curTok.lexeme);
              }
            case HTLexicon.EXTERNAL:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  return _parseClassDecl(isAbstract: true, isExternal: true);
                case HTLexicon.CLASS:
                  return _parseClassDecl(isExternal: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(isExternal: true);
                case HTLexicon.VAR:
                case HTLexicon.LET:
                case HTLexicon.CONST:
                  throw HTError.externalVar();
                case HTLexicon.FUNCTION:
                  return _parseFuncDecl(isExternal: true);
                default:
                  throw HTError.unexpected(
                      SemanticType.declStmt, curTok.lexeme);
              }
            case HTLexicon.ABSTRACT:
              advance(1);
              return _parseClassDecl(isAbstract: true);
            case HTLexicon.ENUM:
              return _parseEnumDecl();
            case HTLexicon.CLASS:
              return _parseClassDecl();
            case HTLexicon.VAR:
              return _parseVarDecl(isMutable: true);
            case HTLexicon.LET:
              return _parseVarDecl(typeInferrence: true, isMutable: true);
            case HTLexicon.CONST:
              return _parseVarDecl(typeInferrence: true);
            case HTLexicon.FUNCTION:
              if (expect([HTLexicon.FUNCTION, SemanticType.identifier]) ||
                  expect([
                    HTLexicon.FUNCTION,
                    HTLexicon.squareLeft,
                    SemanticType.identifier,
                    HTLexicon.squareRight,
                    SemanticType.identifier
                  ])) {
                return _parseFuncDecl();
              } else {
                return _parseFuncDecl(category: FunctionCategory.literal);
              }
            case HTLexicon.IF:
              return _parseIfStmt();
            case HTLexicon.WHILE:
              return _parseWhileStmt();
            case HTLexicon.DO:
              return _parseDoStmt();
            case HTLexicon.FOR:
              return _parseForStmt();
            case HTLexicon.WHEN:
              return _parseWhenStmt();
            default:
              return _parseExprStmt();
          }
        }
      case SourceType.module:
        if (curTok.lexeme == HTLexicon.library) {
          return _parseLibraryStmt();
        } else if (curTok.lexeme == HTLexicon.IMPORT) {
          return _parseImportStmt();
        } else {
          switch (curTok.type) {
            case SemanticType.singleLineComment:
            case SemanticType.multiLineComment:
              return _parseExprStmt();
            case HTLexicon.EXPORT:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  return _parseClassDecl(
                      isAbstract: true, isExternal: true, isExported: true);
                case HTLexicon.CLASS:
                  return _parseClassDecl(isExternal: true, isExported: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(isExternal: true, isExported: true);
                case HTLexicon.VAR:
                  return _parseVarDecl(isMutable: true, isExported: true);
                case HTLexicon.LET:
                  return _parseVarDecl(
                      typeInferrence: true, isMutable: true, isExported: true);
                case HTLexicon.CONST:
                  return _parseVarDecl(typeInferrence: true, isExported: true);
                case HTLexicon.FUNCTION:
                  return _parseFuncDecl(isExternal: true, isExported: true);
                default:
                  throw HTError.unexpected(
                      SemanticType.declStmt, curTok.lexeme);
              }
            case HTLexicon.EXTERNAL:
              advance(1);
              switch (curTok.type) {
                case HTLexicon.ABSTRACT:
                  advance(1);
                  if (curTok.type != HTLexicon.CLASS) {
                    throw HTError.unexpected(
                        SemanticType.classDeclaration, curTok.lexeme);
                  }
                  return _parseClassDecl(isAbstract: true, isExternal: true);
                case HTLexicon.CLASS:
                  return _parseClassDecl(isExternal: true);
                case HTLexicon.ENUM:
                  return _parseEnumDecl(isExternal: true);
                case HTLexicon.FUNCTION:
                  if (!expect([HTLexicon.FUNCTION, SemanticType.identifier])) {
                    throw HTError.unexpected(
                        SemanticType.functionDeclaration, peek(1).lexeme);
                  }
                  return _parseFuncDecl(isExternal: true);
                case HTLexicon.VAR:
                case HTLexicon.LET:
                case HTLexicon.CONST:
                  throw HTError.externalVar();
                default:
                  throw HTError.unexpected(
                      SemanticType.declStmt, curTok.lexeme);
              }
            case HTLexicon.ABSTRACT:
              advance(1);
              return _parseClassDecl(isAbstract: true);
            case HTLexicon.ENUM:
              return _parseEnumDecl();
            case HTLexicon.CLASS:
              return _parseClassDecl();
            case HTLexicon.VAR:
              return _parseVarDecl(isMutable: true, lateInitialize: true);
            case HTLexicon.LET:
              return _parseVarDecl(typeInferrence: true, lateInitialize: true);
            case HTLexicon.CONST:
              return _parseVarDecl(typeInferrence: true, lateInitialize: true);
            case HTLexicon.FUNCTION:
              return _parseFuncDecl();
            default:
              throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
          }
        }
      case SourceType.function:
        switch (curTok.type) {
          case HTLexicon.VAR:
            return _parseVarDecl(isMutable: true);
          case HTLexicon.LET:
            return _parseVarDecl(typeInferrence: true, isMutable: true);
          case HTLexicon.CONST:
            return _parseVarDecl(typeInferrence: true);
          case HTLexicon.FUNCTION:
            if (expect([HTLexicon.FUNCTION, SemanticType.identifier]) ||
                expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  SemanticType.identifier,
                  HTLexicon.squareRight,
                  SemanticType.identifier
                ])) {
              return _parseFuncDecl();
            } else {
              return _parseFuncDecl(category: FunctionCategory.literal);
            }
          case HTLexicon.IF:
            return _parseIfStmt();
          case HTLexicon.WHILE:
            return _parseWhileStmt();
          case HTLexicon.DO:
            return _parseDoStmt();
          case HTLexicon.FOR:
            return _parseForStmt();
          case HTLexicon.WHEN:
            return _parseWhenStmt();
          case HTLexicon.BREAK:
            final keyword = advance(1);
            return BreakStmt(keyword, keyword.line, keyword.column, _curSource);
          case HTLexicon.CONTINUE:
            final keyword = advance(1);
            return ContinueStmt(
                keyword, keyword.line, keyword.column, _curSource);
          case HTLexicon.RETURN:
            if (_curFuncType != null &&
                _curFuncType != FunctionCategory.constructor) {
              return _parseReturnStmt();
            } else {
              throw HTError.outsideReturn();
            }
          default:
            return _parseExprStmt();
        }
      case SourceType.klass:
        final isExternal = expect([HTLexicon.EXTERNAL], consume: true);
        final isStatic = expect([HTLexicon.STATIC], consume: true);
        switch (curTok.type) {
          case SemanticType.singleLineComment:
          case SemanticType.multiLineComment:
            return _parseExprStmt();
          case HTLexicon.VAR:
            return _parseVarDecl(
                classId: _curClass?.id,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isMutable: true,
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.LET:
            return _parseVarDecl(
                classId: _curClass?.id,
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isMutable: true,
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.CONST:
            return _parseVarDecl(
                classId: _curClass?.id,
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.FUNCTION:
            return _parseFuncDecl(
                category: FunctionCategory.method,
                classId: _curClass?.id,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
          case HTLexicon.CONSTRUCT:
            if (isStatic) {
              throw HTError.unexpected(
                  SemanticType.declStmt, HTLexicon.CONSTRUCT);
            }
            return _parseFuncDecl(
              category: FunctionCategory.constructor,
              classId: _curClass?.id,
              isExternal: isExternal || (_curClass?.isExternal ?? false),
            );
          case HTLexicon.GET:
            return _parseFuncDecl(
                category: FunctionCategory.getter,
                classId: _curClass?.id,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
          case HTLexicon.SET:
            return _parseFuncDecl(
                category: FunctionCategory.setter,
                classId: _curClass?.id,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
          default:
            throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
        }
      case SourceType.struct:
      case SourceType.expression:
        return _parseExpr();
    }
  }

  LibraryStmt _parseLibraryStmt() {
    final keyword = advance(1);

    _isLibrary = true;

    expect([HTLexicon.semicolon], consume: true);

    final stmt = LibraryStmt(keyword.line, keyword.column, _curSource);

    return stmt;
  }

  ImportStmt _parseImportStmt() {
    final keyword = advance(1);
    String key = match(SemanticType.literalString).literal;
    String? alias;
    if (expect([HTLexicon.AS], consume: true)) {
      alias = match(SemanticType.identifier).lexeme;
    }

    final showList = <String>[];
    if (curTok.lexeme == HTLexicon.SHOW) {
      advance(1);
      while (curTok.type == SemanticType.identifier) {
        showList.add(advance(1).lexeme);
        if (curTok.type != HTLexicon.comma) {
          break;
        } else {
          advance(1);
        }
      }
    }

    expect([HTLexicon.semicolon], consume: true);

    final stmt = ImportStmt(key, keyword.line, keyword.column, _curSource,
        alias: alias, showList: showList);

    _curModuleImports.add(stmt);

    return stmt;
  }

  /// 使用递归向下的方法生成表达式, 不断调用更底层的, 优先级更高的子Parser
  ///
  /// 赋值 = , 优先级 1, 右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  AstNode _parseExpr() {
    if (curTok.type == SemanticType.singleLineComment) {
      final comment = advance(1);
      return CommentExpr(
          comment.literal, false, comment.line, comment.column, _curSource);
    } else if (curTok.type == SemanticType.multiLineComment) {
      final comment = advance(1);
      return CommentExpr(
          comment.literal, true, comment.line, comment.column, _curSource);
    } else {
      final left = _parserTernaryExpr();
      if (HTLexicon.assignments.contains(curTok.type)) {
        if (!_leftValueLegality) {
          throw HTError.invalidLeftValue();
        }
        final op = advance(1);
        final right = _parseExpr();
        if (left is MemberExpr) {
          return MemberAssignExpr(
              left.object, left.key, right, left.line, left.column, _curSource);
        } else if (left is SubExpr) {
          return SubAssignExpr(
              left.array, left.key, right, left.line, left.column, _curSource);
        } else {
          return BinaryExpr(
              left, op.lexeme, right, op.line, op.column, _curSource);
        }
      } else {
        return left;
      }
    }
  }

  AstNode _parserTernaryExpr() {
    var condition = _parseLogicalOrExpr();
    if (expect([HTLexicon.condition], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(condition, thenBranch, elseBranch, condition.line,
          condition.column, _curSource);
    }
    return condition;
  }

  /// 逻辑或 or , 优先级 5, 左合并
  AstNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        final op = advance(1); // and operator
        final right = _parseLogicalAndExpr();
        left =
            BinaryExpr(left, op.lexeme, right, op.line, op.column, _curSource);
      }
    }
    return left;
  }

  /// 逻辑和 and , 优先级 6, 左合并
  AstNode _parseLogicalAndExpr() {
    var left = _parseEqualityExpr();
    if (curTok.type == HTLexicon.logicalAnd) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalAnd) {
        final op = advance(1); // and operator
        final right = _parseEqualityExpr();
        left =
            BinaryExpr(left, op.lexeme, right, op.line, op.column, _curSource);
      }
    }
    return left;
  }

  /// 逻辑相等 ==, !=, 优先级 7, 不合并
  AstNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      final right = _parseRelationalExpr();
      left = BinaryExpr(left, op.lexeme, right, op.line, op.column, _curSource);
    }
    return left;
  }

  /// 逻辑比较 <, >, <=, >=, as, is, is! 优先级 8, 不合并
  AstNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (HTLexicon.logicalRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1);
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op.lexeme, right, op.line, op.column, _curSource);
    } else if (HTLexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final opTok = advance(1);
      late final String op;
      if (opTok.lexeme == HTLexicon.IS) {
        op = expect([HTLexicon.logicalNot], consume: true)
            ? HTLexicon.ISNOT
            : HTLexicon.IS;
      } else {
        op = opTok.lexeme;
      }
      final right = _parseTypeExpr(isLocal: true);
      left = BinaryExpr(left, op, right, opTok.line, opTok.column, _curSource);
    }
    return left;
  }

  /// 加法 +, -, 优先级 13, 左合并
  AstNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.additives.contains(curTok.type)) {
        final op = advance(1);
        final right = _parseMultiplicativeExpr();
        left =
            BinaryExpr(left, op.lexeme, right, op.line, op.column, _curSource);
      }
    }
    return left;
  }

  /// 乘法 *, /, %, 优先级 14, 左合并
  AstNode _parseMultiplicativeExpr() {
    var left = _parseUnaryPrefixExpr();
    if (HTLexicon.multiplicatives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.multiplicatives.contains(curTok.type)) {
        final op = advance(1);
        final right = _parseUnaryPrefixExpr();
        left =
            BinaryExpr(left, op.lexeme, right, op.line, op.column, _curSource);
      }
    }
    return left;
  }

  /// 前缀 -e, !e，++e, --e, 优先级 15, 不合并
  AstNode _parseUnaryPrefixExpr() {
    if (!(HTLexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      final op = advance(1);
      final value = _parseUnaryPostfixExpr();
      return UnaryPrefixExpr(op.lexeme, value, op.line, op.column, _curSource);
    }
  }

  /// 后缀 e., e[], e(), e++, e-- 优先级 16, 右合并
  AstNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      final op = advance(1);
      switch (op.type) {
        case HTLexicon.memberGet:
          _leftValueLegality = true;
          final name = match(SemanticType.identifier);
          final key = SymbolExpr(
              name.lexeme, name.line, name.column, _curSource,
              isLocal: false);
          expr = MemberExpr(expr, key, op.line, op.column, _curSource);
          break;
        case HTLexicon.subGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.squareRight);
          expr = SubExpr(expr, indexExpr, op.line, op.column, _curSource);
          break;
        case HTLexicon.call:
          // TODO: typeArgs: typeArgs
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(
              expr, positionalArgs, namedArgs, op.line, op.column, _curSource);
          break;
        case HTLexicon.postIncrement:
        case HTLexicon.postDecrement:
          _leftValueLegality = false;
          expr =
              UnaryPostfixExpr(expr, op.lexeme, op.line, op.column, _curSource);
          break;
        default:
          break;
      }
    }
    return expr;
  }

  /// Expression without operators
  AstNode _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.NULL:
        _leftValueLegality = false;
        final token = advance(1);
        return NullExpr(token.line, token.column, _curSource);
      case SemanticType.literalBoolean:
        _leftValueLegality = false;
        final token = advance(1) as TokenBooleanLiteral;
        return BooleanExpr(token.literal, token.line, token.column, _curSource);
      case SemanticType.literalInteger:
        _leftValueLegality = false;
        final token = advance(1) as TokenIntLiteral;
        return ConstIntExpr(
            token.literal, token.line, token.column, _curSource);
      case SemanticType.literalFloat:
        _leftValueLegality = false;
        final token = advance(1) as TokenFloatLiteral;
        return ConstFloatExpr(
            token.literal, token.line, token.column, _curSource);
      case SemanticType.literalString:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringLiteral;
        return ConstStringExpr.fromToken(token, _curSource);
      case SemanticType.stringInterpolation:
        _leftValueLegality = false;
        final token = advance(1) as TokenStringInterpolation;
        final interpolation = <AstNode>[];
        for (final tokens in token.interpolations) {
          final exprParser = HTAstParser(
              config: ParserConfig(sourceType: SourceType.expression));
          final nodes = exprParser.parse(tokens, _curSource);
          if (nodes.length > 1) {
            throw HTError.stringInterpolation();
          }
          interpolation.add(nodes.first);
        }
        var i = 0;
        final value = token.literal.replaceAllMapped(
            RegExp(HTLexicon.stringInterpolation),
            (Match m) => '${HTLexicon.curlyLeft}${i++}${HTLexicon.curlyRight}');
        return StringInterpolationExpr(
            value,
            token.quotationLeft,
            token.quotationRight,
            interpolation,
            token.line,
            token.column,
            _curSource);
      case HTLexicon.THIS:
        _leftValueLegality = false;
        final keyword = advance(1);
        return SymbolExpr(
            keyword.lexeme, keyword.line, keyword.column, _curSource);
      case HTLexicon.SUPER:
        _leftValueLegality = false;
        final keyword = advance(1);
        return SymbolExpr(
            keyword.lexeme, keyword.line, keyword.column, _curSource);
      case HTLexicon.roundLeft:
        _leftValueLegality = false;
        final punc = advance(1);
        final innerExpr = _parseExpr();
        match(HTLexicon.roundRight);
        return GroupExpr(innerExpr, punc.line, punc.column, _curSource);
      case HTLexicon.squareLeft:
        _leftValueLegality = false;
        final line = curTok.line;
        final column = advance(1).column;
        var listExpr = <AstNode>[];
        while (curTok.type != HTLexicon.squareRight) {
          listExpr.add(_parseExpr());
          if (curTok.type != HTLexicon.squareRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.squareRight);
        return ListExpr(listExpr, line, column, _curSource);
      case HTLexicon.curlyLeft:
        _leftValueLegality = false;
        final line = curTok.line;
        final column = advance(1).column;
        var mapExpr = <AstNode, AstNode>{};
        while (curTok.type != HTLexicon.curlyRight) {
          var keyExpr = _parseExpr();
          match(HTLexicon.colon);
          var valueExpr = _parseExpr();
          mapExpr[keyExpr] = valueExpr;
          if (curTok.type != HTLexicon.curlyRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.curlyRight);
        return MapExpr(line, column, _curSource, map: mapExpr);
      case HTLexicon.FUNCTION:
        return _parseFuncDecl(category: FunctionCategory.literal);
      case SemanticType.identifier:
        // literal function type
        if (curTok.lexeme == HTLexicon.function) {
          _leftValueLegality = false;
          return _parseTypeExpr();
        }
        // TODO: literal interface type
        else {
          _leftValueLegality = true;
          final symbol = advance(1);
          // TODO: type arguments
          return SymbolExpr(
              symbol.lexeme, symbol.line, symbol.column, _curSource);
        }
      default:
        throw HTError.unexpected(SemanticType.expression, curTok.lexeme);
    }
  }

  TypeExpr _parseTypeExpr({bool isLocal = false}) {
    // function type
    if (curTok.lexeme != HTLexicon.FUNCTION) {
      final id = match(SemanticType.identifier);

      final typeArgs = <TypeExpr>[];
      if (expect([HTLexicon.angleLeft], consume: true)) {
        if (curTok.type == HTLexicon.angleRight) {
          throw HTError.emptyTypeArgs();
        }
        while ((curTok.type != HTLexicon.angleRight) &&
            (curTok.type != HTLexicon.endOfFile)) {
          typeArgs.add(_parseTypeExpr());
          expect([HTLexicon.comma], consume: true);
        }
        match(HTLexicon.angleRight);
      }

      final isNullable = expect([HTLexicon.nullable], consume: true);

      return TypeExpr(id.lexeme, id.line, id.column, _curSource,
          arguments: typeArgs, isNullable: isNullable, isLocal: isLocal);
    }
    // TODO: interface type
    else {
      final keyword = advance(1);

      // TODO: genericTypeParameters 泛型参数

      final parameters = <ParamTypeExpr>[];

      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;

      match(HTLexicon.roundLeft);
      while (curTok.type != HTLexicon.roundRight &&
          curTok.type != HTLexicon.endOfFile) {
        final line = curTok.line;
        final column = curTok.column;
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }

        late final paramType;
        String? paramId;
        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        } else {
          paramId = match(SemanticType.identifier).lexeme;
          match(HTLexicon.colon);
        }

        paramType = _parseTypeExpr();

        final param = ParamTypeExpr(paramType, line, column, _curSource,
            isOptional: isOptional, isVariadic: isVariadic, id: paramId);
        parameters.add(param);

        if (isOptional && expect([HTLexicon.squareRight], consume: true)) {
          break;
        } else if (isNamed && expect([HTLexicon.curlyRight], consume: true)) {
          break;
        } else if (curTok.type != HTLexicon.roundRight) {
          match(HTLexicon.comma);
        }

        if (isVariadic) {
          break;
        }
      }
      match(HTLexicon.roundRight);

      match(HTLexicon.singleArrow);

      final returnType = _parseTypeExpr();

      return FuncTypeExpr(returnType, keyword.line, keyword.column, _curSource,
          paramTypes: parameters,
          hasOptionalParam: isOptional,
          hasNamedParam: isNamed);
    }
  }

  BlockStmt _parseBlockStmt(
      {String? id,
      SourceType sourceType = SourceType.function,
      bool createNamespace = true}) {
    final token = match(HTLexicon.curlyLeft);
    final statements = <AstNode>[];
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      statements.add(stmt);
    }
    match(HTLexicon.curlyRight);
    return BlockStmt(statements, token.line, token.column, _curSource,
        id: id, createNamespace: createNamespace);
  }

  void _handleCallArguments(
      List<AstNode> positionalArgs, Map<String, AstNode> namedArgs) {
    var isNamed = false;
    while ((curTok.type != HTLexicon.roundRight) &&
        (curTok.type != HTLexicon.endOfFile)) {
      if ((!isNamed &&
              expect([SemanticType.identifier, HTLexicon.colon],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(SemanticType.identifier).lexeme;
        match(HTLexicon.colon);
        final value = _parseExpr();
        namedArgs[name] = value;
      } else {
        positionalArgs.add(_parseExpr());
      }
      if (curTok.type != HTLexicon.roundRight) {
        match(HTLexicon.comma);
      }
    }
    match(HTLexicon.roundRight);
  }

  ExprStmt _parseExprStmt() {
    AstNode? expr;
    if (curTok.type != HTLexicon.semicolon) {
      expr = _parseExpr();
    }
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true);
    return ExprStmt(expr, curTok.line, curTok.column, _curSource);
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    AstNode? expr;
    if (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.semicolon &&
        curTok.type != HTLexicon.endOfFile) {
      expr = _parseExpr();
    }
    expect([HTLexicon.semicolon], consume: true);
    return ReturnStmt(keyword, expr, keyword.line, keyword.column, _curSource);
  }

  IfStmt _parseIfStmt() {
    final keyword = advance(1);
    match(HTLexicon.roundLeft);
    var condition = _parseExpr();
    match(HTLexicon.roundRight);
    late BlockStmt thenBranch;
    if (curTok.type == HTLexicon.curlyLeft) {
      thenBranch = _parseBlockStmt(id: SemanticType.thenBranch);
    } else {
      final stmt = _parseStmt();
      thenBranch = BlockStmt([stmt], stmt.line, stmt.column, _curSource,
          id: SemanticType.thenBranch);
    }
    BlockStmt? elseBranch;
    if (expect([HTLexicon.ELSE], consume: true)) {
      if (curTok.type == HTLexicon.curlyLeft) {
        elseBranch = _parseBlockStmt(id: SemanticType.elseBranch);
      } else {
        final stmt = _parseStmt();
        elseBranch = BlockStmt([stmt], stmt.line, stmt.column, _curSource,
            id: SemanticType.elseBranch);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch, keyword.line,
        keyword.column, _curSource);
  }

  WhileStmt _parseWhileStmt() {
    final keyword = advance(1);
    AstNode? condition;
    if (expect([HTLexicon.roundLeft], consume: true)) {
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    late BlockStmt loop;
    if (curTok.type == HTLexicon.curlyLeft) {
      loop = _parseBlockStmt(id: SemanticType.whileLoop);
    } else {
      final stmt = _parseStmt();
      loop = BlockStmt([stmt], stmt.line, stmt.column, _curSource,
          id: SemanticType.whileLoop);
    }
    return WhileStmt(condition, loop, keyword.line, keyword.column, _curSource);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance(1);
    late BlockStmt loop;
    if (curTok.type == HTLexicon.curlyLeft) {
      loop = _parseBlockStmt(id: SemanticType.doLoop);
    } else {
      final stmt = _parseStmt();
      loop = BlockStmt([stmt], stmt.line, stmt.column, _curSource,
          id: SemanticType.doLoop);
    }
    AstNode? condition;
    if (expect([HTLexicon.WHILE], consume: true)) {
      match(HTLexicon.roundLeft);
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    return DoStmt(loop, condition, keyword.line, keyword.column, _curSource);
  }

  AstNode _parseForStmt() {
    final keyword = advance(1);
    match(HTLexicon.roundLeft);
    final forStmtType = peek(2).lexeme;
    VarDeclStmt? declaration;
    AstNode? condition;
    AstNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.IN) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        throw HTError.unexpected(SemanticType.variableDeclaration, curTok.type);
      }
      declaration = _parseVarDecl(
          typeInferrence: curTok.type != HTLexicon.VAR,
          isMutable: curTok.type != HTLexicon.CONST);

      advance(1);

      final collection = _parseExpr();

      match(HTLexicon.roundRight);

      final loop = _parseBlockStmt(id: SemanticType.forLoop);

      return ForInStmt(declaration, collection, loop, keyword.line,
          keyword.column, _curSource);
    } else {
      if (!expect([HTLexicon.semicolon], consume: false)) {
        declaration = _parseVarDecl(
            typeInferrence: curTok.type != HTLexicon.VAR,
            isMutable: curTok.type != HTLexicon.CONST,
            endOfStatement: true);
      } else {
        match(HTLexicon.semicolon);
      }

      if (!expect([HTLexicon.semicolon], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);

      if (!expect([HTLexicon.roundRight], consume: false)) {
        increment = _parseExpr();
      }
      match(HTLexicon.roundRight);

      final loop = _parseBlockStmt(id: SemanticType.forLoop);

      return ForStmt(declaration, condition, increment, loop, keyword.line,
          keyword.column, _curSource);
    }
  }

  WhenStmt _parseWhenStmt() {
    final keyword = advance(1);
    AstNode? condition;
    if (expect([HTLexicon.roundLeft], consume: true)) {
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    final options = <AstNode, AstNode>{};
    BlockStmt? elseBranch;
    match(HTLexicon.curlyLeft);
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.endOfFile) {
      if (curTok.lexeme == HTLexicon.ELSE) {
        advance(1);
        match(HTLexicon.singleArrow);
        if (curTok.type == HTLexicon.curlyLeft) {
          elseBranch = _parseBlockStmt(id: SemanticType.elseBranch);
        } else {
          final stmt = _parseStmt();
          elseBranch = BlockStmt([stmt], stmt.line, stmt.column, _curSource,
              id: SemanticType.elseBranch);
        }
      } else {
        final caseExpr = _parseExpr();
        match(HTLexicon.singleArrow);
        late final caseBranch;
        if (curTok.type == HTLexicon.curlyLeft) {
          caseBranch = _parseBlockStmt(id: SemanticType.whenBranch);
        } else {
          final stmt = _parseStmt();
          caseBranch = BlockStmt([stmt], stmt.line, stmt.column, _curSource,
              id: SemanticType.whenBranch);
        }
        options[caseExpr] = caseBranch;
      }
    }
    match(HTLexicon.curlyRight);
    return WhenStmt(options, elseBranch, condition, keyword.line,
        keyword.column, _curSource);
  }

  // 变量声明语句
  VarDeclStmt _parseVarDecl(
      {String? declId,
      String? classId,
      bool typeInferrence = false,
      bool isExternal = false,
      bool isMutable = false,
      bool isStatic = false,
      bool isConst = false,
      bool isExported = false,
      bool lateInitialize = false,
      AstNode? additionalInitializer,
      bool endOfStatement = false}) {
    advance(1);
    var idTok = match(SemanticType.identifier);
    var id = idTok.lexeme;

    if (classId != null && isExternal) {
      if (!(_curClass!.isExternal) && !isStatic) {
        throw HTError.externMember();
      }
      id = '$classId.$id';
    }

    if (declId != null) {
      id = declId;
    }

    var declType;
    if (expect([HTLexicon.colon], consume: true)) {
      declType = _parseTypeExpr();
    }

    var initializer = additionalInitializer;
    if (expect([HTLexicon.assign], consume: true)) {
      initializer = _parseExpr();
    }

    if (endOfStatement) {
      match(HTLexicon.semicolon);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    return VarDeclStmt(id, idTok.line, idTok.column, _curSource,
        classId: classId,
        declType: declType,
        initializer: initializer,
        typeInferrence: typeInferrence,
        isExternal: isExternal,
        isStatic: isStatic,
        isMutable: isMutable,
        isConst: isConst,
        isExported: isExported,
        lateInitialize: lateInitialize);
  }

  FuncDeclExpr _parseFuncDecl(
      {FunctionCategory category = FunctionCategory.normal,
      String? classId,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isExported = false}) {
    final savedCurFuncType = _curFuncType;
    _curFuncType = category;

    final keyword = advance(1);

    String? externalTypedef;
    if (!isExternal &&
        (isStatic ||
            category == FunctionCategory.normal ||
            category == FunctionCategory.literal)) {
      if (expect([HTLexicon.squareLeft], consume: true)) {
        if (isExternal) {
          throw HTError.internalFuncWithExternalTypeDef();
        }
        externalTypedef = match(SemanticType.identifier).lexeme;
        match(HTLexicon.squareRight);
      }
    }

    var declId = '';
    late String id;

    if (curTok.type == SemanticType.identifier) {
      declId = advance(1).lexeme;
    }

    switch (category) {
      case FunctionCategory.constructor:
        id = (declId.isEmpty)
            ? HTLexicon.constructor
            : '${HTLexicon.constructor}$declId';
        break;
      case FunctionCategory.getter:
        id = HTLexicon.getter + declId;
        break;
      case FunctionCategory.setter:
        id = HTLexicon.setter + declId;
        break;
      case FunctionCategory.literal:
        id = HTLexicon.anonymousFunction +
            (AbstractParser.anonymousFuncIndex++).toString();
        break;
      default:
        id = declId;
    }

    final typeParameters = <TypeExpr>[];

    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <ParamDeclExpr>[];

    var hasParamDecls = false;
    if (category != FunctionCategory.getter &&
        expect([HTLexicon.roundLeft], consume: true)) {
      hasParamDecls = true;
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != HTLexicon.roundRight) &&
          (curTok.type != HTLexicon.squareRight) &&
          (curTok.type != HTLexicon.curlyRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        // 可选参数, 根据是否有方括号判断, 一旦开始了可选参数, 则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数, 根据是否有花括号判断
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }

        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
        }

        if (!isNamed && !isVariadic) {
          if (!isOptional) {
            ++minArity;
            ++maxArity;
          } else {
            ++maxArity;
          }
        }

        var paramId = match(SemanticType.identifier);
        TypeExpr? paramDeclType;

        if (expect([HTLexicon.colon], consume: true)) {
          paramDeclType = _parseTypeExpr();
        }

        AstNode? initializer;
        if (expect([HTLexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = _parseExpr();
          } else {
            throw HTError.argInit();
          }
        }

        final param = ParamDeclExpr(
            paramId.lexeme, paramId.line, paramId.column, _curSource,
            declType: paramDeclType,
            initializer: initializer,
            isVariadic: isVariadic,
            isOptional: isOptional,
            isNamed: isNamed);

        paramDecls.add(param);

        if (curTok.type != HTLexicon.squareRight &&
            curTok.type != HTLexicon.curlyRight &&
            curTok.type != HTLexicon.roundRight) {
          match(HTLexicon.comma);
        }

        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }

      if (isOptional) {
        match(HTLexicon.squareRight);
      } else if (isNamed) {
        match(HTLexicon.curlyRight);
      }

      match(HTLexicon.roundRight);

      // setter只能有一个参数, 就是赋值语句的右值
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        throw HTError.setterArity();
      }
    }

    TypeExpr? returnType;
    ReferConstructorExpr? referCtor;
    // the return value type declaration
    if (expect([HTLexicon.singleArrow], consume: true)) {
      if (category == FunctionCategory.constructor) {
        throw HTError.ctorReturn();
      }
      returnType = _parseTypeExpr();
    }
    // referring to another constructor
    else if (expect([HTLexicon.colon], consume: true)) {
      if (category != FunctionCategory.constructor) {
        throw HTError.nonCotrWithReferCtor();
      }
      if (isExternal) {
        throw HTError.externalCtorWithReferCtor();
      }
      final ctorCallee = advance(1);
      if (!HTLexicon.constructorCall.contains(ctorCallee.lexeme)) {
        throw HTError.unexpected(SemanticType.ctorCallExpr, curTok.lexeme);
      }
      String? ctorKey;
      if (expect([HTLexicon.memberGet], consume: true)) {
        ctorKey = match(SemanticType.identifier).lexeme;
        match(HTLexicon.roundLeft);
      } else {
        match(HTLexicon.roundLeft);
      }

      var positionalArgs = <AstNode>[];
      var namedArgs = <String, AstNode>{};
      _handleCallArguments(positionalArgs, namedArgs);

      referCtor = ReferConstructorExpr(
        ctorCallee.lexeme == HTLexicon.SUPER,
        ctorKey,
        positionalArgs,
        namedArgs,
        ctorCallee.line,
        ctorCallee.column,
        _curSource,
      );
    }

    BlockStmt? definition;
    if (curTok.type == HTLexicon.curlyLeft) {
      definition = _parseBlockStmt(id: SemanticType.functionCall);
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(_curClass?.isAbstract ?? false)) {
        throw HTError.missingFuncBody(id);
      }
      expect([HTLexicon.semicolon], consume: true);
    }

    _curFuncType = savedCurFuncType;

    return FuncDeclExpr(
        id, declId, paramDecls, keyword.line, keyword.column, _curSource,
        classId: classId,
        genericParameters: typeParameters,
        externalTypeId: externalTypedef,
        returnType: returnType,
        referConstructor: referCtor,
        hasParamDecls: hasParamDecls,
        minArity: minArity,
        maxArity: maxArity,
        definition: definition,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isFuncVariadic,
        isExported: isExported,
        category: category);
  }

  ClassDeclStmt _parseClassDecl(
      {bool isExternal = false,
      bool isAbstract = false,
      bool isExported = true}) {
    final keyword = match(HTLexicon.CLASS);

    final id = match(SemanticType.identifier);

    // generic type参数
    // final genericParameters = <TypeExpr>[];
    // if (expect([HTLexicon.angleLeft], consume: true)) {
    //   while ((curTok.type != HTLexicon.angleRight) &&
    //       (curTok.type != HTLexicon.endOfFile)) {
    //     if (typeParameters.isNotEmpty) {
    //       match(HTLexicon.comma);
    //     }
    //     typeParameters.add(advance(1).lexeme);
    //   }
    //   match(HTLexicon.angleRight);
    // }

    // 父类
    TypeExpr? superClassType;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      if (curTok.lexeme == id.lexeme) {
        throw HTError.extendsSelf();
      }

      superClassType = _parseTypeExpr();
    }

    final savedClass = _curClass;

    _curClass = ClassDeclaration(id.lexeme, _curModuleFullName, _curLibraryName,
        isExternal: isExternal, isAbstract: isAbstract);

    // 类的定义体
    final definition = _parseBlockStmt(
        sourceType: SourceType.klass,
        createNamespace: false,
        id: SemanticType.classDefinition);

    // _curBlock.classDecls[className.lexeme] = stmt;

    _curClass = savedClass;

    return ClassDeclStmt(id.lexeme, keyword.line, keyword.column, _curSource,
        // genericParameters: genericParameters,
        superType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isExported: isExported,
        definition: definition);
  }

  EnumDeclStmt _parseEnumDecl(
      {bool isExternal = false, bool isExported = true}) {
    final keyword = match(HTLexicon.ENUM);

    final id = match(SemanticType.identifier);

    var enumerations = <String>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while (curTok.type != HTLexicon.curlyRight &&
          curTok.type != HTLexicon.endOfFile) {
        enumerations.add(match(SemanticType.identifier).lexeme);
        if (curTok.type != HTLexicon.curlyRight) {
          match(HTLexicon.comma);
        }
      }
      match(HTLexicon.curlyRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    return EnumDeclStmt(
        id.lexeme, enumerations, keyword.line, keyword.column, _curSource,
        isExternal: isExternal, isExported: isExported);
    // _curBlock.enumDecls[class_name.lexeme] = stmt;
  }

  TypeAliasDeclStmt _parseTypeAliasDecl() {
    final keyword = advance(1);
    final id = match(SemanticType.identifier).lexeme;
    final value = _parseTypeExpr();
    return TypeAliasDeclStmt(
        id, value, keyword.line, keyword.column, _curSource);
  }
}
