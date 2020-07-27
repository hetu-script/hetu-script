import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'token.dart';
import 'common.dart';
import 'interpreter.dart';

enum ParseStyle {
  /// 程序脚本使用完整的标点符号规则，包括各种括号、逗号和分号
  ///
  /// 程序脚本中只能出现变量、类和函数的声明
  ///
  /// 程序脚本中必有一个叫做main的完整函数作为入口
  library,

  /// 函数语句块中只能出现变量声明、控制语句和函数调用
  program,

  /// 类定义中只能出现变量和函数的声明
  classDefinition,
}

/// 负责对Token列表进行语法分析并生成语句列表
///
/// 语法定义如下
///
/// <程序>    ::=   <导入语句> | <变量声明>
///
/// <变量声明>      ::=   <变量声明> | <函数定义> | <类定义>
///
/// <语句块>    ::=   "{" <语句> { <语句> } "}"
///
/// <语句>      ::=   <声明> | <表达式> ";"
///
/// <表达式>    ::=   <标识符> | <单目> | <双目> | <三目>
///
/// <运算符>    ::=   <运算符>
class Parser {
  final List<Token> _tokens = [];
  var _tokPos = 0;
  Interpreter _interpreter;
  String _curClassName;

  static const List<String> _patternImport = [HS_Common.Import, HS_Common.Str];
  static const List<String> _patternVarDecl = [HS_Common.Identifier, HS_Common.Identifier, HS_Common.Semicolon];
  static const List<String> _patternVarDeclInit = [HS_Common.Identifier, HS_Common.Identifier, HS_Common.Assign];
  static const List<String> _patternFuncDecl = [HS_Common.Identifier, HS_Common.Identifier, HS_Common.RoundLeft];
  static const List<String> _patternAssign = [HS_Common.Identifier, HS_Common.Assign];
  static const List<String> _patternIf = [HS_Common.If, HS_Common.RoundLeft];
  static const List<String> _patternWhile = [HS_Common.While, HS_Common.RoundLeft];
  static const List<String> _patternForIn = [
    HS_Common.For,
    HS_Common.RoundLeft,
    HS_Common.Identifier,
    HS_Common.Identifier,
    HS_Common.In
  ];

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 如果consume为true，则在符合要求时向前移动Token指针
  ///
  /// 在不符合预期时，如果error为true，则抛出异常
  bool expect(List<String> tokTypes, {bool consume = false, bool error}) {
    error ??= consume;
    for (var i = 0; i < tokTypes.length; ++i) {
      if (consume) {
        if (curTok.type != tokTypes[i]) {
          if (error) {
            throw HSErr_Expected(tokTypes[i], curTok.lexeme, curTok.line, curTok.column);
          }
          return false;
        }
        ++_tokPos;
      } else {
        if (peek(i).type != tokTypes[i]) {
          return false;
        }
      }
    }
    return true;
  }

  /// 如果当前token符合要求则前进一步，然后返回之前的token，否则抛出异常
  Token match(String tokenType, {bool error = true}) {
    if (curTok.type == tokenType) {
      return advance(1);
    }

    if (error) throw HSErr_Expected(tokenType, curTok.lexeme, curTok.line, curTok.column);
    return Token.EOF;
  }

  /// 前进指定距离，返回原先位置的Token
  Token advance(int distance) {
    _tokPos += distance;
    return peek(-distance);
  }

  /// 获得相对于目前位置一定距离的Token，不改变目前位置
  Token peek(int pos) {
    if ((_tokPos + pos) < _tokens.length) {
      return _tokens[_tokPos + pos];
    } else {
      return Token.EOF;
    }
  }

  /// 获得当前Token
  Token get curTok => peek(0);

