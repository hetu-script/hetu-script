import '../grammar/lexicon.dart';
import '../source/source.dart';
import '../core/abstract_parser.dart';
import '../core/lexer.dart';
import '../core/const_table.dart';
import '../core/declaration/abstract_class.dart';
import '../grammar/semantic.dart';
import '../error/errors.dart';
import '../source/source_provider.dart';
import 'ast/ast.dart';
import 'analyzer.dart';
import 'ast_source.dart';

class HTAstParser extends AbstractParser with AnalyzerRef {
  late HTAstCompilation _curCompilation;
  late List<ImportInfo> _curImports;
  late ConstTable _curConstTable;
  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  AbstractClass? _curClass;
  FunctionCategory? _curFuncType;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  Future<HTAstCompilation> parse(
      String content, SourceProvider sourceProvider, String fullName,
      [ParserConfig config = const ParserConfig()]) async {
    this.config = config;
    _curModuleFullName = fullName;
    // _curBlock = _mainBlock = AstDeclarationBlock();
    _curClass = null;
    _curFuncType = null;
    _curCompilation = HTAstCompilation();
    _curImports = <ImportInfo>[];
    _curConstTable = ConstTable();

    final tokens = Lexer().lex(content, fullName);
    addTokens(tokens);
    final code = <AstNode>[];
    while (curTok.type != HTLexicon.endOfFile) {
      final stmt = _parseStmt(sourceType: config.sourceType);
      code.add(stmt);
    }

    // for (final importInfo in _curImports) {
    //   final importedFullName = sourceProvider.resolveFullName(importInfo.key);
    //   if (!sourceProvider.hasModule(importedFullName)) {
    //     _curModuleFullName = importedFullName;
    //     final importedContent = await sourceProvider.getSource(importedFullName,
    //         curModuleFullName: _curModuleFullName);
    //     final parser2 = HTAstParser(interpreter);
    //     final compilation2 = await parser2.parse(
    //         importedContent.content, sourceProvider, importedFullName);

    //     _curCompilation.addAll(compilation2);
    //   }
    // }

    // final decls = <AstNode>[];
    // // 将变量表前置, 总是按照：枚举、函数、类、变量这个顺序
    // for (final decl in _mainBlock.enumDecls.values) {
    //   decls.add(decl);
    // }
    // for (final decl in _mainBlock.funcDecls.values) {
    //   decls.add(decl);
    // }
    // for (final decl in _mainBlock.classDecls.values) {
    //   decls.add(decl);
    // }
    // for (final decl in _mainBlock.varDecls.values) {
    //   decls.add(decl);
    // }

    _curCompilation
        .add(HTAstModule(fullName, content, [...code], _curConstTable));

    return _curCompilation;
  }

