import 'package:hetu_script/src/ast/ast_interpreter.dart';

import '../errors.dart';
import 'ast.dart';
import '../token.dart';
import '../lexicon.dart';
import '../type.dart';
import '../parser.dart';
import '../common.dart';

class HTAstParser extends Parser with AstInterpreterRef {
  late String _curModuleUniqueKey;
  @override
  String get curModuleUniqueKey => _curModuleUniqueKey;

  ClassInfo? _curClass;
  // HTType? _curClassType;
  // String? _curClassId;

  final _classStmts = <String, ASTNode>{};

  HTAstParser(HTAstInterpreter interpreter) {
    this.interpreter = interpreter;
  }

  Future<List<ASTNode>> parse(List<Token> tokens, String fileName,
      [CodeType codeType = CodeType.module, debugMode = false]) async {
    this.tokens.clear();
    this.tokens.addAll(tokens);
    _curModuleUniqueKey = fileName;

    final statements = <ASTNode>[];
    while (curTok.type != HTLexicon.endOfFile) {
      var stmt = _parseStmt(codeType: codeType);
      if (stmt is ImportStmt) {
        await interpreter.import(stmt.key, moduleName: stmt.namespace);
        _curModuleUniqueKey = interpreter.curModuleUniqueKey;
      }
      statements.add(stmt);
    }

    return statements;
  }