  List<Stmt> parse(
    List<Token> tokens, {
    Interpreter interpreter,
    ParseStyle style = ParseStyle.library,
  }) {
    _tokens.clear();
    _tokens.addAll(tokens);
    _tokPos = 0;

    _interpreter = interpreter ?? globalInterpreter;

    var statements = <Stmt>[];
    while (curTok.type != HS_Common.EOF) {
      statements.add(_parseStmt(style: style));
    }
    return statements;
  }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  Expr _parseExpr() {
    return _parseAssignmentExpr();
  }

  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  Expr _parseAssignmentExpr() {
    Expr expr = _parseLogicalOrExpr();

    if (HS_Common.Assignment.contains(curTok.type)) {
      Token op = advance(1);
      Expr value = _parseAssignmentExpr();

      if (expr is VarExpr) {
        Token name = expr.name;
        return AssignExpr(name, op, value);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value);
      } else if (expr is SubGetExpr) {
        return SubSetExpr(expr.collection, expr.key, value);
      }

      throw HSErr_InvalidLeftValue(op.lexeme, op.line, op.column);
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  Expr _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == HS_Common.Or) {
      var op = advance(1);
      var right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  Expr _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok.type == HS_Common.And) {
      var op = advance(1);
      var right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  Expr _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    while (HS_Common.Equality.contains(curTok.type)) {
      var op = advance(1);

      var right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  Expr _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    while (HS_Common.Relational.contains(curTok.type)) {
      var op = advance(1);

      var right = _parseAdditiveExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 加法 +, -，优先级 13，左合并
  Expr _parseAdditiveExpr() {
    var expr = _parseMultiplicativeExpr();
    while (HS_Common.Additive.contains(curTok.type)) {
      var op = advance(1);

      var right = _parseMultiplicativeExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 乘法 *, /, %，优先级 14，左合并
  Expr _parseMultiplicativeExpr() {
    var expr = _parseUnaryPrefixExpr();
    while (HS_Common.Multiplicative.contains(curTok.type)) {
      var op = advance(1);

      var right = _parseUnaryPrefixExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 前缀 -e, !e，优先级 15，不能合并
  Expr _parseUnaryPrefixExpr() {
    // 因为是前缀所以不能像别的表达式那样先进行下一级的分析
    Expr expr;
    if (HS_Common.UnaryPrefix.contains(curTok.type)) {
      var op = advance(1);

      expr = UnaryExpr(op, _parseUnaryPostfixExpr());
    } else {
      expr = _parseUnaryPostfixExpr();
    }
    return expr;
  }

  /// 后缀 e., e[], e()，优先级 16，取属性不能合并，下标和函数调用可以右合并
  Expr _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    //多层函数调用可以合并
    while (true) {
      if (expect([HS_Common.RoundLeft], consume: true, error: false)) {
        var params = <Expr>[];
        while ((curTok.type != HS_Common.RoundRight) && (curTok.type != HS_Common.EOF)) {
          params.add(_parseExpr());
          match(HS_Common.Comma, error: false);
        }
        expect([HS_Common.RoundRight], consume: true);
        expr = CallExpr(expr, params);
      } else if (expect([HS_Common.Dot], consume: true, error: false)) {
        Token name = match(HS_Common.Identifier);
        expr = MemberGetExpr(expr, name);
      } else if (expect([HS_Common.SquareLeft], consume: true, error: false)) {
        var index_expr = _parseExpr();
        expect([HS_Common.SquareRight], consume: true);
        expr = SubGetExpr(expr, index_expr);
      } else {
        break;
      }
    }
    return expr;
  }

  /// 只有一个Token的简单表达式
  Expr _parsePrimaryExpr() {
    if (HS_Common.Literals.contains(curTok.type)) {
      int index;
      if (curTok.literal == HS_Common.Null) {
        advance(1);
        return NullExpr(peek(-1).line, peek(-1).column);
      } else if (curTok.literal is num) {
        index = _interpreter.addLiteral(curTok.literal);
      } else if (curTok.literal is bool) {
        index = _interpreter.addLiteral(curTok.literal);
      } else if (curTok.literal is String) {
        index = _interpreter.addLiteral(HS_Common.convertEscapeCode(curTok.literal));
      }
      advance(1);
      return LiteralExpr(index, peek(-1).line, peek(-1).column);
    } else if (curTok.type == HS_Common.This) {
      advance(1);
      return ThisExpr(peek(-1));
    } else if (curTok.type == HS_Common.Identifier) {
      advance(1);
      return VarExpr(peek(-1));
    } else if (curTok.type == HS_Common.RoundLeft) {
      advance(1);
      var innerExpr = _parseExpr();
      expect([HS_Common.RoundRight], consume: true);
      return GroupExpr(innerExpr);
    } else if (curTok.type == HS_Common.SquareLeft) {
      int line = curTok.line;
      int col = advance(1).column;
      var list_expr = <Expr>[];
      while (curTok.type != HS_Common.SquareRight) {
        list_expr.add(_parseExpr());
        match(HS_Common.Comma, error: false);
      }
      expect([HS_Common.SquareRight], consume: true);
      return ListExpr(list_expr, line, col);
    } else if (curTok.type == HS_Common.CurlyLeft) {
      int line = curTok.line;
      int col = advance(1).column;
      var map_expr = <Expr, Expr>{};
      while (curTok.type != HS_Common.CurlyRight) {
        var key_expr = _parseExpr();
        expect([HS_Common.Colon], consume: true);
        var value_expr = _parseExpr();
        expect([HS_Common.Comma], consume: true, error: false);
        map_expr[key_expr] = value_expr;
      }
      expect([HS_Common.CurlyRight], consume: true);
      return MapExpr(map_expr, line, col);
    } else {
      throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
    }
  }

  Stmt _parseStmt({ParseStyle style = ParseStyle.library}) {
    switch (style) {
      case ParseStyle.library:
        {
          bool is_extern = expect([HS_Common.External], consume: true, error: false);
          if (expect(_patternImport)) {
            return _parseImportStmt();
          }
          // 如果是变量声明
          else if (expect(_patternVarDecl) || expect(_patternVarDeclInit)) {
            return _parseVarStmt(is_extern: is_extern);
          } // 如果是类声明
          else if (expect([HS_Common.Class, HS_Common.Identifier, HS_Common.CurlyLeft]) ||
              expect([
                HS_Common.Class,
                HS_Common.Identifier,
                HS_Common.Extends,
                HS_Common.Identifier,
                HS_Common.CurlyLeft
              ])) {
            return _parseClassStmt();
          } // 其他语句都认为是函数声明
          else {
            return _parseFunctionStmt(is_extern: is_extern);
          }
        }
        break;
      case ParseStyle.program:
        {
          // 函数块中不能出现extern或者static关键字的声明
          // 如果是变量声明
          if (expect(_patternVarDecl) || expect(_patternVarDeclInit)) {
            return _parseVarStmt();
          } // 如果是赋值语句
          else if (expect(_patternAssign)) {
            return _parseAssignStmt();
          } // 如果是跳出语句
          else if (curTok.type == HS_Common.Break) {
            return BreakStmt();
          } // 如果是返回语句
          else if (curTok.type == HS_Common.Return) {
            return _parseReturnStmt();
          } // 如果是If语句
          else if (expect(_patternIf)) {
            return _parseIfStmt();
          } // 如果是While语句
          else if (expect(_patternWhile)) {
            return _parseWhileStmt();
          } // 如果是ForIn语句
          else if (expect(_patternForIn)) {
            return _parseForInStmt();
          }
          // 其他语句都认为是表达式
          else {
            return _parseExprStmt();
          }
        }
        break;
      case ParseStyle.classDefinition:
        {
          bool is_extern = expect([HS_Common.External], consume: true, error: false);
          bool is_static = expect([HS_Common.Static], consume: true, error: false);
          // 如果是变量声明
          if (expect(_patternVarDecl) || expect(_patternVarDeclInit)) {
            return _parseVarStmt(is_extern: is_extern, is_static: is_static);
          } // 如果是构造函数
          // TODO：命名的构造函数
          else if ((curTok.lexeme == _curClassName) &&
              ((peek(1).type == HS_Common.RoundLeft) || (peek(1).type == HS_Common.Dot))) {
            return _parseConstructorStmt(is_extern: is_extern);
          } // 其他语句都认为是函数声明
          else {
            return _parseFunctionStmt(is_extern: is_extern, is_static: is_static);
          }
        }
        break;
    }
    return null;
  }

  List<Stmt> _parseBlock({ParseStyle style = ParseStyle.library}) {
    var stmts = <Stmt>[];
    while ((curTok.type != HS_Common.CurlyRight) && (curTok.type != HS_Common.EOF)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HS_Common.CurlyRight], consume: true);
    return stmts;
  }

  BlockStmt _parseBlockStmt({ParseStyle style = ParseStyle.library}) {
    var stmts = <Stmt>[];
    while ((curTok.type != HS_Common.CurlyRight) && (curTok.type != HS_Common.EOF)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HS_Common.CurlyRight], consume: true);
    return BlockStmt(stmts);
  }

  ImportStmt _parseImportStmt() {
    // 之前校验过了所以这里直接跳过
    advance(1);
    var stmt = ImportStmt(match(HS_Common.Str).literal);
    expect([HS_Common.Semicolon], consume: true);
    return stmt;
  }

  /// 变量声明语句
  VarStmt _parseVarStmt({bool is_extern = false, bool is_static = false}) {
    // if (!HS_Common.BuildInTypes.contains(curTok.lexeme)) {
    //   throw HSErr_Undefined(curTok.lexeme, curTok.line, curTok.column);
    // }
    var typename = curTok;
    var varname = peek(1);
    // 之前已经校验过了所以这里直接跳过
    advance(2);
    var initializer;
    if (expect([HS_Common.Assign], consume: true, error: false)) {
      initializer = _parseExpr();
    }
    // 语句一定以分号结尾
    expect([HS_Common.Semicolon], consume: true);
    return VarStmt(typename, varname, initializer: initializer, isExtern: is_extern, isStatic: is_static);
  }

  /// 为了避免涉及复杂的左值右值问题，赋值语句在河图中不作为表达式处理
  /// 而是分成直接赋值，取值后复制和取属性后复制
  ExprStmt _parseAssignStmt() {
    // 之前已经校验过等于号了所以这里直接跳过
    var name = advance(1);
    var assignTok = advance(1);
    var value = _parseExpr();
    // 语句一定以分号结尾
    expect([HS_Common.Semicolon], consume: true);
    var expr = AssignExpr(name, assignTok, value);
    return ExprStmt(expr);
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句一定以分号结尾
    expect([HS_Common.Semicolon], consume: true);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    Expr expr;
    if (curTok.type != HS_Common.Semicolon) {
      expr = _parseExpr();
    }
    expect([HS_Common.Semicolon], consume: true);
    return ReturnStmt(keyword, expr);
  }

  IfStmt _parseIfStmt() {
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    var condition = _parseExpr();
    expect([HS_Common.RoundRight], consume: true);
    Stmt thenBranch;
    if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
      thenBranch = _parseBlockStmt(style: ParseStyle.program);
    } else {
      thenBranch = _parseStmt(style: ParseStyle.program);
    }
    Stmt elseBranch;
    if (expect([HS_Common.Else], consume: true, error: false)) {
      if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
        elseBranch = _parseBlockStmt(style: ParseStyle.program);
      } else {
        elseBranch = _parseStmt(style: ParseStyle.program);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch);
  }

  WhileStmt _parseWhileStmt() {
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    var condition = _parseExpr();
    expect([HS_Common.RoundRight], consume: true);
    Stmt loop;
    if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
      loop = _parseBlockStmt(style: ParseStyle.program);
    } else {
      loop = _parseStmt(style: ParseStyle.program);
    }
    return WhileStmt(condition, loop);
  }

  /// ForIn语句其实会在解析时转换为While语句
  BlockStmt _parseForInStmt() {
    var list_stmt = <Stmt>[];
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    // 递增变量
    String i = 'int${DateTime.now().millisecondsSinceEpoch}';
    list_stmt.add(VarStmt(
        TokenIdentifier(HS_Common.Num, curTok.line, curTok.column), TokenIdentifier(i, curTok.line, curTok.column),
        initializer: LiteralExpr(globalInterpreter.addLiteral(0), curTok.line, curTok.column)));
    // 指针
    var typename = match(HS_Common.Identifier);
    var varname = match(HS_Common.Identifier);
    list_stmt.add(VarStmt(typename, varname));
    expect([HS_Common.In], consume: true);
    var list_obj = _parseExpr();
    // 条件语句
    var get_length = MemberGetExpr(list_obj, Token(HS_Common.length, curTok.line, curTok.column));
    var condition = BinaryExpr(VarExpr(TokenIdentifier(i, curTok.line, curTok.column)),
        Token(HS_Common.Lesser, curTok.line, curTok.column), get_length);
    // 在循环体之前手动插入递增语句和指针语句
    // 按下标取数组元素
    var loop_body = <Stmt>[];
    var sub_get_value = SubGetExpr(list_obj, VarExpr(TokenIdentifier(i, curTok.line, curTok.column)));
    var assign_stmt = ExprStmt(AssignExpr(TokenIdentifier(varname.lexeme, curTok.line, curTok.column),
        Token(HS_Common.Assign, curTok.line, curTok.column), sub_get_value));
    loop_body.add(assign_stmt);
    // 递增下标变量
    var increment_expr = BinaryExpr(
        VarExpr(TokenIdentifier(i, curTok.line, curTok.column)),
        Token(HS_Common.Add, curTok.line, curTok.column),
        LiteralExpr(globalInterpreter.addLiteral(1), curTok.line, curTok.column));
    var increment_stmt = ExprStmt(AssignExpr(TokenIdentifier(i, curTok.line, curTok.column),
        Token(HS_Common.Assign, curTok.line, curTok.column), increment_expr));
    loop_body.add(increment_stmt);
    // 循环体
    expect([HS_Common.RoundRight], consume: true);
    if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
      loop_body.addAll(_parseBlock(style: ParseStyle.program));
    } else {
      loop_body.add(_parseStmt(style: ParseStyle.program));
    }
    list_stmt.add(WhileStmt(condition, BlockStmt(loop_body)));
    return BlockStmt(list_stmt);
  }

  List<VarStmt> _parseParameters() {
    var result = <VarStmt>[];
    while ((curTok.type != HS_Common.RoundRight) && (curTok.type != HS_Common.EOF)) {
      if (result.isNotEmpty) {
        expect([HS_Common.Comma], consume: true, error: false);
      }
      if (expect([HS_Common.Identifier, HS_Common.Identifier])) {
        if (HS_Common.ParametersTypes.contains(curTok.lexeme)) {
          //TODO，参数默认值、可选参数、命名参数
          result.add(VarStmt(curTok, peek(1)));
          advance(2);
        } else {
          throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
        }
      } else {
        throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column);
      }
    }
    expect([HS_Common.RoundRight], consume: true);
    return result;
  }

