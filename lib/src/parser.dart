import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'token.dart';
import 'common.dart';
import 'interpreter.dart';
import 'class.dart';

enum ParseStyle {
  /// 程序脚本使用完整的标点符号规则，包括各种括号、逗号和分号
  ///
  /// 程序脚本中只能出现变量、类和函数的声明
  ///
  /// 程序脚本中必有一个叫做main的完整函数作为入口
  program,

  /// 函数语句块中只能出现变量声明、控制语句和函数调用
  functionDefinition,

  /// 类定义中只能出现变量和函数的声明
  classDefinition,

  /// 命令行环境下整个输入当做一条表达式语句
  ///
  /// 第一个标识符被识别为函数名称
  ///
  /// 之后的标识符全部被作为函数参数
  ///
  /// 用空格代替脚本中的括号和逗号
  commandLine,

  /// 由命令行的语句汇集成的脚本，可以出现变量声明，以分号作为语句结束
  commandLineScript,
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
  var _position = 0;
  Context _context;
  String _curClassName;

  static const List<String> _patternDecl = [Common.Identifier, Common.Identifier, Common.Semicolon];
  static const List<String> _patternInit = [Common.Identifier, Common.Identifier, Common.Assign];
  static const List<String> _patternFuncDecl = [Common.Identifier, Common.Identifier, Common.RoundLeft];
  static const List<String> _patternAssign = [Common.Identifier, Common.Assign];
  static const List<String> _patternIf = [Common.If, Common.RoundLeft];
  static const List<String> _patternWhile = [Common.While, Common.RoundLeft];

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 如果consume为true，则向前移动Token指针，并且会在不符合预期时记录错误
  bool expect(List<String> tokenTypes, {bool consume = false}) {
    var result = true;
    for (var i = 0; i < tokenTypes.length; ++i) {
      if (consume) {
        if (curTok.type != tokenTypes[i]) {
          result = false;
        }
        ++_position;
      } else {
        if (peek(i).type != tokenTypes[i]) {
          result = false;
          break;
        }
      }
    }
    return result;
  }

  Token advance(int distance) {
    _position += distance;
    return curTok;
  }

  Token peek(int pos) {
    if ((_position + pos) < _tokens.length) {
      return _tokens[_position + pos];
    } else {
      return Token.EOF;
    }
  }

  Token get curTok => peek(0);

