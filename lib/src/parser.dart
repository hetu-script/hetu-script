import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'token.dart';
import 'constants.dart';

enum ParserContext {
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
  String _curClassName;

  static const List<String> _patternDecl = [Constants.Identifier, Constants.Identifier, Constants.Semicolon];
  static const List<String> _patternInit = [Constants.Identifier, Constants.Identifier, Constants.Assign];
  static const List<String> _patternFuncDecl = [Constants.Identifier, Constants.Identifier, Constants.RoundLeft];
  static const List<String> _patternAssign = [Constants.Identifier, Constants.Assign];
  static const List<String> _patternIf = [Constants.If, Constants.RoundLeft];
  static const List<String> _patternWhile = [Constants.While, Constants.RoundLeft];

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
    ParserContext context = ParserContext.program,
  }) {
    _tokens.clear();
    _tokens.addAll(tokens);
    _position = 0;

    var statements = <Stmt>[];
    while (curTok.type != Constants.EOF) {
      statements.add(_parseStmt(context: context));
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

    if (Constants.Assignment.contains(curTok.type)) {
      Token op = curTok;
      advance(1);
      Expr value = _parseAssignmentExpr();

      if (expr is VarExpr) {
        Token name = expr.name;
        return AssignExpr(name, op, value);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value);
      }

      throw HetuError('(Parser) Invalid assignment target. [${op.lineNumber}, ${op.colNumber}].');
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  Expr _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == Constants.Or) {
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
    while (curTok.type == Constants.And) {
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
    while (Constants.Equality.contains(curTok.type)) {
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
    while (Constants.Relational.contains(curTok.type)) {
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
    while (Constants.Additive.contains(curTok.type)) {
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
    while (Constants.Multiplicative.contains(curTok.type)) {
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
    if (Constants.UnaryPrefix.contains(curTok.type)) {
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
      if (curTok.text == Constants.RoundLeft) {
        advance(1);
        var params = <Expr>[];
        while ((curTok.type != Constants.RoundRight) && (curTok.type != Constants.EOF)) {
          params.add(_parseExpr());
          if (curTok.type == Constants.Comma) {
            advance(1);
          }
        }
        expr = CallExpr(expr, params);
        expect([Constants.RoundRight], consume: true);
      } else if (curTok.text == Constants.Dot) {
        advance(1);
        if (curTok.type == Constants.Identifier) {
          Token name = curTok;
          expr = MemberGetExpr(expr, name);
          advance(1);
        } else {
          throw HetuError(
              '(Parser) Expected member identifier, get [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
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
    if (Constants.Literals.contains(curTok.type)) {
      expr = LiteralExpr(curTok);
      advance(1);
    } else if (curTok.type == Constants.This) {
      expr = ThisExpr(curTok);
      advance(1);
    } else if (curTok.type == Constants.Identifier) {
      expr = VarExpr(curTok);
      advance(1);
    } else if (curTok.type == Constants.RoundLeft) {
      advance(1);
      var innerExpr = _parseExpr();
      expect([Constants.RoundRight], consume: true);
      expr = GroupExpr(innerExpr);
    } else {
      throw HetuError('(Parser) Unknown identifier [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
    }
    return expr;
  }

  Stmt _parseStmt({ParserContext context = ParserContext.program}) {
    Stmt stmt;

    switch (context) {
      case ParserContext.program:
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
          else if (expect([Constants.Class, Constants.Identifier, Constants.CurlyLeft]) ||
              expect([
                Constants.Class,
                Constants.Identifier,
                Constants.Extends,
                Constants.Identifier,
                Constants.CurlyLeft
              ])) {
            stmt = _parseClassStmt();
          } else {
            throw HetuError(
                '(Parser) Unknown statement identifier [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
          }
        }
        break;
      case ParserContext.functionDefinition:
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
          else if (curTok.type == Constants.Break) {
            stmt = BreakStmt();
          } // 如果是返回语句
          else if (curTok.type == Constants.Return) {
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
      case ParserContext.classDefinition:
        {
          // 如果是变量声明
          if (expect(_patternDecl)) {
            stmt = _parseVarStmt();
          } // 如果是带初始化语句的变量声明
          else if (expect(_patternInit)) {
            stmt = _parseVarInitStmt();
          } // 如果是构造函数
          // TODO：命名的构造函数
          else if ((curTok.text == _curClassName) && (peek(1).type == Constants.RoundLeft)) {
            stmt = _parseConstructorStmt();
            // 如果是函数声明
          } else if (expect(_patternFuncDecl)) {
            stmt = _parseFunctionStmt();
          } else {
            throw HetuError(
                '(Parser) Unknown class field definition identifier [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
          }
        }
        break;
      case ParserContext.commandLine:
        stmt = _parseCommandLine();
        break;
      case ParserContext.commandLineScript:
        stmt = _parseCommandLineScript();
        break;
    }

    return stmt;
  }

  List<Stmt> _parseBlock({ParserContext context = ParserContext.program}) {
    var stmts = <Stmt>[];
    while ((curTok.type != Constants.CurlyRight) && (curTok.type != Constants.EOF)) {
      stmts.add(_parseStmt(context: context));
    }
    expect([Constants.CurlyRight], consume: true);
    return stmts;
  }

  BlockStmt _parseBlockStmt({ParserContext context = ParserContext.program}) {
    BlockStmt stmt;
    var stmts = <Stmt>[];
    while ((curTok.type != Constants.CurlyRight) && (curTok.type != Constants.EOF)) {
      stmts.add(_parseStmt(context: context));
    }
    if (expect([Constants.CurlyRight], consume: true)) {
      stmt = BlockStmt(stmts);
    }
    return stmt;
  }

  /// 无初始化的变量声明语句
  VarStmt _parseVarStmt() {
    VarStmt stmt;
    if (!Constants.BuildInTypes.contains(curTok.text)) {
      throw HetuError('(Parser) Undefined typename [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
    }
    var typename = curTok;
    var varname = peek(1);
    // 之前已经校验过了所以这里直接跳过
    advance(2);
    // 语句一定以分号结尾
    if (expect([Constants.Semicolon], consume: true)) {
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
    if (expect([Constants.Semicolon], consume: true)) {
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
    if (expect([Constants.Semicolon], consume: true)) {
      expr = AssignExpr(name, assignTok, value);
      stmt = ExprStmt(expr);
    }
    return stmt;
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句一定以分号结尾
    expect([Constants.Semicolon], consume: true);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    ReturnStmt stmt;
    var keyword = curTok;
    advance(1);
    Expr expr;
    if (curTok.type != Constants.Semicolon) {
      expr = _parseExpr();
    }
    if (expect([Constants.Semicolon], consume: true)) {
      stmt = ReturnStmt(keyword, expr);
    }
    return stmt;
  }

  IfStmt _parseIfStmt() {
    IfStmt stmt;
    // 之前已经校验过括号了所以这里直接跳过
    advance(2);
    var condition = _parseExpr();
    expect([Constants.RoundRight], consume: true);
    Stmt thenBranch;
    if (curTok.type == Constants.CurlyLeft) {
      advance(1);
      thenBranch = _parseBlockStmt(context: ParserContext.functionDefinition);
    } else {
      thenBranch = _parseStmt(context: ParserContext.functionDefinition);
    }
    Stmt elseBranch;
    if (curTok.type == Constants.Else) {
      advance(1);
      if (curTok.type == Constants.CurlyLeft) {
        advance(1);
        elseBranch = _parseBlockStmt(context: ParserContext.functionDefinition);
      } else {
        elseBranch = _parseStmt(context: ParserContext.functionDefinition);
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
    if (curTok.type == Constants.CurlyLeft) {
      advance(1);
      loop = _parseBlockStmt(context: ParserContext.functionDefinition);
    } else {
      loop = _parseStmt(context: ParserContext.functionDefinition);
    }
    stmt = WhileStmt(condition, loop);
    return stmt;
  }

  List<VarStmt> _parseParameters() {
    var result = <VarStmt>[];
    while ((curTok.type != Constants.RoundRight) && (curTok.type != Constants.EOF)) {
      if ((result.isNotEmpty) && (curTok.type == Constants.Comma)) {
        advance(1);
      }
      if (expect([Constants.Identifier, Constants.Identifier, Constants.Comma]) ||
          expect([Constants.Identifier, Constants.Identifier, Constants.RoundRight])) {
        if (Constants.ParametersTypes.contains(curTok.text)) {
          //TODO，参数默认值、可选参数、命名参数
          result.add(VarStmt(curTok, peek(1), null));
        } else {
          throw HetuError(
              '(Parser) Unsupported parameter type [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
        }
      } else {
        throw HetuError(
            'Parser error: Expected parameter variable statement, get [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
      }
      advance(2);
    }
    expect([Constants.RoundRight], consume: true);
    return result;
  }

  FuncStmt _parseFunctionStmt() {
    FuncStmt stmt;
    if (!Constants.FunctionReturnTypes.contains(curTok.text)) {
      throw HetuError('(Parser) Undefined typename [${curTok.text}]. [${curTok.lineNumber}, ${curTok.colNumber}].');
    }
    var return_type = curTok.text;
    var func_name = peek(1);
    // 之前已经校验过左括号了所以这里直接跳过
    advance(3);
    var params = _parseParameters();
    // 处理函数定义部分的语句块
    expect([Constants.CurlyLeft], consume: true);
    var stmts = _parseBlock(context: ParserContext.functionDefinition);
    stmt = FuncStmt(return_type, func_name, params, stmts);
    return stmt;
  }

  ConstructorStmt _parseConstructorStmt() {
    ConstructorStmt stmt;
    var name = curTok;
    advance(2);
    var params = _parseParameters();
    expect([Constants.CurlyLeft], consume: true);
    var stmts = _parseBlock(context: ParserContext.functionDefinition);
    stmt = ConstructorStmt(_curClassName, name, params, stmts);
    return stmt;
  }

  ClassStmt _parseClassStmt() {
    ClassStmt stmt;
    // 已经判断过了所以直接跳过Class关键字
    advance(1);
    var class_name = curTok;
    VarExpr super_class;
    _curClassName = curTok.text;
    advance(1);
    if (curTok.type == Constants.Extends) {
      advance(1);
      super_class = VarExpr(curTok);
      advance(2);
    } else {
      advance(1);
    }

    var variables = <VarStmt>[];
    var methods = <FuncStmt>[];
    while ((curTok.type != Constants.CurlyRight) && (curTok.type != Constants.EOF)) {
      var stmt = _parseStmt(context: ParserContext.classDefinition);
      if (stmt is VarStmt) {
        variables.add(stmt);
      } else if (stmt is FuncStmt) {
        methods.add(stmt);
      }
    }
    expect([Constants.CurlyRight], consume: true);

    stmt = ClassStmt(class_name, super_class, variables, methods);
    _curClassName = null;
    return stmt;
  }

  ExprStmt _parseCommandLine() {
    var expr = VarExpr(curTok);
    advance(1);
    var params = <Expr>[];
    while (curTok.type != Constants.EOF) {
      params.add(LiteralExpr(curTok));
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