  AstNode _parseStmt({SourceType sourceType = SourceType.function}) {
    switch (sourceType) {
      case SourceType.script:
        switch (curTok.type) {
          case HTLexicon.IMPORT:
            return _parseImportStmt();
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.ABSTRACT:
                advance(1);
                if (curTok.type != HTLexicon.CLASS) {
                  throw HTError.unexpected(
                      SemanticType.classDecl, curTok.lexeme);
                }
                return _parseClassDeclStmt(isAbstract: true, isExternal: true);
              case HTLexicon.CLASS:
                return _parseClassDeclStmt(isExternal: true);
              case HTLexicon.ENUM:
                return _parseEnumDeclStmt(isExternal: true);
              case HTLexicon.VAR:
              case HTLexicon.LET:
              case HTLexicon.CONST:
                throw HTError.externalVar();
              case HTLexicon.FUNCTION:
                if (!expect([HTLexicon.FUNCTION, SemanticType.identifier])) {
                  throw HTError.unexpected(
                      SemanticType.funcDecl, peek(1).lexeme);
                }
                return _parseFuncDeclaration(isExternal: true);
              default:
                throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
            }
          case HTLexicon.ABSTRACT:
            advance(1);
            if (curTok.type != HTLexicon.CLASS) {
              throw HTError.unexpected(SemanticType.classDecl, curTok.lexeme);
            }
            return _parseClassDeclStmt(isAbstract: true);
          case HTLexicon.ENUM:
            return _parseEnumDeclStmt();
          case HTLexicon.CLASS:
            return _parseClassDeclStmt();
          case HTLexicon.VAR:
            return _parseVarDeclStmt();
          case HTLexicon.LET:
            return _parseVarDeclStmt(typeInferrence: true);
          case HTLexicon.CONST:
            return _parseVarDeclStmt(typeInferrence: true, isImmutable: true);
          case HTLexicon.FUNCTION:
            if (expect([HTLexicon.FUNCTION, SemanticType.identifier]) ||
                expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  SemanticType.identifier,
                  HTLexicon.squareRight,
                  SemanticType.identifier
                ])) {
              return _parseFuncDeclaration();
            } else {
              return _parseExprStmt();
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
      case SourceType.module:
        switch (curTok.type) {
          case HTLexicon.IMPORT:
            return _parseImportStmt();
          case HTLexicon.ABSTRACT:
            advance(1);
            if (curTok.type != HTLexicon.CLASS) {
              throw HTError.unexpected(SemanticType.classDecl, curTok.lexeme);
            }
            return _parseClassDeclStmt(isAbstract: true);
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.ABSTRACT:
                advance(1);
                if (curTok.type != HTLexicon.CLASS) {
                  throw HTError.unexpected(
                      SemanticType.classDecl, curTok.lexeme);
                }
                return _parseClassDeclStmt(isAbstract: true, isExternal: true);
              case HTLexicon.CLASS:
                return _parseClassDeclStmt(isExternal: true);
              case HTLexicon.ENUM:
                return _parseEnumDeclStmt(isExternal: true);
              case HTLexicon.FUNCTION:
                if (!expect([HTLexicon.FUNCTION, SemanticType.identifier])) {
                  throw HTError.unexpected(
                      SemanticType.funcDecl, peek(1).lexeme);
                }
                return _parseFuncDeclaration();
              case HTLexicon.VAR:
              case HTLexicon.LET:
              case HTLexicon.CONST:
                throw HTError.externalVar();
              default:
                throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
            }
          case HTLexicon.ENUM:
            return _parseEnumDeclStmt();
          case HTLexicon.CLASS:
            return _parseClassDeclStmt();
          case HTLexicon.VAR:
            return _parseVarDeclStmt(lateInitialize: true);
          case HTLexicon.LET:
            return _parseVarDeclStmt(
                typeInferrence: true, lateInitialize: true);
          case HTLexicon.CONST:
            return _parseVarDeclStmt(
                typeInferrence: true, isImmutable: true, lateInitialize: true);
          case HTLexicon.FUNCTION:
            return _parseFuncDeclaration();
          default:
            throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
        }
      case SourceType.function:
        switch (curTok.type) {
          case HTLexicon.VAR:
            return _parseVarDeclStmt();
          case HTLexicon.LET:
            return _parseVarDeclStmt(typeInferrence: true);
          case HTLexicon.CONST:
            return _parseVarDeclStmt(typeInferrence: true, isImmutable: true);
          case HTLexicon.FUNCTION:
            if (!expect([HTLexicon.FUNCTION, SemanticType.identifier]) &&
                !expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  SemanticType.identifier,
                  HTLexicon.squareRight,
                  SemanticType.identifier
                ])) {
              return _parseFuncDeclaration(category: FunctionCategory.literal);
            } else {
              return _parseExprStmt();
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
            return BreakStmt(keyword, keyword.line, keyword.column);
          case HTLexicon.CONTINUE:
            final keyword = advance(1);
            return ContinueStmt(keyword, keyword.line, keyword.column);
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
          case HTLexicon.VAR:
            return _parseVarDeclStmt(
                isMember: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.LET:
            return _parseVarDeclStmt(
                isMember: true,
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.CONST:
            return _parseVarDeclStmt(
                isMember: true,
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isImmutable: true,
                isStatic: isStatic,
                lateInitialize: true);
          case HTLexicon.FUNCTION:
            return _parseFuncDeclaration(
                category: FunctionCategory.method,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
          case HTLexicon.CONSTRUCT:
            if (isStatic) {
              throw HTError.unexpected(
                  SemanticType.declStmt, HTLexicon.CONSTRUCT);
            }
            return _parseFuncDeclaration(
              category: FunctionCategory.constructor,
              isExternal: isExternal || (_curClass?.isExternal ?? false),
            );
          case HTLexicon.GET:
            return _parseFuncDeclaration(
                category: FunctionCategory.getter,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
          case HTLexicon.SET:
            return _parseFuncDeclaration(
                category: FunctionCategory.setter,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
          default:
            throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
        }
      case SourceType.expression:
        return _parseExpr();
    }
  }

  ImportStmt _parseImportStmt() {
    final keyword = advance(1);
    String key = match(HTLexicon.string).literal;
    String? alias;
    if (expect([HTLexicon.AS], consume: true)) {
      alias = match(SemanticType.identifier).lexeme;

      if (alias.isEmpty) {
        throw HTError.emptyString();
      }
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

    _curImports.add(ImportInfo(key, name: alias, showList: showList));

    return ImportStmt(key, alias, showList, keyword.line, keyword.column);
  }

  /// 使用递归向下的方法生成表达式, 不断调用更底层的, 优先级更高的子Parser
  ///
  /// 赋值 = , 优先级 1, 右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  AstNode _parseExpr() {
    var left = _parserTernaryExpr();
    if (HTLexicon.assignments.contains(curTok.type)) {
      if (!_leftValueLegality) {
        throw HTError.invalidLeftValue();
      }
      final op = advance(1);
      // right combination: recursively use this same function on next expr
      final right = _parseExpr();
      left = BinaryExpr(left, op.lexeme, right, op.line, op.column);
    }
    return left;
  }

  AstNode _parserTernaryExpr() {
    var condition = _parseLogicalOrExpr();
    if (expect([HTLexicon.condition], consume: true)) {
      _leftValueLegality = false;
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
      final elseBranch = _parserTernaryExpr();
      condition = TernaryExpr(
          condition, thenBranch, elseBranch, condition.line, condition.column);
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
        left = BinaryExpr(left, op.lexeme, right, op.line, op.column);
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
        left = BinaryExpr(left, op.lexeme, right, op.line, op.column);
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
      left = BinaryExpr(left, op.lexeme, right, op.line, op.column);
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
      left = BinaryExpr(left, op.lexeme, right, op.line, op.column);
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
      final right = _parseTypeExpr();
      left = BinaryExpr(left, op, right, opTok.line, opTok.column);
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
        left = BinaryExpr(left, op.lexeme, right, op.line, op.column);
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
        left = BinaryExpr(left, op.lexeme, right, op.line, op.column);
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
      return UnaryPrefixExpr(op.lexeme, value, op.line, op.column);
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
          final name = match(SemanticType.identifier).lexeme;
          expr = MemberExpr(expr, name, op.line, op.column);
          break;
        case HTLexicon.subGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.squareRight);
          expr = SubGetExpr(expr, indexExpr, op.line, op.column);
          break;
        case HTLexicon.call:
          // TODO: typeArgs: typeArgs
          _leftValueLegality = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
          _handleCallArguments(positionalArgs, namedArgs);
          expr = CallExpr(expr, positionalArgs, namedArgs, op.line, op.column);
          break;
        case HTLexicon.postIncrement:
        case HTLexicon.postDecrement:
          _leftValueLegality = false;
          expr = UnaryPostfixExpr(expr, op.lexeme, op.line, op.column);
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
        final word = advance(1);
        return NullExpr(word.line, word.column);
      case HTLexicon.boolean:
        _leftValueLegality = false;
        final word = advance(1);
        return BooleanExpr(word.literal, word.line, word.column);
      case HTLexicon.integer:
        _leftValueLegality = false;
        final word = advance(1);
        var index = _curConstTable.addInt(word.literal);
        return ConstIntExpr(index, word.line, word.column);
      case HTLexicon.float:
        _leftValueLegality = false;
        final word = advance(1);
        var index = _curConstTable.addFloat(word.literal);
        return ConstFloatExpr(index, word.line, word.column);
      case HTLexicon.string:
        _leftValueLegality = false;
        final word = advance(1);
        var index = _curConstTable.addString(word.literal);
        return ConstStringExpr(index, word.line, word.column);
      case HTLexicon.THIS:
        _leftValueLegality = false;
        final keyword = advance(1);
        return SymbolExpr(keyword.lexeme, keyword.line, keyword.column);
      case HTLexicon.SUPER:
        _leftValueLegality = false;
        final keyword = advance(1);
        return SymbolExpr(keyword.lexeme, keyword.line, keyword.column);
      case HTLexicon.roundLeft:
        _leftValueLegality = false;
        final punc = advance(1);
        final innerExpr = _parseExpr();
        match(HTLexicon.roundRight);
        return GroupExpr(innerExpr, punc.line, punc.column);
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
        return LiteralListExpr(line, column, list: listExpr);
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
        return LiteralMapExpr(line, column, map: mapExpr);

      case HTLexicon.FUNCTION:
        return _parseFuncDeclaration(category: FunctionCategory.literal);
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
          return SymbolExpr(symbol.lexeme, symbol.line, symbol.column);
        }
      default:
        throw HTError.unexpected(SemanticType.expression, curTok.lexeme);
    }
  }

  TypeExpr _parseTypeExpr() {
    // function type
    if (expect([HTLexicon.function, HTLexicon.roundLeft], consume: true)) {
      final keyword = peek(-2);

      // TODO: genericTypeParameters 泛型参数

      final paramTypes = <ParamType>[];

      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;

      while (curTok.type != HTLexicon.roundRight &&
          curTok.type != HTLexicon.endOfFile) {
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

        final param = ParamType(
            isOptional: isOptional,
            isVariadic: isVariadic,
            id: paramId,
            paramType: paramType);
        paramTypes.add(param);

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

      return FunctionTypeExpr(returnType, keyword.line, keyword.column,
          paramTypes: paramTypes);
    }
    // TODO: interface type
    else {
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

      return TypeExpr(id.lexeme, id.line, id.column,
          arguments: typeArgs, isNullable: isNullable);
    }
  }

  BlockStmt _parseBlockStmt({SourceType sourceType = SourceType.function}) {
    // final savedDeclBlock = _curBlock;
    // _curBlock = AstDeclarationBlock();
    final token = match(HTLexicon.curlyLeft);
    final statements = <AstNode>[];
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.endOfFile) {
      final stmt = _parseStmt(sourceType: sourceType);
      statements.add(stmt);
    }
    match(HTLexicon.curlyRight);
    // _curBlock = savedDeclBlock;
    return BlockStmt(statements, token.line, token.column);
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
    return ExprStmt(expr, curTok.line, curTok.column);
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
    return ReturnStmt(keyword, expr, keyword.line, keyword.column);
  }

  IfStmt _parseIfStmt() {
    final keyword = advance(1);
    match(HTLexicon.roundLeft);
    var condition = _parseExpr();
    match(HTLexicon.roundRight);
    late BlockStmt thenBranch;
    if (curTok.type == HTLexicon.curlyLeft) {
      thenBranch = _parseBlockStmt();
    } else {
      final stmt = _parseStmt();
      thenBranch = BlockStmt([stmt], stmt.line, stmt.column);
    }
    AstNode? elseBranch;
    if (expect([HTLexicon.ELSE], consume: true)) {
      if (curTok.type == HTLexicon.curlyLeft) {
        elseBranch = _parseBlockStmt();
      } else {
        elseBranch = _parseStmt();
      }
    }
    return IfStmt(
        condition, thenBranch, elseBranch, keyword.line, keyword.column);
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
      loop = _parseBlockStmt();
    } else {
      final stmt = _parseStmt();
      loop = BlockStmt([stmt], stmt.line, stmt.column);
    }
    return WhileStmt(condition, loop, keyword.line, keyword.column);
  }

  DoStmt _parseDoStmt() {
    final keyword = advance(1);
    late BlockStmt loop;
    if (curTok.type == HTLexicon.curlyLeft) {
      loop = _parseBlockStmt();
    } else {
      final stmt = _parseStmt();
      loop = BlockStmt([stmt], stmt.line, stmt.column);
    }
    AstNode? condition;
    if (expect([HTLexicon.WHILE], consume: true)) {
      match(HTLexicon.roundLeft);
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    return DoStmt(loop, condition, keyword.line, keyword.column);
  }

  // For语句其实会在解析时转换为While语句
  AstNode _parseForStmt() {
    final keyword = advance(1);
    match(HTLexicon.roundLeft);
    final forStmtType = peek(2).lexeme;
    AstNode? declaration;
    AstNode? condition;
    AstNode? increment;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.IN) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        throw HTError.unexpected(SemanticType.varDecl, curTok.type);
      }
      declaration = _parseVarDeclStmt(
          typeInferrence: curTok.type != HTLexicon.VAR,
          isImmutable: curTok.type == HTLexicon.CONST);

      advance(1);

      final collection = _parseExpr();

      match(HTLexicon.roundRight);

      final loop = _parseBlockStmt();

      return ForInStmt(
          declaration, collection, loop, keyword.line, keyword.column);
    } else {
      if (!expect([HTLexicon.semicolon], consume: false)) {
        // final declId = peek(1);
        // final markedId = '${HTLexicon.internalMarker}$declId';
        // newSymbolMap[declId.lexeme] = markedId;
        declaration = _parseVarDeclStmt(
            // declId: markedId,
            typeInferrence: curTok.type != HTLexicon.VAR,
            isImmutable: curTok.type == HTLexicon.CONST,
            endOfStatement: true);

        // statements.add(declaration);
        // // TODO: 这里是为了实现闭包效果，之后应该改成真正的闭包
        // final capturedInit = SymbolExpr(markedId, declId.line, declId.column);
        // final capturedDecl = VarDecl(markedId, declId.line, declId.column,
        //     initializer: capturedInit, lateInitialize: false);
        // additionalVarDecls.add(capturedDecl);
      } else {
        match(HTLexicon.semicolon);
      }

      if (!expect([HTLexicon.semicolon], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);

      if (!expect([HTLexicon.semicolon], consume: false)) {
        increment = _parseExpr();
      }
      match(HTLexicon.roundRight);

      final loop = _parseBlockStmt();

      return ForStmt(declaration, condition, increment, loop, keyword.line,
          keyword.column);
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
          elseBranch = _parseBlockStmt();
        } else {
          final stmt = _parseStmt();
          elseBranch = BlockStmt([stmt], stmt.line, stmt.column);
        }
      } else {
        final caseExpr = _parseExpr();
        match(HTLexicon.singleArrow);
        late final caseBranch;
        if (curTok.type == HTLexicon.curlyLeft) {
          caseBranch = _parseBlockStmt();
        } else {
          final stmt = _parseStmt();
          caseBranch = BlockStmt([stmt], stmt.line, stmt.column);
        }
        options[caseExpr] = caseBranch;
      }
    }
    match(HTLexicon.curlyRight);
    return WhenStmt(
        options, elseBranch, condition, keyword.line, keyword.column);
  }

  // 变量声明语句
  VarDecl _parseVarDeclStmt(
      {String? declId,
      bool isMember = false,
      bool typeInferrence = false,
      bool isExternal = false,
      bool isImmutable = false,
      bool isStatic = false,
      bool lateInitialize = false,
      AstNode? additionalInitializer,
      bool endOfStatement = false}) {
    advance(1);
    var idTok = match(SemanticType.identifier);
    var id = idTok.lexeme;

    if (isMember && isExternal) {
      if (!(_curClass!.isExternal) && !isStatic) {
        throw HTError.externMember();
      }
      id = '${_curClass!.id}.$id';
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

    // 语句结尾
    if (endOfStatement) {
      match(HTLexicon.semicolon);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    return VarDecl(id, idTok.line, idTok.column,
        declType: declType,
        initializer: initializer,
        typeInferrence: typeInferrence,
        isExternal: isExternal,
        isImmutable: isImmutable,
        isStatic: isStatic,
        lateInitialize: lateInitialize);
  }

  FuncDecl _parseFuncDeclaration(
      {FunctionCategory category = FunctionCategory.normal,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false}) {
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

    if (category != FunctionCategory.literal) {
      if (category == FunctionCategory.constructor) {
        if (curTok.type == SemanticType.identifier) {
          declId = advance(1).lexeme;
        }
      } else {
        declId = match(SemanticType.identifier).lexeme;
      }
    }

    // if (!isExternal) {
    switch (category) {
      case FunctionCategory.constructor:
        id = (declId.isEmpty)
            ? HTLexicon.constructor
            : '${HTLexicon.constructor}$declId';
        // if (_curBlock.contains(id)) {
        //   throw HTError.definedParser(declId);
        // }
        break;
      case FunctionCategory.getter:
        id = HTLexicon.getter + declId;
        // if (_curBlock.contains(id)) {
        //   throw HTError.definedParser(declId);
        // }
        break;
      case FunctionCategory.setter:
        id = HTLexicon.setter + declId;
        // if (_curBlock.contains(id)) {
        //   throw HTError.definedParser(declId);
        // }
        break;
      case FunctionCategory.literal:
        id = HTLexicon.anonymousFunction +
            (AbstractParser.anonymousFuncIndex++).toString();
        break;
      default:
        id = declId;
    }
    // } else {
    //   if (_curClass != null) {
    //     if (!(_curClass!.isExternal) && !isStatic) {
    //       throw HTError.externalMember();
    //     }
    //     if (isStatic || (category == FunctionType.constructor)) {
    //       id = (declId.isEmpty) ? _curClass!.id : '${_curClass!.id}.$declId';
    //     } else {
    //       id = declId;
    //     }
    //   } else {
    //     id = declId;
    //   }
    // }

    // if (functype == FuncStmtType.normal) {
    //   if (_declarations.containsKey(func_name)) throw HTErrorDefined(func_name, fileName, curTok.line, curTok.column);
    // }

    final typeParameters = <TypeExpr>[];

    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <ParamDecl>[];

    if (category != FunctionCategory.getter &&
        expect([HTLexicon.roundLeft], consume: true)) {
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

        final param = ParamDecl(paramId.lexeme, paramId.line, paramId.column,
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

      // setter只能有一个参数, 就是赋值语句的右值, 但此处并不需要判断类型
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        throw HTError.setterArity();
      }
    }

    TypeExpr? returnType;
    CallExpr? referCtor;
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

      final ctorToken = advance(1);
      if (!HTLexicon.constructorCall.contains(ctorToken.lexeme)) {
        throw HTError.unexpected(SemanticType.ctorCallExpr, curTok.lexeme);
      }

      late ReferConstructorExpr referCtorExpr;
      if (expect([HTLexicon.memberGet], consume: true)) {
        final ctorCallName = match(SemanticType.identifier).lexeme;
        match(HTLexicon.roundLeft);
        referCtorExpr = ReferConstructorExpr(
          ctorToken.lexeme == HTLexicon.SUPER,
          ctorToken.line,
          ctorToken.column,
          name: ctorCallName,
        );
      } else {
        match(HTLexicon.roundLeft);
        referCtorExpr = ReferConstructorExpr(
            ctorToken.lexeme == HTLexicon.SUPER,
            ctorToken.line,
            ctorToken.column);
      }

      var positionalArgs = <AstNode>[];
      var namedArgs = <String, AstNode>{};
      _handleCallArguments(positionalArgs, namedArgs);

      referCtor = CallExpr(referCtorExpr, positionalArgs, namedArgs,
          ctorToken.line, ctorToken.column);
    }

    BlockStmt? definition;
    if (curTok.type == HTLexicon.curlyLeft) {
      // 处理函数定义部分的语句块
      definition = _parseBlockStmt();
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

    return FuncDecl(id, declId, paramDecls, keyword.line, keyword.column,
        classId: _curClass?.id,
        typeParameters: typeParameters,
        externalTypedef: externalTypedef,
        returnType: returnType,
        referCtor: referCtor,
        minArity: minArity,
        maxArity: maxArity,
        definition: definition,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isFuncVariadic,
        category: category);
  }

  ClassDecl _parseClassDeclStmt(
      {bool isExternal = false, bool isAbstract = false}) {
    // 已经判断过了所以直接跳过关键字
    final keyword = advance(1);

    final id = match(SemanticType.identifier);

    final typeParameters = <TypeExpr>[];

    // if (_mainBlock.contains(className.lexeme)) {
    //   throw HTError.definedParser(className.lexeme);
    // }

    final savedClass = _curClass;

    // final savedClassId = _curClassId;
    // final savedClassType = _curClassType;
    // final savedClassType = _curClassType;
    // _curClassId = className.lexeme;
    // _curClassType = classType;
    // _curClassType = HTType(className.lexeme);

    _curClass = AbstractClass(id.lexeme,
        isExternal: isExternal, isAbstract: isAbstract);

    // generic type参数
    // var typeParameters = <String>[];
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

    // 继承父类
    TypeExpr? superClassType;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      if (curTok.lexeme == id.lexeme) {
        throw HTError.extendsSelf();
      }

      superClassType = _parseTypeExpr();

      // else if (!_mainBlock.contains(curTok.lexeme)) {
      //   throw HTError.notClass(curTok.lexeme);
      // }
    }

    // 类的定义体
    final definition = _parseBlockStmt(sourceType: SourceType.klass);

    // _curBlock.classDecls[className.lexeme] = stmt;

    _curClass = savedClass;

    return ClassDecl(id.lexeme, definition, keyword.line, keyword.column,
        typeParameters: typeParameters,
        superClassType: superClassType,
        isExternal: isExternal,
        isAbstract: isAbstract);
  }

  EnumDecl _parseEnumDeclStmt({bool isExternal = false}) {
    // 已经判断过了所以直接跳过关键字
    final keyword = advance(1);

    final id = match(SemanticType.identifier);

    // if (_mainBlock.contains(class_name.lexeme)) {
    //   throw HTError.definedParser(class_name.lexeme);
    // }

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

    return EnumDecl(id.lexeme, enumerations, keyword.line, keyword.column,
        isExternal: isExternal);
    // _curBlock.enumDecls[class_name.lexeme] = stmt;
  }
}