  HTType _parseType() {
    final type_name = advance(1).lexeme;
    var type_args = <HTType>[];
    if (expect([HTLexicon.angleLeft], consume: true)) {
      while ((curTok.type != HTLexicon.angleRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        type_args.add(_parseType());
        if (curTok.type != HTLexicon.angleRight) {
          match(HTLexicon.comma);
        }
      }
      match(HTLexicon.angleRight);
    }

    return HTType(type_name, typeArgs: type_args);
  }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  ASTNode _parseExpr() => _parseAssignmentExpr();

  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  ASTNode _parseAssignmentExpr() {
    final expr = _parseLogicalOrExpr();

    if (HTLexicon.assignments.contains(curTok.type)) {
      final op = advance(1);
      final value = _parseAssignmentExpr();

      if (expr is SymbolExpr) {
        return AssignExpr(expr.id, op, value);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value);
      } else if (expr is SubGetExpr) {
        return SubSetExpr(expr.collection, expr.key, value);
      }

      throw HTError.illegalLeftValueParser();
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  ASTNode _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == HTLexicon.logicalOr) {
      final op = advance(1);
      final right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  ASTNode _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok.type == HTLexicon.logicalAnd) {
      final op = advance(1);
      final right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，不合并
  ASTNode _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    if (HTLexicon.equalitys.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，不合并
  ASTNode _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    if (HTLexicon.relationals.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseAdditiveExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 加法 +, -，优先级 13，左合并
  ASTNode _parseAdditiveExpr() {
    var expr = _parseMultiplicativeExpr();
    while (HTLexicon.additives.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseMultiplicativeExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 乘法 *, /, %，优先级 14，左合并
  ASTNode _parseMultiplicativeExpr() {
    var expr = _parseUnaryPrefixExpr();
    while (HTLexicon.multiplicatives.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseUnaryPrefixExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 前缀 -e, !e，优先级 15，不合并
  ASTNode _parseUnaryPrefixExpr() {
    // 因为是前缀所以不能像别的表达式那样先进行下一级的分析
    ASTNode expr;
    if (HTLexicon.unaryPrefixs.contains(curTok.type)) {
      var op = advance(1);

      expr = UnaryExpr(op, _parseUnaryPostfixExpr());
    } else {
      expr = _parseUnaryPostfixExpr();
    }
    return expr;
  }

  /// 后缀 e., e[], e()，优先级 16，右合并
  ASTNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    while (true) {
      if (expect([HTLexicon.call], consume: true)) {
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};

        while ((curTok.type != HTLexicon.roundRight) &&
            (curTok.type != HTLexicon.endOfFile)) {
          final arg = _parseExpr();
          if (expect([HTLexicon.colon], consume: false)) {
            if (arg is SymbolExpr) {
              advance(1);
              var value = _parseExpr();
              namedArgs[arg.id.lexeme] = value;
            } else {
              throw HTError.unexpected(
                curTok.lexeme,
              );
            }
          } else {
            positionalArgs.add(arg);
          }

          if (curTok.type != HTLexicon.roundRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.roundRight);
        expr = CallExpr(
            expr, positionalArgs, namedArgs); // TODO: typeArgs: typeArgs
      } else if (expect([HTLexicon.memberGet], consume: true)) {
        final name = match(HTLexicon.identifier);
        expr = MemberGetExpr(expr, name);
      } else if (expect([HTLexicon.subGet], consume: true)) {
        var index_expr = _parseExpr();
        match(HTLexicon.squareRight);
        expr = SubGetExpr(expr, index_expr);
      } else {
        break;
      }
    }
    return expr;
  }

  /// 只有一个Token的简单表达式
  ASTNode _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.NULL:
        advance(1);
        return NullExpr(_curModuleUniqueKey, peek(-1).line, peek(-1).column);
      case HTLexicon.TRUE:
        advance(1);
        return BooleanExpr(
            true, _curModuleUniqueKey, peek(-1).line, peek(-1).column);
      case HTLexicon.FALSE:
        advance(1);
        return BooleanExpr(
            false, _curModuleUniqueKey, peek(-1).line, peek(-1).column);
      case HTLexicon.integer:
        var index = interpreter.addInt(curTok.literal);
        advance(1);
        return ConstIntExpr(
            index, _curModuleUniqueKey, peek(-1).line, peek(-1).column);
      case HTLexicon.float:
        var index = interpreter.addConstFloat(curTok.literal);
        advance(1);
        return ConstFloatExpr(
            index, _curModuleUniqueKey, peek(-1).line, peek(-1).column);
      case HTLexicon.string:
        var index = interpreter.addConstString(curTok.literal);
        advance(1);
        return ConstStringExpr(
            index, _curModuleUniqueKey, peek(-1).line, peek(-1).column);
      case HTLexicon.THIS:
        advance(1);
        return ThisExpr(peek(-1));
      case HTLexicon.identifier:
        advance(1);
        return SymbolExpr(peek(-1));
      case HTLexicon.roundLeft:
        advance(1);
        var innerExpr = _parseExpr();
        match(HTLexicon.roundRight);
        return GroupExpr(innerExpr);
      case HTLexicon.squareLeft:
        final line = curTok.line;
        final column = advance(1).column;
        var list_expr = <ASTNode>[];
        while (curTok.type != HTLexicon.squareRight) {
          list_expr.add(_parseExpr());
          if (curTok.type != HTLexicon.squareRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.squareRight);
        return LiteralVectorExpr(_curModuleUniqueKey, line, column, list_expr);
      case HTLexicon.curlyLeft:
        final line = curTok.line;
        final column = advance(1).column;
        var map_expr = <ASTNode, ASTNode>{};
        while (curTok.type != HTLexicon.curlyRight) {
          var key_expr = _parseExpr();
          match(HTLexicon.colon);
          var value_expr = _parseExpr();
          map_expr[key_expr] = value_expr;
          if (curTok.type != HTLexicon.curlyRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.curlyRight);
        return LiteralDictExpr(_curModuleUniqueKey, line, column, map_expr);

      case HTLexicon.FUNCTION:
        return _parseFuncDeclaration(funcType: FunctionType.literal);

      default:
        throw HTError.unexpected(curTok.lexeme);
    }
  }

  ASTNode _parseStmt({CodeType codeType = CodeType.module}) {
    switch (codeType) {
      case CodeType.module:
        switch (curTok.type) {
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.CLASS:
                return _parseClassDeclStmt(isExtern: true);
              case HTLexicon.ENUM:
                return _parseEnumDeclStmt(isExtern: true);
              case HTLexicon.VAR:
                return _parseVarStmt(isExtern: true, isDynamic: true);
              case HTLexicon.LET:
                return _parseVarStmt(isExtern: true);
              case HTLexicon.CONST:
                return _parseVarStmt(isExtern: true, isImmutable: true);
              case HTLexicon.FUNCTION:
                return _parseFuncDeclaration(isExtern: true);
              default:
                throw HTError.unexpected(curTok.type);
            }
          // case HTLexicon.ABSTRACT:
          //   match(HTLexicon.CLASS);
          //   return _parseClassDeclStmt(classType: ClassType.abstracted);
          // case HTLexicon.INTERFACE:
          //   match(HTLexicon.CLASS);
          //   return _parseClassDeclStmt(classType: ClassType.interface);
          // case HTLexicon.MIXIN:
          //   match(HTLexicon.CLASS);
          //   return _parseClassDeclStmt(classType: ClassType.mixIn);
          case HTLexicon.CLASS:
            return _parseClassDeclStmt();
          case HTLexicon.IMPORT:
            return _parseImportStmt();
          case HTLexicon.VAR:
            return _parseVarStmt(isDynamic: true);
          case HTLexicon.LET:
            return _parseVarStmt();
          case HTLexicon.CONST:
            return _parseVarStmt(isImmutable: true);
          case HTLexicon.FUNCTION:
            return _parseFuncDeclaration();
          default:
            throw HTError.unexpected(curTok.lexeme);
        }
      case CodeType.expression:
      case CodeType.function:
      case CodeType.script:
        // 函数块中不能出现extern或者static关键字的声明
        // var变量声明
        if (expect([HTLexicon.VAR])) {
          return _parseVarStmt(isDynamic: true);
        } // let
        else if (expect([HTLexicon.LET])) {
          return _parseVarStmt();
        } // const
        else if (expect([HTLexicon.CONST])) {
          return _parseVarStmt(isImmutable: true);
        } // 函数声明
        else if (expect([HTLexicon.FUNCTION])) {
          return _parseFuncDeclaration();
        } // 赋值语句
        else if (expect([HTLexicon.identifier, HTLexicon.assign])) {
          return _parseAssignStmt();
        } //If语句
        else if (expect([HTLexicon.IF])) {
          return _parseIfStmt();
        } // While语句
        else if (expect([HTLexicon.WHILE])) {
          return _parseWhileStmt();
        } // For语句
        else if (expect([HTLexicon.FOR])) {
          return _parseForStmt();
        } // 跳出语句
        else if (expect([HTLexicon.BREAK])) {
          return BreakStmt(advance(1));
        } // 继续语句
        else if (expect([HTLexicon.CONTINUE])) {
          return ContinueStmt(advance(1));
        } // 返回语句
        else if (curTok.type == HTLexicon.RETURN) {
          return _parseReturnStmt();
        }
        // 表达式
        else {
          return _parseExprStmt();
        }
      case CodeType.klass:
        final isExtern = expect([HTLexicon.EXTERNAL], consume: true);
        final isStatic = expect([HTLexicon.STATIC], consume: true);
        // var变量声明
        if (expect([HTLexicon.VAR])) {
          return _parseVarStmt(
              isExtern: isExtern || (_curClass?.isExtern ?? false),
              isStatic: isStatic);
        } // let
        else if (expect([HTLexicon.LET])) {
          return _parseVarStmt(
              isDynamic: true,
              isExtern: isExtern || (_curClass?.isExtern ?? false),
              isStatic: isStatic);
        } // const
        else if (expect([HTLexicon.CONST])) {
          if (!isStatic) throw HTError.constMustBeStatic(curTok.lexeme);
          return _parseVarStmt(
              isDynamic: true,
              isExtern: isExtern || (_curClass?.isExtern ?? false),
              isStatic: true,
              isImmutable: true);
        } // 构造函数
        else if (curTok.lexeme == HTLexicon.CONSTRUCT) {
          return _parseFuncDeclaration(
              funcType: FunctionType.constructor,
              isExtern: isExtern || (_curClass?.isExtern ?? false),
              isStatic: isStatic);
        } // setter函数声明
        else if (curTok.lexeme == HTLexicon.GET) {
          return _parseFuncDeclaration(
              funcType: FunctionType.getter,
              isExtern: isExtern || (_curClass?.isExtern ?? false),
              isStatic: isStatic);
        } // getter函数声明
        else if (curTok.lexeme == HTLexicon.SET) {
          return _parseFuncDeclaration(
              funcType: FunctionType.setter,
              isExtern: isExtern || (_curClass?.isExtern ?? false),
              isStatic: isStatic);
        } // 成员函数声明
        else if (expect([HTLexicon.FUNCTION])) {
          return _parseFuncDeclaration(
              isExtern: isExtern || (_curClass?.isExtern ?? false),
              isStatic: isStatic);
        } else {
          throw HTError.unexpected(curTok.lexeme);
        }
    }
  }

  List<ASTNode> _parseBlock({CodeType codeType = CodeType.module}) {
    var stmts = <ASTNode>[];
    while ((curTok.type != HTLexicon.curlyRight) &&
        (curTok.type != HTLexicon.endOfFile)) {
      stmts.add(_parseStmt(codeType: codeType));
    }
    match(HTLexicon.curlyRight);
    return stmts;
  }

  BlockStmt _parseBlockStmt({CodeType codeType = CodeType.module}) {
    var stmts = <ASTNode>[];
    var line = curTok.line;
    var column = curTok.column;
    while ((curTok.type != HTLexicon.curlyRight) &&
        (curTok.type != HTLexicon.endOfFile)) {
      stmts.add(_parseStmt(codeType: codeType));
    }
    match(HTLexicon.curlyRight);
    return BlockStmt(stmts, curModuleUniqueKey, line, column);
  }

  ImportStmt _parseImportStmt() {
    // 之前校验过了所以这里直接跳过
    final keyword = advance(1);
    String fileName = match(HTLexicon.string).literal;
    String? spaceName;
    if (expect([HTLexicon.AS], consume: true)) {
      spaceName = match(HTLexicon.identifier).lexeme;
    }
    var stmt = ImportStmt(keyword, fileName, spaceName);
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  /// 为了避免涉及复杂的左值右值问题，赋值语句在河图中不作为表达式处理
  /// 而是分成直接赋值，取值后复制和取属性后复制
  ExprStmt _parseAssignStmt() {
    // 之前已经校验过等于号了所以这里直接跳过
    var name = advance(1);
    var token = advance(1);
    var value = _parseExpr();
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true);
    var expr = AssignExpr(name, token, value);
    return ExprStmt(expr);
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    ASTNode? expr;
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
    ASTNode? thenBranch;
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      thenBranch = _parseBlockStmt(codeType: CodeType.function);
    } else {
      thenBranch = _parseStmt(codeType: CodeType.function);
    }
    ASTNode? elseBranch;
    if (expect([HTLexicon.ELSE], consume: true)) {
      if (expect([HTLexicon.curlyLeft], consume: true)) {
        elseBranch = _parseBlockStmt(codeType: CodeType.function);
      } else {
        elseBranch = _parseStmt(codeType: CodeType.function);
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
    ASTNode? loop;
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      loop = _parseBlockStmt(codeType: CodeType.function);
    } else {
      loop = _parseStmt(codeType: CodeType.function);
    }
    return WhileStmt(condition, loop);
  }

  /// For语句其实会在解析时转换为While语句
  BlockStmt _parseForStmt() {
    var list_stmt = <ASTNode>[];
    expect([HTLexicon.FOR, HTLexicon.roundLeft], consume: true);
    // 递增变量
    final i = '__i${Parser.internalVarIndex++}';
    list_stmt.add(VarDeclStmt(
        TokenIdentifier(i, curModuleUniqueKey, curTok.line, curTok.column),
        declType: HTType.number,
        initializer: ConstIntExpr(interpreter.addInt(0), curModuleUniqueKey,
            curTok.line, curTok.column)));
    // 指针
    var varname = match(HTLexicon.identifier).lexeme;
    var type = HTType.ANY;
    if (expect([HTLexicon.colon], consume: true)) {
      type = _parseType();
    }
    list_stmt.add(VarDeclStmt(
        TokenIdentifier(varname, curTok.fileName, curTok.line, curTok.column),
        declType: type));
    match(HTLexicon.IN);
    var list_obj = _parseExpr();
    // 条件语句
    var get_length = MemberGetExpr(
        list_obj,
        TokenIdentifier(
            HTLexicon.length, curModuleUniqueKey, curTok.line, curTok.column));
    var condition = BinaryExpr(
        SymbolExpr(
            TokenIdentifier(i, curModuleUniqueKey, curTok.line, curTok.column)),
        Token(HTLexicon.lesser, curModuleUniqueKey, curTok.line, curTok.column),
        get_length);
    // 在循环体之前手动插入递增语句和指针语句
    // 按下标取数组元素
    var loop_body = <ASTNode>[];
    // 这里一定要复制一个list_obj的表达式，否则在resolve的时候会因为是相同的对象出错，覆盖掉上面那个表达式的位置
    var sub_get_value = SubGetExpr(
        list_obj.clone(),
        SymbolExpr(TokenIdentifier(
            i, curModuleUniqueKey, curTok.line, curTok.column)));
    var assign_stmt = ExprStmt(AssignExpr(
        TokenIdentifier(
            varname, curModuleUniqueKey, curTok.line, curTok.column),
        Token(HTLexicon.assign, curModuleUniqueKey, curTok.line, curTok.column),
        sub_get_value));
    loop_body.add(assign_stmt);
    // 递增下标变量
    var increment_expr = BinaryExpr(
        SymbolExpr(
            TokenIdentifier(i, curModuleUniqueKey, curTok.line, curTok.column)),
        Token(HTLexicon.add, curModuleUniqueKey, curTok.line, curTok.column),
        ConstIntExpr(interpreter.addInt(1), curModuleUniqueKey, curTok.line,
            curTok.column));
    var increment_stmt = ExprStmt(AssignExpr(
        TokenIdentifier(i, curModuleUniqueKey, curTok.line, curTok.column),
        Token(HTLexicon.assign, curModuleUniqueKey, curTok.line, curTok.column),
        increment_expr));
    loop_body.add(increment_stmt);
    // 循环体
    match(HTLexicon.roundRight);
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      loop_body.addAll(_parseBlock(codeType: CodeType.function));
    } else {
      loop_body.add(_parseStmt(codeType: CodeType.function));
    }
    list_stmt.add(WhileStmt(condition,
        BlockStmt(loop_body, curModuleUniqueKey, curTok.line, curTok.column)));
    return BlockStmt(list_stmt, curModuleUniqueKey, curTok.line, curTok.column);
  }

  /// 变量声明语句
  VarDeclStmt _parseVarStmt(
      {bool isDynamic = false,
      bool isExtern = false,
      bool isStatic = false,
      bool isImmutable = false}) {
    advance(1);
    final var_name = match(HTLexicon.identifier);

    // if (_declarations.containsKey(var_name)) throw HTErrorDefined(var_name.lexeme, fileName, curTok.line, curTok.column);

    var decl_type;
    if (expect([HTLexicon.colon], consume: true)) {
      decl_type = _parseType();
    }

    ASTNode? initializer;
    if (expect([HTLexicon.assign], consume: true)) {
      initializer = _parseExpr();
    }
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true);
    var stmt = VarDeclStmt(var_name,
        declType: decl_type,
        initializer: initializer,
        isDynamic: isDynamic,
        isExtern: isExtern,
        isImmutable: isImmutable,
        isStatic: isStatic);

    // _declarations[var_name.lexeme] = stmt;

    return stmt;
  }

  List<ParamDeclStmt> _parseParameters() {
    var params = <ParamDeclStmt>[];
    var isOptional = false;
    var isNamed = false;
    while ((curTok.type != HTLexicon.roundRight) &&
        (curTok.type != HTLexicon.squareRight) &&
        (curTok.type != HTLexicon.curlyRight) &&
        (curTok.type != HTLexicon.endOfFile)) {
      // 可选参数，根据是否有方括号判断，一旦开始了可选参数，则不再增加参数数量arity要求
      if (!isOptional) {
        isOptional = expect([HTLexicon.squareLeft], consume: true);
        if (!isOptional && !isNamed) {
          //检查命名参数，根据是否有花括号判断
          isNamed = expect([HTLexicon.curlyLeft], consume: true);
        }
      }

      var isVariadic = false;
      if (!isNamed) {
        isVariadic = expect([HTLexicon.varargs], consume: true);
      }

      var name = match(HTLexicon.identifier);
      HTType? declType;
      if (expect([HTLexicon.colon], consume: true)) {
        declType = _parseType();
      }

      ASTNode? initializer;
      if (isOptional || isNamed) {
        //参数默认值
        if (expect([HTLexicon.assign], consume: true)) {
          initializer = _parseExpr();
        }
      }

      params.add(ParamDeclStmt(name,
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

  FuncDeclStmt _parseFuncDeclaration(
      {FunctionType funcType = FunctionType.normal,
      bool isExtern = false,
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
    var params = <ParamDeclStmt>[];

    if (funcType != FunctionType.getter) {
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

        // setter只能有一个参数，就是赋值语句的右值，但此处并不需要判断类型
        if ((funcType == FunctionType.setter) && (arity != 1)) {
          throw HTError.setter();
        }
      }
    }

    var return_type = HTType.ANY;
    if ((funcType != FunctionType.constructor) &&
        (expect([HTLexicon.colon], consume: true))) {
      return_type = _parseType();
    }

    var body = <ASTNode>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      // 处理函数定义部分的语句块
      body = _parseBlock(codeType: CodeType.function);
    }
    expect([HTLexicon.semicolon], consume: true);

    var stmt = FuncDeclStmt(
        return_type, params, curModuleUniqueKey, keyword.line, keyword.column,
        id: func_name,
        typeParameters: typeParameters,
        arity: arity,
        definition: body,
        classId: _curClass?.id,
        isExtern: isExtern,
        isStatic: isStatic,
        isVariadic: isVariadic,
        funcType: funcType);

    // _declarations[stmt.id] = stmt;

    return stmt;
  }

  ClassDeclStmt _parseClassDeclStmt(
      {bool isExtern = false, bool isAbstract = false}) {
    // 已经判断过了所以直接跳过关键字
    advance(1);

    final className = match(HTLexicon.identifier);

    if (_classStmts.containsKey(className.lexeme)) {
      throw HTError.definedParser(className.lexeme);
    }

    final savedClass = _curClass;

    // final savedClassId = _curClassId;
    // final savedClassType = _curClassType;
    // final savedClassType = _curClassType;
    // _curClassId = className.lexeme;
    // _curClassType = classType;
    // _curClassType = HTType(className.lexeme);

    _curClass =
        ClassInfo(className.lexeme, isExtern: isExtern, isAbstract: isAbstract);

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
    ClassDeclStmt? super_class_decl;
    HTType? super_class_type_args;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      if (curTok.lexeme == className.lexeme) {
        throw HTError.unexpected(className.lexeme);
      } else if (_classStmts[curTok.lexeme] == null) {
        throw HTError.notClass(curTok.lexeme);
      }

      super_class = SymbolExpr(curTok);
      super_class_decl = _classStmts[super_class.id.lexeme] as ClassDeclStmt?;
      advance(1);
      if (expect([HTLexicon.angleLeft], consume: true)) {
        // 类型传入参数
        super_class_type_args = _parseType();
        match(HTLexicon.angleRight);
      }
    }

    // 类的定义体
    var variables = <VarDeclStmt>[];
    var methods = <FuncDeclStmt>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while ((curTok.type != HTLexicon.curlyRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        var member = _parseStmt(codeType: CodeType.klass);
        if (member is VarDeclStmt) {
          variables.add(member);
        } else if (member is FuncDeclStmt) {
          methods.add(member);
        }
      }
      match(HTLexicon.curlyRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    final stmt = ClassDeclStmt(className, variables, methods,
        isExtern: isExtern,
        isAbstract: isAbstract,
        typeParameters: typeParameters,
        superClass: super_class,
        superClassDeclStmt: super_class_decl,
        superClassTypeArgs: super_class_type_args);

    _classStmts[className.lexeme] = stmt;

    _curClass = savedClass;
    // _curClassId = savedClassId;
    // _curClassType = savedClassType;
    // _curClassType = savedClassType;
    return stmt;
  }

  EnumDeclStmt _parseEnumDeclStmt({bool isExtern = false}) {
    // 已经判断过了所以直接跳过关键字
    advance(1);

    final class_name = match(HTLexicon.identifier);

    if (_classStmts.containsKey(class_name.lexeme)) {
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

    final stmt = EnumDeclStmt(class_name, enumerations, isExtern: isExtern);
    _classStmts[class_name.lexeme] = stmt;

    return stmt;
  }
}