  FuncStmt _parseFunctionStmt({bool is_extern = false, bool is_static = false}) {
    FuncStmtType functype = FuncStmtType.normal;
    var return_type;
    if (expect([HS_Common.Set], consume: true, error: false)) {
      return_type = HS_Common.Void;
      functype = FuncStmtType.setter;
    } else {
      if (!HS_Common.FunctionReturnTypes.contains(curTok.lexeme)) {
        throw HSErr_Undefined(curTok.lexeme, curTok.line, curTok.column);
      }
      return_type = match(HS_Common.Identifier).lexeme;
      if (expect([HS_Common.Get], consume: true, error: false)) {
        functype = FuncStmtType.getter;
      }
    }
    var func_name = match(HS_Common.Identifier);
    int arity = 0;
    var params = <VarStmt>[];
    if (functype != FuncStmtType.getter) {
      // 之前还没有校验过左括号
      expect([HS_Common.RoundLeft], consume: true);
      if (expect([HS_Common.Unknown], consume: true, error: false)) {
        arity = -1;
        expect([HS_Common.RoundRight], consume: true);
      } else {
        params = _parseParameters();
        arity = params.length;
      }
      if ((functype == FuncStmtType.setter) && (arity != 1)) throw HSErr_Setter(func_name.line, func_name.column);
    }
    var body = <Stmt>[];
    if (!is_extern) {
      // 处理函数定义部分的语句块
      expect([HS_Common.CurlyLeft], consume: true);
      body = _parseBlock(style: ParseStyle.program);
    } else {
      expect([HS_Common.Semicolon], consume: true);
    }
    return FuncStmt(return_type, func_name, params,
        arity: arity,
        definition: body,
        className: _curClassName,
        isExtern: is_extern,
        isStatic: is_static,
        functype: functype);
  }

