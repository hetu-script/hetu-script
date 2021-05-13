import '../grammar/lexicon.dart';
import '../source/source.dart';
import '../core/parser.dart';
import '../core/lexer.dart';
import '../core/token.dart';
import '../core/const_table.dart';
import '../core/class/class.dart';
import '../grammar/semantic.dart';
import '../error/errors.dart';
import '../source/source_provider.dart';
import 'ast.dart';
import 'analyzer.dart';
import 'ast_source.dart';

class AstDeclarationBlock implements DeclarationBlock {
  final enumDecls = <String, EnumDecl>{};
  final funcDecls = <String, FuncDecl>{};
  final classDecls = <String, ClassDecl>{};
  final varDecls = <String, VarDecl>{};

  @override
  bool contains(String id) =>
      enumDecls.containsKey(id) ||
      funcDecls.containsKey(id) ||
      classDecls.containsKey(id) ||
      varDecls.containsKey(id);
}

class HTAstParser extends Parser with AnalyzerRef {
  late AstDeclarationBlock _mainBlock;
  late AstDeclarationBlock _curBlock;
  late HTAstCompilation _curCompilation;
  late List<ImportInfo> _curImports;
  late ConstTable _curConstTable;
  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  ClassInfo? _curClass;
  FunctionCategory? _curFuncType;

  var _leftValueLegality = false;

  HTAstParser(HTAnalyzer interpreter) {
    this.interpreter = interpreter;
  }

  Future<HTAstCompilation> parse(
      String content, SourceProvider sourceProvider, String fullName,
      [ParserConfig config = const ParserConfig()]) async {
    this.config = config;
    _curModuleFullName = fullName;
    _curBlock = _mainBlock = AstDeclarationBlock();
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
      if (stmt != null) {
        code.add(stmt);
      }
    }

    for (final importInfo in _curImports) {
      final importedFullName = sourceProvider.resolveFullName(importInfo.key);
      if (!sourceProvider.hasModule(importedFullName)) {
        _curModuleFullName = importedFullName;
        final importedContent = await sourceProvider.getSource(importedFullName,
            curModuleFullName: _curModuleFullName);
        final parser2 = HTAstParser(interpreter);
        final compilation2 = await parser2.parse(
            importedContent.content, sourceProvider, importedFullName);

        _curCompilation.addAll(compilation2);
      }
    }

    final decls = <AstNode>[];
    // 将变量表前置, 总是按照：枚举、函数、类、变量这个顺序
    for (final decl in _mainBlock.enumDecls.values) {
      decls.add(decl);
    }
    for (final decl in _mainBlock.funcDecls.values) {
      decls.add(decl);
    }
    for (final decl in _mainBlock.classDecls.values) {
      decls.add(decl);
    }
    for (final decl in _mainBlock.varDecls.values) {
      decls.add(decl);
    }

    _curCompilation.add(
        HTAstModule(fullName, content, [...decls, ...code], _curConstTable));

