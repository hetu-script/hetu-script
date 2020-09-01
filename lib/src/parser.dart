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
  function,

  /// 类定义中只能出现变量和函数的声明
  classDefinition,

  commandLine,
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
  final Interpreter interpreter;

  final List<Token> _tokens = [];
  var _tokPos = 0;
  Token _curClassName;
  String _curFileName;

  static int internalVarIndex = 0;

  static const List<String> _patternAssign = [HS_Common.Identifier, HS_Common.Assign];

  Parser(this.interpreter);

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 如果consume为true，则在符合要求时向前移动Token指针
  ///
  /// 在不符合预期时，如果error为true，则抛出异常
  bool expect(List<String> tokTypes, {bool consume = false, bool error}) {
    error ??= consume;
    for (var i = 0; i < tokTypes.length; ++i) {
      if (consume) {
        if (curTok != tokTypes[i]) {
          if (error) {
            throw HSErr_Expected(tokTypes[i], curTok.lexeme, curTok.line, curTok.column, _curFileName);
          }
          return false;
        }
        ++_tokPos;
      } else {
        if (peek(i) != tokTypes[i]) {
          return false;
        }
      }
    }
    return true;
  }

  /// 如果当前token符合要求则前进一步，然后返回之前的token，否则抛出异常
  Token match(String tokenType, {bool error = true}) {
    if (curTok == tokenType) {
      return advance(1);
    }

    if (error) throw HSErr_Expected(tokenType, curTok.lexeme, curTok.line, curTok.column, _curFileName);
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
  // {
  // var cur = peek(0);
  // if (cur == HS_Common.Multiline) {
  //   advance(1);
  //   cur = peek(0);
  // }
  // return cur;
  // }

  List<Stmt> parse(
    List<Token> tokens,
    String fileName, {
    ParseStyle style = ParseStyle.library,
  }) {
    _tokens.clear();
    _tokens.addAll(tokens);
    _tokPos = 0;
    _curFileName = fileName;

    var statements = <Stmt>[];
    try {
      while (curTok != HS_Common.EOF) {
        var stmt = _parseStmt(style: style);
        if (stmt != null) statements.add(stmt);
      }
    } catch (e) {
      print(e);
    } finally {
      return statements;
    }
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
        return AssignExpr(name, op, value, _curFileName);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value, _curFileName);
      } else if (expr is SubGetExpr) {
        return SubSetExpr(expr.collection, expr.key, value, _curFileName);
      }

      throw HSErr_InvalidLeftValue(op.lexeme, op.line, op.column, _curFileName);
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  Expr _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok == HS_Common.Or) {
      var op = advance(1);
      var right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  Expr _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok == HS_Common.And) {
      var op = advance(1);
      var right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  Expr _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    while (HS_Common.Equality.contains(curTok.type)) {
      var op = advance(1);

      var right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  Expr _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    while (HS_Common.Relational.contains(curTok.type)) {
      var op = advance(1);
      var right = _parseAdditiveExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 加法 +, -，优先级 13，左合并
  Expr _parseAdditiveExpr() {
    var expr = _parseMultiplicativeExpr();
    while (HS_Common.Additive.contains(curTok.type)) {
      var op = advance(1);

      var right = _parseMultiplicativeExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 乘法 *, /, %，优先级 14，左合并
  Expr _parseMultiplicativeExpr() {
    var expr = _parseUnaryPrefixExpr();
    while (HS_Common.Multiplicative.contains(curTok.type)) {
      var op = advance(1);

      var right = _parseUnaryPrefixExpr();
      expr = BinaryExpr(expr, op, right, _curFileName);
    }
    return expr;
  }

  /// 前缀 -e, !e，优先级 15，不能合并
  Expr _parseUnaryPrefixExpr() {
    // 因为是前缀所以不能像别的表达式那样先进行下一级的分析
    Expr expr;
    if (HS_Common.UnaryPrefix.contains(curTok.type)) {
      var op = advance(1);

      expr = UnaryExpr(op, _parseUnaryPostfixExpr(), _curFileName);
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
        while ((curTok != HS_Common.RoundRight) && (curTok != HS_Common.EOF)) {
          params.add(_parseExpr());
          if (curTok != HS_Common.RoundRight) {
            expect([HS_Common.Comma], consume: true);
          }
        }
        expect([HS_Common.RoundRight], consume: true);
        expr = CallExpr(expr, params, _curFileName);
      } else if (expect([HS_Common.Dot], consume: true, error: false)) {
        Token name = match(HS_Common.Identifier);
        expr = MemberGetExpr(expr, name, _curFileName);
      } else if (expect([HS_Common.SquareLeft], consume: true, error: false)) {
        var index_expr = _parseExpr();
        expect([HS_Common.SquareRight], consume: true);
        expr = SubGetExpr(expr, index_expr, _curFileName);
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
      if (curTok == HS_Common.Null) {
        advance(1);
        return NullExpr(peek(-1).line, peek(-1).column, _curFileName);
      } else if (curTok == HS_Common.Num) {
        index = interpreter.addLiteral(curTok.literal);
      } else if (curTok == HS_Common.Bool) {
        index = interpreter.addLiteral(curTok.literal);
      } else if (curTok == HS_Common.Str) {
        index = interpreter.addLiteral(HS_Common.convertEscapeCode(curTok.literal));
      }
      advance(1);
      return LiteralExpr(index, peek(-1).line, peek(-1).column, _curFileName);
    } else if (curTok == HS_Common.This) {
      advance(1);
      return ThisExpr(peek(-1), _curFileName);
    } else if (curTok == HS_Common.Identifier) {
      advance(1);
      return VarExpr(peek(-1), _curFileName);
    } else if (curTok == HS_Common.RoundLeft) {
      advance(1);
      var innerExpr = _parseExpr();
      expect([HS_Common.RoundRight], consume: true);
      return GroupExpr(innerExpr, _curFileName);
    } else if (curTok == HS_Common.SquareLeft) {
      int line = curTok.line;
      int col = advance(1).column;
      var list_expr = <Expr>[];
      while (curTok != HS_Common.SquareRight) {
        list_expr.add(_parseExpr());
        if (curTok != HS_Common.SquareRight) {
          expect([HS_Common.Comma], consume: true);
        }
      }
      expect([HS_Common.SquareRight], consume: true);
      return VectorExpr(list_expr, line, col, _curFileName);
    } else if (curTok == HS_Common.CurlyLeft) {
      int line = curTok.line;
      int col = advance(1).column;
      var map_expr = <Expr, Expr>{};
      while (curTok != HS_Common.CurlyRight) {
        var key_expr = _parseExpr();
        expect([HS_Common.Colon], consume: true);
        var value_expr = _parseExpr();
        expect([HS_Common.Comma], consume: true, error: false);
        map_expr[key_expr] = value_expr;
      }
      expect([HS_Common.CurlyRight], consume: true);
      return BlockExpr(map_expr, line, col, _curFileName);
    } else {
      throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column, _curFileName);
    }
  }

  Stmt _parseStmt({ParseStyle style = ParseStyle.library}) {
    if (curTok == HS_Common.Newline) advance(1);
    switch (style) {
      case ParseStyle.library:
        {
          bool is_extern = expect([HS_Common.External], consume: true, error: false);
          if (expect([HS_Common.Import])) {
            return _parseImportStmt();
          }
          // 变量声明
          else if (expect([HS_Common.Var])) {
            return _parseVarStmt(is_extern: is_extern);
          } // 类声明
          else if (expect([HS_Common.Class])) {
            return _parseClassStmt();
          } // 函数声明
          else if (expect([HS_Common.Func])) {
            return _parseFunctionStmt(FuncStmtType.normal, is_extern: is_extern);
          } else {
            throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column, _curFileName);
          }
        }
        break;
      case ParseStyle.function:
        {
          // 函数块中不能出现extern或者static关键字的声明
          // 变量声明
          if (expect([HS_Common.Var])) {
            return _parseVarStmt();
          } // 赋值语句
          else if (expect(_patternAssign)) {
            return _parseAssignStmt();
          } //If语句
          else if (expect([HS_Common.If])) {
            return _parseIfStmt();
          } // While语句
          else if (expect([HS_Common.While])) {
            return _parseWhileStmt();
          } // For语句
          else if (expect([HS_Common.For])) {
            return _parseForStmt();
          } // 跳出语句
          else if (expect([HS_Common.Break])) {
            return BreakStmt();
          } // 继续语句
          else if (expect([HS_Common.Continue])) {
            return ContinueStmt();
          } // 函数声明
          else if (expect([HS_Common.Func])) {
            return _parseFunctionStmt(FuncStmtType.normal);
          } // 返回语句
          else if (curTok == HS_Common.Return) {
            return _parseReturnStmt();
          }
          // 表达式
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
          if (expect([HS_Common.Var])) {
            return _parseVarStmt(is_extern: is_extern, is_static: is_static);
          } // 构造函数
          // TODO：命名的构造函数
          else if (expect([HS_Common.Init])) {
            return _parseFunctionStmt(FuncStmtType.initter, is_extern: is_extern, is_static: is_static);
          } // setter函数声明
          else if (expect([HS_Common.Get])) {
            return _parseFunctionStmt(FuncStmtType.getter, is_extern: is_extern, is_static: is_static);
          } // getter函数声明
          else if (expect([HS_Common.Set])) {
            return _parseFunctionStmt(FuncStmtType.setter, is_extern: is_extern, is_static: is_static);
          } // 成员函数声明
          else if (expect([HS_Common.Func])) {
            return _parseFunctionStmt(FuncStmtType.method, is_extern: is_extern, is_static: is_static);
          } else {
            throw HSErr_Unexpected(curTok.lexeme, curTok.line, curTok.column, _curFileName);
          }
        }
        break;
      case ParseStyle.commandLine:
        {
          var callee = _parseExpr();
          var params = <Expr>[];
          while (curTok.type != HS_Common.EOF) {
            params.add(LiteralExpr(interpreter.addLiteral(curTok.lexeme), curTok.line, curTok.column, _curFileName));
            advance(1);
          }
          return ExprStmt(CallExpr(callee, params, _curFileName));
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
    String filename = match(HS_Common.Str).literal;
    String spacename;
    if (expect([HS_Common.As], consume: true, error: false)) {
      spacename = match(HS_Common.Identifier).lexeme;
    }
    var stmt = ImportStmt(filename, asspace: spacename);
    expect([HS_Common.Semicolon], consume: true, error: false);
    return stmt;
  }

  List<String> _parseTypeParams() {
    var typeParams = <String>[];
    while ((curTok != HS_Common.AngleRight) && (curTok != HS_Common.EOF)) {
      typeParams.add(advance(1).lexeme);
      expect([HS_Common.Comma], consume: true, error: false);
    }
    expect([HS_Common.AngleRight], consume: true);

    return typeParams;
  }

  /// 变量声明语句
  VarStmt _parseVarStmt({bool is_extern = false, bool is_static = false}) {
    advance(1);
    var varname = match(HS_Common.Identifier);
    String typename;
    if (expect([HS_Common.Colon], consume: true, error: false)) {
      typename = advance(1).lexeme;
    }
    var typeParams = <String>[];
    if (expect([HS_Common.AngleLeft], consume: true, error: false)) typeParams = _parseTypeParams();

    var initializer;
    if (expect([HS_Common.Assign], consume: true, error: false)) {
      initializer = _parseExpr();
    }
    // 语句结尾
    expect([HS_Common.Semicolon], consume: true, error: false);
    return VarStmt(varname, typename,
        typeparams: typeParams, initializer: initializer, isExtern: is_extern, isStatic: is_static);
  }

  /// 为了避免涉及复杂的左值右值问题，赋值语句在河图中不作为表达式处理
  /// 而是分成直接赋值，取值后复制和取属性后复制
  ExprStmt _parseAssignStmt() {
    // 之前已经校验过等于号了所以这里直接跳过
    var name = advance(1);
    var assignTok = advance(1);
    var value = _parseExpr();
    // 语句结尾
    expect([HS_Common.Semicolon], consume: true, error: false);
    var expr = AssignExpr(name, assignTok, value, _curFileName);
    return ExprStmt(expr);
  }

  ExprStmt _parseExprStmt({bool commandLine = false}) {
    var stmt = ExprStmt(_parseExpr());
    if (!commandLine) {
      // 语句结尾
      expect([HS_Common.Semicolon], consume: true, error: false);
    }
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    Expr expr;
    if (curTok.type != HS_Common.CurlyRight) {
      expr = _parseExpr();
    }
    expect([HS_Common.Semicolon], consume: true, error: false);
    return ReturnStmt(keyword, expr);
  }

  IfStmt _parseIfStmt() {
    advance(1);
    expect([HS_Common.RoundLeft], consume: true);
    var condition = _parseExpr();
    expect([HS_Common.RoundRight], consume: true);
    Stmt thenBranch;
    if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
      thenBranch = _parseBlockStmt(style: ParseStyle.function);
    } else {
      thenBranch = _parseStmt(style: ParseStyle.function);
    }
    Stmt elseBranch;
    if (expect([HS_Common.Else], consume: true, error: false)) {
      if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
        elseBranch = _parseBlockStmt(style: ParseStyle.function);
      } else {
        elseBranch = _parseStmt(style: ParseStyle.function);
      }
    }
    return IfStmt(condition, thenBranch, elseBranch);
  }

  WhileStmt _parseWhileStmt() {
    // 之前已经校验过括号了所以这里直接跳过
    advance(1);
    expect([HS_Common.CurlyLeft], consume: true);
    var condition = _parseExpr();
    expect([HS_Common.RoundRight], consume: true);
    Stmt loop;
    if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
      loop = _parseBlockStmt(style: ParseStyle.function);
    } else {
      loop = _parseStmt(style: ParseStyle.function);
    }
    return WhileStmt(condition, loop);
  }

  /// For语句其实会在解析时转换为While语句
  BlockStmt _parseForStmt() {
    var list_stmt = <Stmt>[];
    var line = curTok.line;
    var column = curTok.column;
    expect([HS_Common.For, HS_Common.RoundLeft], consume: true);
    // 递增变量
    String i = '__i${internalVarIndex++}';
    list_stmt.add(VarStmt(TokenIdentifier(i, line, column + 4), HS_Common.Num,
        initializer: LiteralExpr(interpreter.addLiteral(0), line, column, _curFileName)));
    // 指针
    var varname = match(HS_Common.Identifier);
    String typename;
    if (expect([HS_Common.Colon], consume: true, error: false)) {
      typename = advance(1).lexeme;
    }
    list_stmt.add(VarStmt(varname, typename));
    expect([HS_Common.In], consume: true);
    var list_obj = _parseExpr();
    // 条件语句
    var get_length = MemberGetExpr(list_obj, Token(HS_Common.length, line, column + 30), _curFileName);
    var condition = BinaryExpr(VarExpr(TokenIdentifier(i, line, column + 24), _curFileName),
        Token(HS_Common.Lesser, line, column + 26), get_length, _curFileName);
    // 在循环体之前手动插入递增语句和指针语句
    // 按下标取数组元素
    var loop_body = <Stmt>[];
    // 这里一定要复制一个list_obj的表达式，否则在resolve的时候会因为是相同的对象出错，覆盖掉上面那个表达式的位置
    var sub_get_value =
        SubGetExpr(list_obj.clone(), VarExpr(TokenIdentifier(i, line + 1, column + 14), _curFileName), _curFileName);
    var assign_stmt = ExprStmt(AssignExpr(TokenIdentifier(varname.lexeme, line + 1, column),
        Token(HS_Common.Assign, line + 1, column + 10), sub_get_value, _curFileName));
    loop_body.add(assign_stmt);
    // 递增下标变量
    var increment_expr = BinaryExpr(
        VarExpr(TokenIdentifier(i, line + 1, column + 18), _curFileName),
        Token(HS_Common.Add, line + 1, column + 22),
        LiteralExpr(interpreter.addLiteral(1), line + 1, column + 24, _curFileName),
        _curFileName);
    var increment_stmt = ExprStmt(AssignExpr(TokenIdentifier(i, line + 1, column),
        Token(HS_Common.Assign, line + 1, column + 20), increment_expr, _curFileName));
    loop_body.add(increment_stmt);
    // 循环体
    expect([HS_Common.RoundRight], consume: true);
    if (expect([HS_Common.CurlyLeft], consume: true, error: false)) {
      loop_body.addAll(_parseBlock(style: ParseStyle.function));
    } else {
      loop_body.add(_parseStmt(style: ParseStyle.function));
    }
    list_stmt.add(WhileStmt(condition, BlockStmt(loop_body)));
    return BlockStmt(list_stmt);
  }

  List<VarStmt> _parseParameters() {
    var params = <VarStmt>[];
    bool optionalStarted = false;
    while ((curTok != HS_Common.RoundRight) && (curTok != HS_Common.SquareRight) && (curTok != HS_Common.EOF)) {
      if (params.isNotEmpty) {
        expect([HS_Common.Comma], consume: true, error: false);
      }
      // 可选参数，根据是否有方括号判断，一旦开始了可选参数，则不再增加参数数量arity要求
      if (!optionalStarted) {
        optionalStarted = expect([HS_Common.SquareLeft], error: false, consume: true);
      }
      var varname = match(HS_Common.Identifier);
      String typename;
      if (expect([HS_Common.Colon], consume: true, error: false)) {
        typename = advance(1).lexeme;
      }
      var typeParams = <String>[];
      if (expect([HS_Common.AngleLeft], consume: true, error: false)) {
        typeParams = _parseTypeParams();
      }

      Expr initializer;
      if (optionalStarted) {
        //参数默认值
        if (expect([HS_Common.Assign], error: false, consume: true)) {
          initializer = _parseExpr();
        }
      }
      params.add(VarStmt(varname, typename, typeparams: typeParams, initializer: initializer));
    }

    if (optionalStarted) expect([HS_Common.SquareRight], consume: true);
    expect([HS_Common.RoundRight], consume: true);
    return params;
  }

  FuncStmt _parseFunctionStmt(FuncStmtType functype, {bool is_extern = false, bool is_static = false}) {
    advance(1);
    Token func_name;
    if (functype != FuncStmtType.initter) {
      func_name = match(HS_Common.Identifier);
    } else {
      if (curTok == HS_Common.RoundLeft) {
        func_name = _curClassName;
      }
    }

    int arity = 0;
    var params = <VarStmt>[];

    if (functype != FuncStmtType.getter) {
      // 之前还没有校验过左括号
      if (expect([HS_Common.RoundLeft], consume: true, error: false)) {
        if (expect([HS_Common.VariadicArguments])) {
          arity = -1;
          advance(1);
        }
        params = _parseParameters();

        if (arity != -1) arity = params.length;

        // setter只能有一个参数，就是赋值语句的右值，但此处并不需要判断类型
        if ((functype == FuncStmtType.setter) && (arity != 1))
          throw HSErr_Setter(curTok.line, curTok.column, _curFileName);
      }
    }

    String return_type = HS_Common.Void;
    var return_type_params = <String>[];

    if (functype != FuncStmtType.initter) {
      if (expect([HS_Common.Colon], consume: true, error: false)) {
        return_type = advance(1).lexeme;
        if (expect([HS_Common.AngleLeft], consume: true, error: false)) {
          return_type_params = _parseTypeParams();
        }
      }
    }

    var body = <Stmt>[];
    if (!is_extern) {
      // 处理函数定义部分的语句块
      expect([HS_Common.CurlyLeft], consume: true);
      body = _parseBlock(style: ParseStyle.function);
    } else {
      expect([HS_Common.Semicolon], consume: true, error: false);
    }
    return FuncStmt(return_type, func_name, params,
        returnTypeParams: return_type_params,
        arity: arity,
        definition: body,
        className: _curClassName?.lexeme,
        isExtern: is_extern,
        isStatic: is_static,
        functype: functype);
  }

  ClassStmt _parseClassStmt() {
    ClassStmt stmt;
    // 已经判断过了所以直接跳过Class关键字
    advance(1);
    var className = curTok;
    _curClassName = advance(1);

    var type_params = <String>[];

    if (expect([HS_Common.AngleLeft], consume: true, error: false)) {
      type_params = _parseTypeParams();
    }

    VarExpr super_class;
    // 继承父类
    if (expect([HS_Common.Extends], consume: true, error: false)) {
      super_class = VarExpr(match(HS_Common.Identifier), _curFileName);
    }
    // 类的定义体
    expect([HS_Common.CurlyLeft], consume: true);
    var variables = <VarStmt>[];
    var methods = <FuncStmt>[];
    if (curTok != HS_Common.CurlyRight) {
      while ((curTok.type != HS_Common.CurlyRight) && (curTok.type != HS_Common.EOF)) {
        var stmt = _parseStmt(style: ParseStyle.classDefinition);
        if (stmt is VarStmt) {
          variables.add(stmt);
        } else if (stmt is FuncStmt) {
          methods.add(stmt);
        }
      }
      expect([HS_Common.CurlyRight], consume: true);
    } else {
      advance(1);
    }

    stmt = ClassStmt(className, super_class, variables, methods, typeParams: type_params);
    _curClassName = null;
    return stmt;
  }
}