  FuncStmt _parseConstructorStmt({bool is_extern = false}) {
    var name = advance(1);
    if (expect([HS_Common.Dot], consume: true, error: false)) {
      name = match(HS_Common.Identifier);
    }
    expect([HS_Common.RoundLeft], consume: true);
    var params = <VarStmt>[];
    int arity;
    if (expect([HS_Common.Unknown], consume: true, error: false)) {
      arity = -1;
      expect([HS_Common.RoundRight], consume: true);
    } else {
      params = _parseParameters();
      arity = params.length;
    }
    var body = <Stmt>[];
    if (!is_extern) {
      expect([HS_Common.CurlyLeft], consume: true);
      body = _parseBlock(style: ParseStyle.program);
    } else {
      expect([HS_Common.Semicolon], consume: true);
    }
    return FuncStmt(HS_Common.Null, name, params,
        arity: arity,
        definition: body,
        className: _curClassName,
        isExtern: is_extern,
        functype: FuncStmtType.constructor);
  }

  ClassStmt _parseClassStmt() {
    ClassStmt stmt;
    // 已经判断过了所以直接跳过Class关键字
    advance(1);
    var class_name = curTok;
    _curClassName = advance(1).lexeme;
    VarExpr super_class;
    // 继承父类
    if (expect([HS_Common.Extends], consume: true, error: false)) {
      super_class = VarExpr(match(HS_Common.Identifier));
    }
    // 类的定义体
    expect([HS_Common.CurlyLeft], consume: true);
    var variables = <VarStmt>[];
    var methods = <FuncStmt>[];
    while ((curTok.type != HS_Common.CurlyRight) && (curTok.type != HS_Common.EOF)) {
      var stmt = _parseStmt(style: ParseStyle.classDefinition);
      if (stmt is VarStmt) {
        variables.add(stmt);
      } else if (stmt is FuncStmt) {
        methods.add(stmt);
      }
    }
    expect([HS_Common.CurlyRight], consume: true);

    stmt = ClassStmt(class_name, super_class, variables, methods);
    _curClassName = null;
    return stmt;
  }
}