  List<Stmt> parse(
    List<Token> tokens, {
    Context context,
    ParseStyle style = ParseStyle.program,
  }) {
    _tokens.clear();
    _tokens.addAll(tokens);
    _position = 0;

    _context = context ?? globalContext;

    var statements = <Stmt>[];
    while (curTok.type != Common.EOF) {
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

    if (Common.Assignment.contains(curTok.type)) {
      Token op = curTok;
      advance(1);
      Expr value = _parseAssignmentExpr();

      if (expr is VarExpr) {
        Token name = expr.name;
        return AssignExpr(name, op, value);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value);
      }

      throw HetuErrorInvalidLeftValue('', op.line, op.column);
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  Expr _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == Common.Or) {
      var op = curTok;
      advance(1);
      var right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  Expr _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok.type == Common.And) {
      var op = curTok;
      advance(1);
      var right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  Expr _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    while (Common.Equality.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  Expr _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    while (Common.Relational.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseAdditiveExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 加法 +, -，优先级 13，左合并
  Expr _parseAdditiveExpr() {
    var expr = _parseMultiplicativeExpr();
    while (Common.Additive.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseMultiplicativeExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 乘法 *, /, %，优先级 14，左合并
  Expr _parseMultiplicativeExpr() {
    var expr = _parseUnaryPrefixExpr();
    while (Common.Multiplicative.contains(curTok.type)) {
      var op = curTok;
      advance(1);
      var right = _parseUnaryPrefixExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 前缀 -e, !e，优先级 15，不能合并
  Expr _parseUnaryPrefixExpr() {
    // 因为是前缀所以不能像别的表达式那样先进行下一级的分析
    Expr expr;
    if (Common.UnaryPrefix.contains(curTok.type)) {
      var op = curTok;
      advance(1);
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
      if (curTok.lexeme == Common.RoundLeft) {
        advance(1);
        var params = <Expr>[];
        while ((curTok.type != Common.RoundRight) && (curTok.type != Common.EOF)) {
          params.add(_parseExpr());
          if (curTok.type == Common.Comma) {
            advance(1);
          }
        }
        expr = CallExpr(expr, params);
        expect([Common.RoundRight], consume: true);
      } else if (curTok.lexeme == Common.Dot) {
        advance(1);
        if (curTok.type == Common.Identifier) {
          Token name = curTok;
          expr = MemberGetExpr(expr, name);
          advance(1);
        } else {
          throw HetuErrorUnexpected(curTok.lexeme, curTok.line, curTok.column);
        }
      } else {
        break;
      }
    }

    return expr;
  }

  /// 只有一个Token的简单表达式
  Expr _parsePrimaryExpr() {
    Expr expr;
    if (Common.Literals.contains(curTok.type)) {
      int index;
      if (curTok.literal is num) {
        index = _context.addLiteral(LNum(curTok.literal));
      } else if (curTok.literal is bool) {
        index = _context.addLiteral(LBool(curTok.literal));
      } else if (curTok.literal is String) {
        index = _context.addLiteral(LString(curTok.literal));
      }
      expr = LiteralExpr(index, curTok.line, curTok.column);
      advance(1);
    } else if (curTok.type == Common.This) {
      expr = ThisExpr(curTok);
      advance(1);
    } else if (curTok.type == Common.Identifier) {
      expr = VarExpr(curTok);
      advance(1);
    } else if (curTok.type == Common.RoundLeft) {
      advance(1);
      var innerExpr = _parseExpr();
      expect([Common.RoundRight], consume: true);
      expr = GroupExpr(innerExpr);
    } else {
      throw HetuErrorUnexpected(curTok.lexeme, curTok.line, curTok.column);
    }
    return expr;
  }

  Stmt _parseStmt({ParseStyle style = ParseStyle.program}) {
    Stmt stmt;

    switch (style) {
      case ParseStyle.program:
        {
          // 如果是变量声明
          if (expect(_patternDecl)) {
            stmt = _parseVarStmt();
          } // 如果是带初始化语句的变量声明
          else if (expect(_patternInit)) {
            stmt = _parseVarInitStmt();
          } // 如果是函数声明
          else if (expect(_patternFuncDecl)) {
            stmt = _parseFunctionStmt();
          } // 如果是类声明
          else if (expect([Common.Class, Common.Identifier, Common.CurlyLeft]) ||
              expect([Common.Class, Common.Identifier, Common.Extends, Common.Identifier, Common.CurlyLeft])) {
            stmt = _parseClassStmt();
          } else {
            throw HetuErrorUnexpected(curTok.lexeme, curTok.line, curTok.column);
          }
        }
        break;
      case ParseStyle.functionDefinition:
        {
          // 如果是变量声明
          if (expect(_patternDecl)) {
            stmt = _parseVarStmt();
          } // 如果是带初始化语句的变量声明
          else if (expect(_patternInit)) {
            stmt = _parseVarInitStmt();
          } // 如果是赋值语句
          else if (expect(_patternAssign)) {
            stmt = _parseAssignStmt();
          } // 如果是跳出语句
          else if (curTok.type == Common.Break) {
            stmt = BreakStmt();
          } // 如果是返回语句
          else if (curTok.type == Common.Return) {
            stmt = _parseReturnStmt();
          } // 如果是If语句
          else if (expect(_patternIf)) {
            stmt = _parseIfStmt();
          } // 如果是While语句
          else if (expect(_patternWhile)) {
            stmt = _parseWhileStmt();
          } // 其他语句都认为是表达式
          else {
            stmt = _parseExprStmt();
          }
        }
        break;
      case ParseStyle.classDefinition:
        {
          // 如果是变量声明
          if (expect(_patternDecl)) {
            stmt = _parseVarStmt();
          } // 如果是带初始化语句的变量声明
          else if (expect(_patternInit)) {
            stmt = _parseVarInitStmt();
          } // 如果是构造函数
          // TODO：命名的构造函数
          else if ((curTok.lexeme == _curClassName) && (peek(1).type == Common.RoundLeft)) {
            stmt = _parseConstructorStmt();
            // 如果是函数声明
          } else if (expect(_patternFuncDecl)) {
            stmt = _parseFunctionStmt();
          } else {
            throw HetuErrorUnexpected(curTok.lexeme, curTok.line, curTok.column);
          }
        }
        break;
      case ParseStyle.commandLine:
        stmt = _parseCommandLine();
        break;
      case ParseStyle.commandLineScript:
        stmt = _parseCommandLineScript();
        break;
    }

    return stmt;
  }

  List<Stmt> _parseBlock({ParseStyle style = ParseStyle.program}) {
    var stmts = <Stmt>[];
    while ((curTok.type != Common.CurlyRight) && (curTok.type != Common.EOF)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([Common.CurlyRight], consume: true);
    return stmts;
  }

  BlockStmt _parseBlockStmt({ParseStyle style = ParseStyle.program}) {
    BlockStmt stmt;
    var stmts = <Stmt>[];
    while ((curTok.type != Common.CurlyRight) && (curTok.type != Common.EOF)) {
      stmts.add(_parseStmt(style: style));
    }
    if (expect([Common.CurlyRight], consume: true)) {
      stmt = BlockStmt(stmts);
    }
    return stmt;
  }

  /// 无初始化的变量声明语句
  VarStmt _parseVarStmt() {
    VarStmt stmt;
    if (!Common.BuildInTypes.contains(curTok.lexeme)) {
      throw HetuErrorUndefined(curTok.lexeme, curTok.line, curTok.column);
    }
    var typename = curTok;
    var varname = peek(1);
    // 之前已经校验过了所以这里直接跳过
    advance(2);
    // 语句一定以分号结尾
    if (expect([Common.Semicolon], consume: true)) {
      stmt = VarStmt(typename, varname, null);
    }
    return stmt;
  }

  /// 有初始化的变量声明语句
  VarStmt _parseVarInitStmt() {
    VarStmt stmt;
    var typename = curTok;
    var varname = peek(1);
    // 之前已经校验过等于号了所以这里直接跳过
    advance(3);
    var initializer = _parseExpr();
    // 语句一定以分号结尾
    if (expect([Common.Semicolon], consume: true)) {
      stmt = VarStmt(typename, varname, initializer);
    }
    return stmt;
  }

  /// 为了避免涉及复杂的左值右值问题，赋值语句在河图中不作为表达式处理
  /// 而是分成直接赋值，取值后复制和取属性后复制
  ExprStmt _parseAssignStmt() {
    ExprStmt stmt;
    AssignExpr expr;
    var name = curTok;
    // 之前已经校验过等于号了所以这里直接跳过
    advance(1);
    var assignTok = curTok;
    advance(1);
    var value = _parseExpr();
    // 语句一定以分号结尾
    if (expect([Common.Semicolon], consume: true)) {
      expr = AssignExpr(name, assignTok, value);
      stmt = ExprStmt(expr);
    }
    return stmt;
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句一定以分号结尾
    expect([Common.Semicolon], consume: true);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    ReturnStmt stmt;
    var keyword = curTok;
    advance(1);
    Expr expr;
    if (curTok.type != Common.Semicolon) {
      expr = _parseExpr();
    }
    if (expect([Common.Semicolon], consume: true)) {
      stmt = ReturnStmt(keyword, expr);
    }
    return stmt;
  }

  IfStmt _parseIfStmt() {
    IfStmt stmt;
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    var condition = _parseExpr();
    expect([Common.RoundRight], consume: true);
    Stmt thenBranch;
    if (curTok.type == Common.CurlyLeft) {
      advance(1);
      thenBranch = _parseBlockStmt(style: ParseStyle.functionDefinition);
    } else {
      thenBranch = _parseStmt(style: ParseStyle.functionDefinition);
    }
    Stmt elseBranch;
    if (curTok.type == Common.Else) {
      advance(1);
      if (curTok.type == Common.CurlyLeft) {
        advance(1);
        elseBranch = _parseBlockStmt(style: ParseStyle.functionDefinition);
      } else {
        elseBranch = _parseStmt(style: ParseStyle.functionDefinition);
      }
    }
    stmt = IfStmt(condition, thenBranch, elseBranch);
    return stmt;
  }

  WhileStmt _parseWhileStmt() {
    WhileStmt stmt;
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    var condition = _parseExpr();
    advance(1);
    Stmt loop;
    if (curTok.type == Common.CurlyLeft) {
      advance(1);
      loop = _parseBlockStmt(style: ParseStyle.functionDefinition);
    } else {
      loop = _parseStmt(style: ParseStyle.functionDefinition);
    }
    stmt = WhileStmt(condition, loop);
    return stmt;
  }

  List<VarStmt> _parseParameters() {
    var result = <VarStmt>[];
    while ((curTok.type != Common.RoundRight) && (curTok.type != Common.EOF)) {
      if ((result.isNotEmpty) && (curTok.type == Common.Comma)) {
        advance(1);
      }
      if (expect([Common.Identifier, Common.Identifier, Common.Comma]) ||
          expect([Common.Identifier, Common.Identifier, Common.RoundRight])) {
        if (Common.ParametersTypes.contains(curTok.lexeme)) {
          //TODO，参数默认值、可选参数、命名参数
          result.add(VarStmt(curTok, peek(1), null));
        } else {
          throw HetuErrorUnexpected(curTok.lexeme, curTok.line, curTok.column);
        }
      } else {
        throw HetuErrorUnexpected(curTok.lexeme, curTok.line, curTok.column);
      }
      advance(2);
    }
    expect([Common.RoundRight], consume: true);
    return result;
  }

  FuncStmt _parseFunctionStmt() {
    FuncStmt stmt;
    if (!Common.FunctionReturnTypes.contains(curTok.lexeme)) {
      throw HetuErrorUndefined(curTok.lexeme, curTok.line, curTok.column);
    }
    var return_type = curTok.lexeme;
    var func_name = peek(1);
    // 之前已经校验过左括号了所以这里直接跳过
    advance(3);
    var params = _parseParameters();
    // 处理函数定义部分的语句块
    expect([Common.CurlyLeft], consume: true);
    var stmts = _parseBlock(style: ParseStyle.functionDefinition);
    stmt = FuncStmt(return_type, func_name, params, stmts);
    return stmt;
  }

  ConstructorStmt _parseConstructorStmt() {
    ConstructorStmt stmt;
    var name = curTok;
    advance(2);
    var params = _parseParameters();
    expect([Common.CurlyLeft], consume: true);
    var stmts = _parseBlock(style: ParseStyle.functionDefinition);
    stmt = ConstructorStmt(_curClassName, name, params, stmts);
    return stmt;
  }

  ClassStmt _parseClassStmt() {
    ClassStmt stmt;
    // 已经判断过了所以直接跳过Class关键字
    advance(1);
    var class_name = curTok;
    VarExpr super_class;
    _curClassName = curTok.lexeme;
    advance(1);
    if (curTok.type == Common.Extends) {
      advance(1);
      super_class = VarExpr(curTok);
      advance(2);
    } else {
      advance(1);
    }

    var variables = <VarStmt>[];
    var methods = <FuncStmt>[];
    while ((curTok.type != Common.CurlyRight) && (curTok.type != Common.EOF)) {
      var stmt = _parseStmt(style: ParseStyle.classDefinition);
      if (stmt is VarStmt) {
        variables.add(stmt);
      } else if (stmt is FuncStmt) {
        methods.add(stmt);
      }
    }
    expect([Common.CurlyRight], consume: true);

    stmt = ClassStmt(class_name, super_class, variables, methods);
    _curClassName = null;
    return stmt;
  }

  ExprStmt _parseCommandLine() {
    var expr = VarExpr(curTok);
    advance(1);
    var params = <Expr>[];
    while (curTok.type != Common.EOF) {
      int index;
      if (curTok.literal is num) {
        index = _context.addLiteral(LNum(curTok.literal));
      } else if (curTok.literal is bool) {
        index = _context.addLiteral(LBool(curTok.literal));
      } else if (curTok.literal is String) {
        index = _context.addLiteral(LString(curTok.literal));
      }
      var expr = LiteralExpr(index, curTok.line, curTok.column);
      params.add(expr);
      advance(1);
    }
    return ExprStmt(CallExpr(expr, params));
  }

  Stmt _parseCommandLineScript() {
    Stmt stmt;
    //todo: 写命令行脚本文件'
    return stmt;
  }
}