    return _curCompilation;
  }

  AstNode? _parseStmt({SourceType sourceType = SourceType.module}) {
    switch (sourceType) {
      case SourceType.script:
        switch (curTok.type) {
          case HTLexicon.IMPORT:
            _parseImportStmt();
            break;
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.ABSTRACT:
                advance(1);
                if (curTok.type == HTLexicon.CLASS) {
                  _parseClassDeclStmt(isAbstract: true, isExternal: true);
                } else {
                  throw HTError.unexpected(
                      SemanticType.classDecl, curTok.lexeme);
                }
                break;
              case HTLexicon.CLASS:
                _parseClassDeclStmt(isExternal: true);
                break;
              case HTLexicon.ENUM:
                _parseEnumDeclStmt(isExternal: true);
                break;
              case HTLexicon.VAR:
              case HTLexicon.LET:
              case HTLexicon.CONST:
                throw HTError.externalVar();
              case HTLexicon.FUNCTION:
                if (expect([HTLexicon.FUNCTION, HTLexicon.identifier])) {
                  _parseFuncDeclaration(isExternal: true);
                } else {
                  throw HTError.unexpected(
                      SemanticType.funcDecl, peek(1).lexeme);
                }
                break;
              default:
                throw HTError.unexpected(HTLexicon.declStmt, curTok.lexeme);
            }
            break;
          case HTLexicon.ABSTRACT:
            advance(1);
            if (curTok.type == HTLexicon.CLASS) {
              _parseClassDeclStmt(isAbstract: true);
            } else {
              throw HTError.unexpected(SemanticType.classDecl, curTok.lexeme);
            }
            break;
          case HTLexicon.ENUM:
            _parseEnumDeclStmt();
            break;
          case HTLexicon.CLASS:
            _parseClassDeclStmt();
            break;
          case HTLexicon.VAR:
            _parseVarDeclStmt();
            break;
          case HTLexicon.LET:
            _parseVarDeclStmt(typeInferrence: true);
            break;
          case HTLexicon.CONST:
            _parseVarDeclStmt(typeInferrence: true, isImmutable: true);
            break;
          case HTLexicon.FUNCTION:
            if (expect([HTLexicon.FUNCTION, HTLexicon.identifier]) ||
                expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  HTLexicon.identifier,
                  HTLexicon.squareRight,
                  HTLexicon.identifier
                ])) {
              _parseFuncDeclaration();
            } else {
              return _parseExprStmt();
            }
            break;
          case HTLexicon.IF:
            return _parseIfStmt();
          case HTLexicon.WHILE:
            return _parseWhileStmt();
          case HTLexicon.DO:
          // return _parseDoStmt();
          case HTLexicon.FOR:
            return _parseForStmt();
          case HTLexicon.WHEN:
          // return _parseWhenStmt();
          case HTLexicon.semicolon:
            advance(1);
            return null;
          default:
            return _parseExprStmt();
        }
        break;
      case SourceType.module:
        switch (curTok.type) {
          case HTLexicon.IMPORT:
            _parseImportStmt();
            break;
          case HTLexicon.ABSTRACT:
            advance(1);
            if (curTok.type == HTLexicon.CLASS) {
              _parseClassDeclStmt(isAbstract: true);
            } else {
              throw HTError.unexpected(SemanticType.classDecl, curTok.lexeme);
            }
            break;
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.ABSTRACT:
                advance(1);
                if (curTok.type == HTLexicon.CLASS) {
                  _parseClassDeclStmt(isAbstract: true, isExternal: true);
                } else {
                  throw HTError.unexpected(
                      SemanticType.classDecl, curTok.lexeme);
                }
                break;
              case HTLexicon.CLASS:
                _parseClassDeclStmt(isExternal: true);
                break;
              case HTLexicon.ENUM:
                _parseEnumDeclStmt(isExternal: true);
                break;
              case HTLexicon.FUNCTION:
                if (expect([HTLexicon.FUNCTION, HTLexicon.identifier])) {
                  _parseFuncDeclaration();
                } else {
                  throw HTError.unexpected(
                      SemanticType.funcDecl, peek(1).lexeme);
                }
                break;
              case HTLexicon.VAR:
              case HTLexicon.LET:
              case HTLexicon.CONST:
                throw HTError.externalVar();
              default:
                throw HTError.unexpected(HTLexicon.declStmt, curTok.lexeme);
            }
            break;
          case HTLexicon.ENUM:
            _parseEnumDeclStmt();
            break;
          case HTLexicon.CLASS:
            _parseClassDeclStmt();
            break;
          case HTLexicon.VAR:
            _parseVarDeclStmt(lateInitialize: true);
            break;
          case HTLexicon.LET:
            _parseVarDeclStmt(typeInferrence: true, lateInitialize: true);
            break;
          case HTLexicon.CONST:
            _parseVarDeclStmt(
                typeInferrence: true, isImmutable: true, lateInitialize: true);
            break;
          case HTLexicon.FUNCTION:
            if (expect([HTLexicon.FUNCTION, HTLexicon.identifier]) ||
                expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  HTLexicon.identifier,
                  HTLexicon.squareRight,
                  HTLexicon.identifier
                ])) {
              _parseFuncDeclaration();
            } else {
              throw HTError.unexpected(SemanticType.funcDecl, peek(1).lexeme);
            }
            break;
          default:
            throw HTError.unexpected(HTLexicon.declStmt, curTok.lexeme);
        }
        break;
      case SourceType.function:
        switch (curTok.type) {
          case HTLexicon.VAR:
            _parseVarDeclStmt();
            break;
          case HTLexicon.LET:
            _parseVarDeclStmt(typeInferrence: true);
            break;
          case HTLexicon.CONST:
            _parseVarDeclStmt(typeInferrence: true, isImmutable: true);
            break;
          case HTLexicon.FUNCTION:
            if (expect([HTLexicon.FUNCTION, HTLexicon.identifier]) ||
                expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  HTLexicon.identifier,
                  HTLexicon.squareRight,
                  HTLexicon.identifier
                ])) {
              _parseFuncDeclaration();
            } else {
              return _parseFuncDeclaration(category: FunctionCategory.literal);
            }
            break;
          case HTLexicon.IF:
            return _parseIfStmt();
          case HTLexicon.WHILE:
            return _parseWhileStmt();
          case HTLexicon.DO:
          // return _parseDoStmt();
          case HTLexicon.FOR:
            return _parseForStmt();
          case HTLexicon.WHEN:
          // return _parseWhenStmt();
          case HTLexicon.BREAK:
            return BreakStmt(advance(1));
          case HTLexicon.CONTINUE:
            return ContinueStmt(advance(1));
          case HTLexicon.RETURN:
            if (_curFuncType != null &&
                _curFuncType != FunctionCategory.constructor) {
              return _parseReturnStmt();
            } else {
              throw HTError.outsideReturn();
            }
          case HTLexicon.semicolon:
            advance(1);
            break;
          default:
            return _parseExprStmt();
        }
        break;
      case SourceType.klass:
        final isExternal = expect([HTLexicon.EXTERNAL], consume: true);
        final isStatic = expect([HTLexicon.STATIC], consume: true);
        switch (curTok.type) {
          case HTLexicon.VAR:
            _parseVarDeclStmt(
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic,
                lateInitialize: true);
            break;
          case HTLexicon.LET:
            _parseVarDeclStmt(
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic,
                lateInitialize: true);
            break;
          case HTLexicon.CONST:
            _parseVarDeclStmt(
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isImmutable: true,
                isStatic: isStatic,
                lateInitialize: true);
            break;
          case HTLexicon.FUNCTION:
            _parseFuncDeclaration(
                category: FunctionCategory.method,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
            break;
          case HTLexicon.CONSTRUCT:
            if (_curClass!.isAbstract) {
              throw HTError.abstractCtor();
            }
            if (isStatic) {
              throw HTError.unexpected(HTLexicon.declStmt, HTLexicon.CONSTRUCT);
            }
            _parseFuncDeclaration(
              category: FunctionCategory.constructor,
              isExternal: isExternal || (_curClass?.isExternal ?? false),
            );
            break;
          case HTLexicon.GET:
            _parseFuncDeclaration(
                category: FunctionCategory.getter,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
            break;
          case HTLexicon.SET:
            _parseFuncDeclaration(
                category: FunctionCategory.setter,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
            break;
          default:
            throw HTError.unexpected(HTLexicon.declStmt, curTok.lexeme);
        }
        break;
      case SourceType.expression:
        return _parseExpr();
    }
  }

  void _parseImportStmt() {
    // 之前校验过了所以这里直接跳过
    advance(1);
    String key = match(HTLexicon.string).literal;
    String? alias;
    if (expect([HTLexicon.AS], consume: true)) {
      alias = match(HTLexicon.identifier).lexeme;

      if (alias.isEmpty) {
        throw HTError.emptyString();
      }
    }

    final showList = <String>[];
    if (expect([HTLexicon.SHOW], consume: true)) {
      while (curTok.type == HTLexicon.identifier) {
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
      final op = advance(1).type;
      // right combination: recursively use this same function on next expr
      final right = _parseExpr();
      left = BinaryExpr(left, op, right);
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
      condition = TernaryExpr(condition, thenBranch, elseBranch);
    }
    return condition;
  }

  /// 逻辑或 or , 优先级 5, 左合并
  AstNode _parseLogicalOrExpr() {
    var left = _parseLogicalAndExpr();
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        final op = advance(1).type; // and operator
        final right = _parseLogicalAndExpr();
        left = BinaryExpr(left, op, right);
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
        final op = advance(1).type; // and operator
        final right = _parseEqualityExpr();
        left = BinaryExpr(left, op, right);
      }
    }
    return left;
  }

  /// 逻辑相等 ==, !=, 优先级 7, 不合并
  AstNode _parseEqualityExpr() {
    var left = _parseRelationalExpr();
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1).type;
      final right = _parseRelationalExpr();
      left = BinaryExpr(left, op, right);
    }
    return left;
  }

  /// 逻辑比较 <, >, <=, >=, as, is, is! 优先级 8, 不合并
  AstNode _parseRelationalExpr() {
    var left = _parseAdditiveExpr();
    if (HTLexicon.logicalRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      final op = advance(1).type;
      final right = _parseAdditiveExpr();
      left = BinaryExpr(left, op, right);
    } else if (HTLexicon.typeRelationals.contains(curTok.type)) {
      _leftValueLegality = false;
      var op = advance(1).type;
      if (peek(1).type == HTLexicon.logicalNot) {
        op = HTLexicon.ISNOT;
      }
      final right = _parseTypeExpr();
      left = BinaryExpr(left, op, right);
    }
    return left;
  }

  /// 加法 +, -, 优先级 13, 左合并
  AstNode _parseAdditiveExpr() {
    var left = _parseMultiplicativeExpr();
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.additives.contains(curTok.type)) {
        final op = advance(1).type;
        final right = _parseMultiplicativeExpr();
        left = BinaryExpr(left, op, right);
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
        final op = advance(1).type;
        final right = _parseUnaryPrefixExpr();
        left = BinaryExpr(left, op, right);
      }
    }
    return left;
  }

  /// 前缀 -e, !e，++e, --e, 优先级 15, 不合并
  AstNode _parseUnaryPrefixExpr() {
    if (!(HTLexicon.unaryPrefixs.contains(curTok.type))) {
      return _parseUnaryPostfixExpr();
    } else {
      var op = advance(1);
      return UnaryExpr(op, _parseUnaryPostfixExpr());
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
          final name = match(HTLexicon.identifier);
          expr = MemberGetExpr(expr, name);
          break;
        case HTLexicon.subGet:
          var indexExpr = _parseExpr();
          _leftValueLegality = true;
          match(HTLexicon.squareRight);
          expr = SubGetExpr(expr, indexExpr);
          break;
        case HTLexicon.call:
          // TODO: typeArgs: typeArgs
          _leftValueLegality = false;
          var isNamed = false;
          var positionalArgs = <AstNode>[];
          var namedArgs = <String, AstNode>{};
          while ((curTok.type != HTLexicon.roundRight) &&
              (curTok.type != HTLexicon.endOfFile)) {
            if ((!isNamed &&
                    expect([HTLexicon.identifier, HTLexicon.colon],
                        consume: false)) ||
                isNamed) {
              isNamed = true;
              final name = match(HTLexicon.identifier).lexeme;
              match(HTLexicon.colon);
              var value = _parseExpr();
              namedArgs[name] = value;
            } else {
              positionalArgs.add(_parseExpr());
            }
            if (curTok.type != HTLexicon.roundRight) {
              match(HTLexicon.comma);
            }
          }
          match(HTLexicon.roundRight);
          expr = CallExpr(expr, positionalArgs, namedArgs);
          break;
        case HTLexicon.postIncrement:
        case HTLexicon.postDecrement:
          _leftValueLegality = false;
          expr = UnaryPostfixExpr(expr, op);
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
        advance(1);
        return NullExpr(peek(-1).line, peek(-1).column);
      case HTLexicon.TRUE:
        _leftValueLegality = false;
        advance(1);
        return BooleanExpr(true, peek(-1).line, peek(-1).column);
      case HTLexicon.FALSE:
        _leftValueLegality = false;
        advance(1);
        return BooleanExpr(false, peek(-1).line, peek(-1).column);
      case HTLexicon.integer:
        _leftValueLegality = false;
        var index = _curConstTable.addInt(curTok.literal);
        advance(1);
        return ConstIntExpr(index, peek(-1).line, peek(-1).column);
      case HTLexicon.float:
        _leftValueLegality = false;
        var index = _curConstTable.addFloat(curTok.literal);
        advance(1);
        return ConstFloatExpr(index, peek(-1).line, peek(-1).column);
      case HTLexicon.string:
        _leftValueLegality = false;
        var index = _curConstTable.addString(curTok.literal);
        advance(1);
        return ConstStringExpr(index, peek(-1).line, peek(-1).column);
      case HTLexicon.THIS:
        _leftValueLegality = false;
        return SymbolExpr(advance(1));
      case HTLexicon.SUPER:
        _leftValueLegality = false;
        return SymbolExpr(advance(1));
      case HTLexicon.roundLeft:
        _leftValueLegality = false;
        advance(1);
        var innerExpr = _parseExpr();
        match(HTLexicon.roundRight);
        return GroupExpr(innerExpr);
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
        return LiteralListExpr(line, column, listExpr);
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
        return LiteralMapExpr(line, column, mapExpr);

      case HTLexicon.FUNCTION:
        return _parseFuncDeclaration(category: FunctionCategory.literal);
      case HTLexicon.identifier:
        // literal function type
        if (curTok.lexeme == HTLexicon.function) {
          _leftValueLegality = false;
          return _parseTypeExpr();
        }
        // TODO: literal interface type
        else {
          _leftValueLegality = true;
          return SymbolExpr(advance(1));
        }
      default:
        throw HTError.unexpected(HTLexicon.expression, curTok.lexeme);
    }
  }

  TypeExpr _parseTypeExpr() {
    // function type
    if (expect([HTLexicon.function, HTLexicon.roundLeft], consume: true)) {
      final keyword = peek(-2);

      // TODO: genericTypeParameters 泛型参数

      final paramTypes = <ParamTypeExpr>[];

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
        var paramId = '';
        if (!isNamed) {
          isVariadic = expect([HTLexicon.varargs], consume: true);
        } else {
          paramId = match(HTLexicon.identifier).lexeme;
          match(HTLexicon.colon);
        }

        paramType = _parseTypeExpr();

        final param = ParamTypeExpr(paramType, paramType.line, paramType.column,
            paramId: paramId,
            isOptional: isOptional,
            isNamed: isNamed,
            isVariadic: isVariadic);
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

      match(HTLexicon.arrow);

      final returnType = _parseTypeExpr();

      return FunctionTypeExpr(returnType, keyword.line, keyword.column,
          parameterTypes: paramTypes);
    }
    // TODO: interface type
    else {
      final id = match(HTLexicon.identifier);

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

  List<AstNode> _parseBlock({SourceType sourceType = SourceType.module}) {
    var stmts = <AstNode>[];
    while ((curTok.type != HTLexicon.curlyRight) &&
        (curTok.type != HTLexicon.endOfFile)) {
      final stmt = _parseStmt(sourceType: sourceType);
      if (stmt != null) {
        stmts.add(stmt);
      }
    }
    match(HTLexicon.curlyRight);
    return stmts;
  }

  BlockStmt _parseBlockStmt({SourceType sourceType = SourceType.module}) {
    var line = curTok.line;
    var column = curTok.column;
    final stmts = _parseBlock(sourceType: sourceType);
    match(HTLexicon.curlyRight);
    return BlockStmt(stmts, line, column);
  }

  /// 为了避免涉及复杂的左值右值问题, 赋值语句在河图中不作为表达式处理
  /// 而是分成直接赋值, 取值后复制和取属性后复制
  // ExprStmt _parseAssignStmt() {
  //   // 之前已经校验过等于号了所以这里直接跳过
  //   var name = advance(1);
  //   var token = advance(1);
  //   var value = _parseExpr();
  //   // 语句结尾
  //   expect([HTLexicon.semicolon], consume: true);
  //   var expr = AssignExpr(name, token, value);
  //   return ExprStmt(expr);
  // }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    AstNode? expr;
    if (!expect([HTLexicon.semicolon], consume: true)) {
      expr = _parseExpr();
    }
    expect([HTLexicon.semicolon], consume: true);
    return ReturnStmt(keyword, expr);
  }

  IfStmt _parseIfStmt() {
    advance(1);
    match(HTLexicon.roundLeft);
    var condition = _parseExpr();
    match(HTLexicon.roundRight);
    AstNode? thenBranch;
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      thenBranch = _parseBlockStmt(sourceType: SourceType.function);
    } else {
      thenBranch = _parseStmt(sourceType: SourceType.function);
    }
    AstNode? elseBranch;
    if (expect([HTLexicon.ELSE], consume: true)) {
      if (expect([HTLexicon.curlyLeft], consume: true)) {
        elseBranch = _parseBlockStmt(sourceType: SourceType.function);
      } else {
        elseBranch = _parseStmt(sourceType: SourceType.function);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch);
  }

  WhileStmt _parseWhileStmt() {
    // 之前已经校验过括号了所以这里直接跳过
    advance(1);
    match(HTLexicon.roundLeft);
    var condition = _parseExpr();
    match(HTLexicon.roundRight);
    AstNode? loop;
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      loop = _parseBlockStmt(sourceType: SourceType.function);
    } else {
      loop = _parseStmt(sourceType: SourceType.function);
    }
    return WhileStmt(condition, loop);
  }

  // WhileStmt _parseDoStmt() {}

  // For语句其实会在解析时转换为While语句
  BlockStmt _parseForStmt() {
    // var list_stmt = <AstNode>[];
    // expect([HTLexicon.FOR, HTLexicon.roundLeft], consume: true);
    // // 递增变量
    // final i = HTLexicon.increment;
    // list_stmt.add(VarDeclStmt(i, curModuleFullName, curTok.line, curTok.column,
    //     declType: HTType.number,
    //     initializer: ConstIntExpr(interpreter.addInt(0), curModuleFullName,
    //         curTok.line, curTok.column)));
    // // 指针
    // var varname = match(HTLexicon.identifier).lexeme;
    // TypeExpr? type;
    // if (expect([HTLexicon.colon], consume: true)) {
    //   type = _parseTypeExpr();
    // }
    // list_stmt.add(VarDeclStmt(
    //     varname, curTok.moduleFullName, curTok.line, curTok.column,
    //     declType: type));
    // match(HTLexicon.IN);
    // var list_obj = _parseExpr();
    // // 条件语句
    // var get_length = MemberGetExpr(
    //     list_obj,
    //     TokenIdentifier(
    //         HTLexicon.length, curModuleFullName, curTok.line, curTok.column));
    // var condition = BinaryExpr(
    //     SymbolExpr(
    //         TokenIdentifier(i, curModuleFullName, curTok.line, curTok.column)),
    //     HTLexicon.lesser,
    //     get_length);
    // // 在循环体之前手动插入递增语句和指针语句
    // // 按下标取数组元素
    // var loop_body = <AstNode>[];
    // // 这里一定要复制一个list_obj的表达式, 否则在resolve的时候会因为是相同的对象出错, 覆盖掉上面那个表达式的位置
    // var sub_get_value = SubGetExpr(
    //     list_obj.clone(),
    //     SymbolExpr(
    //         TokenIdentifier(i, curModuleFullName, curTok.line, curTok.column)));
    // var assign_stmt = ExprStmt(BinaryExpr(
    //     SymbolExpr(TokenIdentifier(
    //         varname, curModuleFullName, curTok.line, curTok.column)),
    //     HTLexicon.assign,
    //     sub_get_value));
    // loop_body.add(assign_stmt);
    // // 递增下标变量
    // var increment_expr = BinaryExpr(
    //     SymbolExpr(
    //         TokenIdentifier(i, curModuleFullName, curTok.line, curTok.column)),
    //     HTLexicon.add,
    //     ConstIntExpr(interpreter.addInt(1), curModuleFullName, curTok.line,
    //         curTok.column));
    // var increment_stmt = ExprStmt(BinaryExpr(
    //     SymbolExpr(
    //         TokenIdentifier(i, curModuleFullName, curTok.line, curTok.column)),
    //     HTLexicon.assign,
    //     increment_expr));
    // loop_body.add(increment_stmt);
    // // 循环体
    // match(HTLexicon.roundRight);
    // if (expect([HTLexicon.curlyLeft], consume: true)) {
    //   loop_body.addAll(_parseBlock(sourceType: SourceType.function));
    // } else {
    //   final stmt = _parseStmt(sourceType: SourceType.function);
    //   if (stmt != null) {
    //     loop_body.add(stmt);
    //   }
    // }
    // list_stmt.add(WhileStmt(condition,
    //     BlockStmt(loop_body, curModuleFullName, curTok.line, curTok.column)));
    // return BlockStmt(list_stmt, curModuleFullName, curTok.line, curTok.column);
    return BlockStmt([], curTok.line, curTok.column);
  }

  // BlockStmt _parseWhenStmt() {}

  // 变量声明语句
  VarDecl _parseVarDeclStmt(
      {String? declId,
      bool typeInferrence = false,
      bool isExternal = false,
      bool isImmutable = false,
      bool isStatic = false,
      bool lateInitialize = false}) {
    advance(1);
    var idTok = match(HTLexicon.identifier);
    var id = idTok.lexeme;

    if (_curClass != null && isExternal) {
      if (!(_curClass!.isExternal) && !isStatic) {
        throw HTError.externMember();
      }
      id = '${_curClass!.id}.$id';
    }

    if (declId != null) {
      id = declId;
    }

    var decl_type;
    if (expect([HTLexicon.colon], consume: true)) {
      decl_type = _parseTypeExpr();
    }

    AstNode? initializer;
    if (expect([HTLexicon.assign], consume: true)) {
      initializer = _parseExpr();
    }
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true);
    var stmt = VarDecl(id, idTok.line, idTok.column,
        declType: decl_type,
        initializer: initializer,
        isDynamic: typeInferrence,
        isExternal: isExternal,
        isImmutable: isImmutable,
        isStatic: isStatic);

    return stmt;
  }

  List<ParamDecl> _parseParameters() {
    var params = <ParamDecl>[];
    var isOptional = false;
    var isNamed = false;
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

      var isVariadic = false;
      if (!isNamed) {
        isVariadic = expect([HTLexicon.varargs], consume: true);
      }

      var name = match(HTLexicon.identifier);
      TypeExpr? declType;
      if (expect([HTLexicon.colon], consume: true)) {
        declType = _parseTypeExpr();
      }

      AstNode? initializer;
      if (isOptional || isNamed) {
        //参数默认值
        if (expect([HTLexicon.assign], consume: true)) {
          initializer = _parseExpr();
        }
      }

      params.add(ParamDecl(name.type, name.line, name.column,
          declType: declType,
          initializer: initializer,
          isVariadic: isVariadic,
          isOptional: isOptional,
          isNamed: isNamed));

      if (curTok.type != HTLexicon.squareRight &&
          curTok.type != HTLexicon.curlyRight &&
          curTok.type != HTLexicon.roundRight) {
        match(HTLexicon.comma);
      }

      if (isVariadic) {
        break;
      }
    }

    if (isOptional) {
      match(HTLexicon.squareRight);
    } else if (isNamed) {
      match(HTLexicon.curlyRight);
    }

    match(HTLexicon.roundRight);
    return params;
  }

  FuncDecl _parseFuncDeclaration(
      {FunctionCategory category = FunctionCategory.normal,
      bool isExternal = false,
      bool isStatic = false}) {
    final keyword = advance(1);
    Token? func_name;
    var typeParameters = <String>[];
    if (curTok.type == HTLexicon.identifier) {
      func_name = advance(1);

      if (expect([HTLexicon.angleLeft], consume: true)) {
        while ((curTok.type != HTLexicon.angleRight) &&
            (curTok.type != HTLexicon.endOfFile)) {
          if (typeParameters.isNotEmpty) {
            match(HTLexicon.comma);
          }
          typeParameters.add(advance(1).lexeme);
        }
        match(HTLexicon.angleRight);
      }
    }

    // if (functype == FuncStmtType.normal) {
    //   if (_declarations.containsKey(func_name)) throw HTErrorDefined(func_name, fileName, curTok.line, curTok.column);
    // }

    var arity = 0;
    var isVariadic = false;
    var params = <ParamDecl>[];

    if (category != FunctionCategory.getter) {
      // 之前还没有校验过左括号
      if (expect([HTLexicon.roundLeft], consume: true)) {
        params = _parseParameters();

        for (var i = 0; i < params.length; ++i) {
          if (params[i].isVariadic) {
            isVariadic = true;
            break;
          } else if (params[i].isOptional || params[i].isNamed) {
            break;
          }
          ++arity;
        }

        // setter只能有一个参数, 就是赋值语句的右值, 但此处并不需要判断类型
        if ((category == FunctionCategory.setter) && (arity != 1)) {
          throw HTError.setterArity();
        }
      }
    }

    TypeExpr? returnType;
    if ((category != FunctionCategory.constructor) &&
        (expect([HTLexicon.colon], consume: true))) {
      returnType = _parseTypeExpr();
    }

    var body = <AstNode>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      // 处理函数定义部分的语句块
      body = _parseBlock(sourceType: SourceType.function);
    }
    expect([HTLexicon.semicolon], consume: true);

    var stmt = FuncDecl(params, keyword.line, keyword.column,
        id: func_name,
        typeParameters: typeParameters,
        returnType: returnType,
        arity: arity,
        definition: body,
        classId: _curClass?.id,
        isExternal: isExternal,
        isStatic: isStatic,
        isVariadic: isVariadic,
        category: category);

    // _declarations[stmt.id] = stmt;

    return stmt;
  }

  ClassDecl _parseClassDeclStmt(
      {bool isExternal = false, bool isAbstract = false}) {
    // 已经判断过了所以直接跳过关键字
    advance(1);

    final className = match(HTLexicon.identifier);

    if (_mainBlock.contains(className.lexeme)) {
      throw HTError.definedParser(className.lexeme);
    }

    final savedClass = _curClass;

    // final savedClassId = _curClassId;
    // final savedClassType = _curClassType;
    // final savedClassType = _curClassType;
    // _curClassId = className.lexeme;
    // _curClassType = classType;
    // _curClassType = HTType(className.lexeme);

    _curClass = ClassInfo(className.lexeme,
        isExternal: isExternal, isAbstract: isAbstract);

    // generic type参数
    var typeParameters = <String>[];
    if (expect([HTLexicon.angleLeft], consume: true)) {
      while ((curTok.type != HTLexicon.angleRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        if (typeParameters.isNotEmpty) {
          match(HTLexicon.comma);
        }
        typeParameters.add(advance(1).lexeme);
      }
      match(HTLexicon.angleRight);
    }

    // 继承父类
    SymbolExpr? super_class;
    ClassDecl? super_class_decl;
    TypeExpr? super_class_type_args;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      if (curTok.lexeme == className.lexeme) {
        throw HTError.extendsSelf();
      } else if (!_mainBlock.contains(curTok.lexeme)) {
        throw HTError.notClass(curTok.lexeme);
      }

      super_class = SymbolExpr(curTok);
      super_class_decl = _mainBlock.classDecls[super_class.id.lexeme];
      advance(1);
      if (expect([HTLexicon.angleLeft], consume: true)) {
        // 类型传入参数
        super_class_type_args = _parseTypeExpr();
        match(HTLexicon.angleRight);
      }
    }

    // 类的定义体
    var variables = <VarDecl>[];
    var methods = <FuncDecl>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while ((curTok.type != HTLexicon.curlyRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        var member = _parseStmt(sourceType: SourceType.klass);
        if (member is VarDecl) {
          variables.add(member);
        } else if (member is FuncDecl) {
          methods.add(member);
        }
      }
      match(HTLexicon.curlyRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    final stmt = ClassDecl(className, variables, methods,
        isExternal: isExternal,
        isAbstract: isAbstract,
        typeParameters: typeParameters,
        superClass: super_class,
        superClassDeclStmt: super_class_decl,
        superClassTypeArgs: super_class_type_args);

    _mainBlock.classDecls[className.lexeme] = stmt;

    _curClass = savedClass;
    // _curClassId = savedClassId;
    // _curClassType = savedClassType;
    // _curClassType = savedClassType;
    return stmt;
  }

  EnumDecl _parseEnumDeclStmt({bool isExternal = false}) {
    // 已经判断过了所以直接跳过关键字
    advance(1);

    final class_name = match(HTLexicon.identifier);

    if (_mainBlock.contains(class_name.lexeme)) {
      throw HTError.definedParser(class_name.lexeme);
    }

    var enumerations = <String>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while (curTok.type != HTLexicon.curlyRight &&
          curTok.type != HTLexicon.endOfFile) {
        enumerations.add(match(HTLexicon.identifier).lexeme);
        if (curTok.type != HTLexicon.curlyRight) {
          match(HTLexicon.comma);
        }
      }

      match(HTLexicon.curlyRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    final stmt = EnumDecl(class_name, enumerations, isExternal: isExternal);
    _mainBlock.enumDecls[class_name.lexeme] = stmt;

    return stmt;
  }
}
