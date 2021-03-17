import 'errors.dart';
import 'expression.dart';
import 'token.dart';
import 'lexicon.dart';
import 'type.dart';
import 'context.dart';
import 'interpreter.dart';

enum ParseStyle {
  /// 程序脚本使用完整的标点符号规则，包括各种括号、逗号和分号
  ///
  /// 库脚本中只能出现变量、类和函数的声明
  library,

  /// 函数语句块中只能出现变量声明、控制语句和函数调用
  function,

  /// 类定义中只能出现变量和函数的声明
  klass,

  /// 外部类
  externalClass,
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
  late List<Token> _tokens;
  late HTContext _context;

  int _curLine = 0;
  int get curLine => _curLine;
  int _curColumn = 0;
  int get curColumn => _curColumn;
  late final String curFileName;

  var _tokPos = 0;
  String? _curClassName;

  static int internalVarIndex = 0;

  static final Map<String, ASTNode> _classStmts = {};

  Parser();

  Future<List<ASTNode>> parse(List<Token> tokens, Interpreter interpreter, HTContext context, String fileName,
      [ParseStyle style = ParseStyle.library]) async {
    _tokens = tokens;
    _context = context;
    curFileName = fileName;

    final statements = <ASTNode>[];
    while (curTok.type != HTLexicon.endOfFile) {
      var stmt = _parseStmt(style: style);
      if (stmt is ImportStmt) {
        await interpreter.import(stmt.key, libName: stmt.namespace);
      }
      statements.add(stmt);
    }
    return statements;
  }

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 如果consume为true，则在符合要求时向前移动Token指针
  ///
  /// 在不符合预期时，如果error为true，则抛出异常
  bool expect(List<String> tokTypes, {bool consume = false, bool? error}) {
    error ??= consume;
    for (var i = 0; i < tokTypes.length; ++i) {
      if (consume) {
        if (curTok.type != tokTypes[i]) {
          if (error) {
            throw HTErrorExpected(tokTypes[i], curTok.lexeme);
          }
          return false;
        }
        advance(1);
      } else {
        if (peek(i).type != tokTypes[i]) {
          return false;
        }
      }
    }
    return true;
  }

  /// 如果当前token符合要求则前进一步，然后返回之前的token，否则抛出异常
  Token match(String tokenType) {
    if (curTok.type == tokenType) {
      return advance(1);
    }

    throw HTErrorExpected(tokenType, curTok.lexeme);
  }

  /// 前进指定距离，返回原先位置的Token
  Token advance(int distance) {
    _tokPos += distance;
    _curLine = curTok.line;
    _curColumn = curTok.column;
    return peek(-distance);
  }

  /// 获得相对于目前位置一定距离的Token，不改变目前位置
  Token peek(int pos) {
    if ((_tokPos + pos) < _tokens.length) {
      return _tokens[_tokPos + pos];
    } else {
      return Token(HTLexicon.endOfFile, curFileName, -1, -1);
    }
  }

  /// 获得当前Token
  Token get curTok => peek(0);
  // {
  // var cur = peek(0);
  // if (cur == env.lexicon.Multiline) {
  //   advance(1);
  //   cur = peek(0);
  // }
  // return cur;
  // }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  ASTNode _parseExpr() => _parseAssignmentExpr();

  HTTypeId _parseTypeId() {
    final type_name = advance(1).lexeme;
    var type_args = <HTTypeId>[];
    if (expect([HTLexicon.angleLeft], consume: true, error: false)) {
      while ((curTok.type != HTLexicon.angleRight) && (curTok.type != HTLexicon.endOfFile)) {
        type_args.add(_parseTypeId());
        expect([HTLexicon.comma], consume: true, error: false);
      }
      expect([HTLexicon.angleRight], consume: true);
    }

    return HTTypeId(type_name, arguments: type_args);
  }

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

      throw HTErrorInvalidLeftValue(op.lexeme);
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  ASTNode _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == HTLexicon.or) {
      final op = advance(1);
      final right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  ASTNode _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok.type == HTLexicon.and) {
      final op = advance(1);
      final right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  ASTNode _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    while (HTLexicon.equalitys.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  ASTNode _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    while (HTLexicon.relationals.contains(curTok.type)) {
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

  /// 前缀 -e, !e，优先级 15，不能合并
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

  /// 后缀 e., e[], e()，优先级 16，取属性不能合并，下标和函数调用可以右合并
  ASTNode _parseUnaryPostfixExpr() {
    var expr = _parsePrimaryExpr();
    //多层函数调用可以合并
    while (true) {
      if (expect([HTLexicon.call], consume: true, error: false)) {
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};

        while ((curTok.type != HTLexicon.roundRight) && (curTok.type != HTLexicon.endOfFile)) {
          final arg = _parseExpr();
          if (expect([HTLexicon.colon], consume: false)) {
            if (arg is SymbolExpr) {
              advance(1);
              var value = _parseExpr();
              namedArgs[arg.id.lexeme] = value;
            } else {
              throw HTErrorUnexpected(
                curTok.lexeme,
              );
            }
          } else {
            positionalArgs.add(arg);
          }

          if (curTok.type != HTLexicon.roundRight) {
            expect([HTLexicon.comma], consume: true);
          }
        }
        expect([HTLexicon.roundRight], consume: true);
        expr = CallExpr(expr, positionalArgs, namedArgs);
      } else if (expect([HTLexicon.memberGet], consume: true, error: false)) {
        final name = match(HTLexicon.identifier);
        expr = MemberGetExpr(expr, name);
      } else if (expect([HTLexicon.subGet], consume: true, error: false)) {
        var index_expr = _parseExpr();
        expect([HTLexicon.squareRight], consume: true);
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
        return NullExpr(curFileName, peek(-1).line, peek(-1).column);
      case HTLexicon.TRUE:
        return BooleanExpr(true, curFileName, peek(-1).line, peek(-1).column);
      case HTLexicon.FALSE:
        return BooleanExpr(false, curFileName, peek(-1).line, peek(-1).column);
      case HTLexicon.integer:
        var index = _context.addConstInt(curTok.literal);
        advance(1);
        return ConstIntExpr(index, curFileName, peek(-1).line, peek(-1).column);
      case HTLexicon.float:
        var index = _context.addConstFloat(curTok.literal);
        advance(1);
        return ConstFloatExpr(index, curFileName, peek(-1).line, peek(-1).column);
      case HTLexicon.string:
        var index = _context.addConstString(curTok.literal);
        advance(1);
        return ConstStringExpr(index, curFileName, peek(-1).line, peek(-1).column);
      case HTLexicon.THIS:
        advance(1);
        return ThisExpr(peek(-1));
      case HTLexicon.identifier:
        advance(1);
        return SymbolExpr(peek(-1));
      case HTLexicon.roundLeft:
        advance(1);
        var innerExpr = _parseExpr();
        expect([HTLexicon.roundRight], consume: true);
        return GroupExpr(innerExpr);
      case HTLexicon.squareLeft:
        final line = curTok.line;
        final column = advance(1).column;
        var list_expr = <ASTNode>[];
        while (curTok.type != HTLexicon.squareRight) {
          list_expr.add(_parseExpr());
          if (curTok.type != HTLexicon.squareRight) {
            expect([HTLexicon.comma], consume: true);
          }
        }
        expect([HTLexicon.squareRight], consume: true);
        return LiteralVectorExpr(curFileName, line, column, list_expr);
      case HTLexicon.curlyLeft:
        final line = curTok.line;
        final column = advance(1).column;
        var map_expr = <ASTNode, ASTNode>{};
        while (curTok.type != HTLexicon.curlyRight) {
          var key_expr = _parseExpr();
          expect([HTLexicon.colon], consume: true);
          var value_expr = _parseExpr();
          expect([HTLexicon.comma], consume: true, error: false);
          map_expr[key_expr] = value_expr;
        }
        expect([HTLexicon.curlyRight], consume: true);
        return LiteralDictExpr(curFileName, line, column, map_expr);

      case HTLexicon.FUN:
        return _parseFuncDeclaration(FunctionType.literal);

      default:
        throw HTErrorUnexpected(curTok.lexeme);
    }
  }

  ASTNode _parseStmt({ParseStyle style = ParseStyle.library}) {
    if (curTok.type == HTLexicon.newLine) advance(1);
    switch (style) {
      case ParseStyle.library:
        final isExtern = expect([HTLexicon.EXTERNAL], consume: true, error: false);
        // import语句
        if (expect([HTLexicon.IMPORT])) {
          return _parseImportStmt();
        } // var变量声明
        if (expect([HTLexicon.VAR])) {
          return _parseVarStmt(isExtern: isExtern, isDynamic: true);
        } // let
        else if (expect([HTLexicon.LET])) {
          return _parseVarStmt(isExtern: isExtern);
        } // const
        else if (expect([HTLexicon.CONST])) {
          return _parseVarStmt(isExtern: isExtern, isImmutable: true);
        } // 类声明
        else if (expect([HTLexicon.CLASS])) {
          return _parseClassDeclStmt(isExtern: isExtern);
        } // 函数声明
        else if (expect([HTLexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.normal, isExtern: isExtern);
        } else {
          throw HTErrorUnexpected(curTok.lexeme);
        }
      case ParseStyle.function:
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
        else if (expect([HTLexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.normal);
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
      case ParseStyle.klass:
        final isExtern = expect([HTLexicon.EXTERNAL], consume: true, error: false);
        final isStatic = expect([HTLexicon.STATIC], consume: true, error: false);
        // var变量声明
        if (expect([HTLexicon.VAR])) {
          return _parseVarStmt(isExtern: isExtern, isStatic: isStatic, isDynamic: true);
        } // let
        else if (expect([HTLexicon.LET])) {
          return _parseVarStmt(isExtern: isExtern, isStatic: isStatic);
        } // const
        else if (expect([HTLexicon.CONST])) {
          if (!isStatic) throw HTErrorConstMustBeStatic(curTok.lexeme);
          return _parseVarStmt(isExtern: isExtern, isStatic: true, isImmutable: true);
        } // 构造函数
        else if (curTok.lexeme == HTLexicon.CONSTRUCT) {
          return _parseFuncDeclaration(FunctionType.constructor, isExtern: isExtern, isStatic: isStatic);
        } // setter函数声明
        else if (curTok.lexeme == HTLexicon.GET) {
          return _parseFuncDeclaration(FunctionType.getter, isExtern: isExtern, isStatic: isStatic);
        } // getter函数声明
        else if (curTok.lexeme == HTLexicon.SET) {
          return _parseFuncDeclaration(FunctionType.setter, isExtern: isExtern, isStatic: isStatic);
        } // 成员函数声明
        else if (expect([HTLexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.method, isExtern: isExtern, isStatic: isStatic);
        } else {
          throw HTErrorUnexpected(curTok.lexeme);
        }
      case ParseStyle.externalClass:
        expect([HTLexicon.EXTERNAL], consume: true, error: false);
        final isStatic = expect([HTLexicon.STATIC], consume: true, error: false);
        // var变量声明
        if (expect([HTLexicon.VAR])) {
          return _parseVarStmt(isExtern: true, isStatic: isStatic, isDynamic: true);
        } // let
        else if (expect([HTLexicon.LET])) {
          return _parseVarStmt(isExtern: true, isStatic: isStatic);
        } // const
        else if (expect([HTLexicon.CONST])) {
          if (!isStatic) throw HTErrorConstMustBeStatic(curTok.lexeme);
          return _parseVarStmt(isExtern: true, isStatic: true, isImmutable: false);
        } // 构造函数
        else if (curTok.lexeme == HTLexicon.CONSTRUCT) {
          return _parseFuncDeclaration(FunctionType.constructor, isExtern: true, isStatic: isStatic);
        } // setter函数声明
        else if (curTok.lexeme == HTLexicon.GET) {
          return _parseFuncDeclaration(FunctionType.getter, isExtern: true, isStatic: isStatic);
        } // getter函数声明
        else if (curTok.lexeme == HTLexicon.SET) {
          return _parseFuncDeclaration(FunctionType.setter, isExtern: true, isStatic: isStatic);
        } // 成员函数声明
        else if (expect([HTLexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.method, isExtern: true, isStatic: isStatic);
        } else {
          throw HTErrorUnexpected(curTok.lexeme);
        }
    }
  }

  List<ASTNode> _parseBlock({ParseStyle style = ParseStyle.library}) {
    var stmts = <ASTNode>[];
    while ((curTok.type != HTLexicon.curlyRight) && (curTok.type != HTLexicon.endOfFile)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HTLexicon.curlyRight], consume: true);
    return stmts;
  }

  BlockStmt _parseBlockStmt({ParseStyle style = ParseStyle.library}) {
    var stmts = <ASTNode>[];
    var line = curTok.line;
    var column = curTok.column;
    while ((curTok.type != HTLexicon.curlyRight) && (curTok.type != HTLexicon.endOfFile)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HTLexicon.curlyRight], consume: true);
    return BlockStmt(stmts, curFileName, line, column);
  }

  ImportStmt _parseImportStmt() {
    // 之前校验过了所以这里直接跳过
    final keyword = advance(1);
    String fileName = match(HTLexicon.string).literal;
    String? spaceName;
    if (expect([HTLexicon.AS], consume: true, error: false)) {
      spaceName = match(HTLexicon.identifier).lexeme;
    }
    var stmt = ImportStmt(keyword, fileName, spaceName);
    expect([HTLexicon.semicolon], consume: true, error: false);
    return stmt;
  }

  /// 变量声明语句
  VarDeclStmt _parseVarStmt(
      {bool isExtern = false, bool isStatic = false, bool isDynamic = false, bool isImmutable = false}) {
    advance(1);
    final var_name = match(HTLexicon.identifier);

    // if (_declarations.containsKey(var_name)) throw HTErrorDefined(var_name.lexeme, fileName, curTok.line, curTok.column);

    var decl_type = HTTypeId.ANY;
    if (expect([HTLexicon.colon], consume: true, error: false)) {
      decl_type = _parseTypeId();
    }

    ASTNode? initializer;
    if (expect([HTLexicon.assign], consume: true, error: false)) {
      initializer = _parseExpr();
    }
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true, error: false);
    var stmt = VarDeclStmt(
      var_name,
      declType: decl_type,
      initializer: initializer,
      isExtern: isExtern,
      isStatic: isStatic,
      isDynamic: isDynamic,
      isImmutable: isImmutable,
    );

    // _declarations[var_name.lexeme] = stmt;

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
    expect([HTLexicon.semicolon], consume: true, error: false);
    var expr = AssignExpr(name, token, value);
    return ExprStmt(expr);
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true, error: false);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    ASTNode? expr;
    if (!expect([HTLexicon.semicolon], consume: true, error: false)) {
      expr = _parseExpr();
    }
    expect([HTLexicon.semicolon], consume: true, error: false);
    return ReturnStmt(keyword, expr);
  }

  IfStmt _parseIfStmt() {
    advance(1);
    expect([HTLexicon.roundLeft], consume: true);
    var condition = _parseExpr();
    expect([HTLexicon.roundRight], consume: true);
    ASTNode? thenBranch;
    if (expect([HTLexicon.curlyLeft], consume: true, error: false)) {
      thenBranch = _parseBlockStmt(style: ParseStyle.function);
    } else {
      thenBranch = _parseStmt(style: ParseStyle.function);
    }
    ASTNode? elseBranch;
    if (expect([HTLexicon.ELSE], consume: true, error: false)) {
      if (expect([HTLexicon.curlyLeft], consume: true, error: false)) {
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
    expect([HTLexicon.roundLeft], consume: true);
    var condition = _parseExpr();
    expect([HTLexicon.roundRight], consume: true);
    ASTNode? loop;
    if (expect([HTLexicon.curlyLeft], consume: true, error: false)) {
      loop = _parseBlockStmt(style: ParseStyle.function);
    } else {
      loop = _parseStmt(style: ParseStyle.function);
    }
    return WhileStmt(condition, loop);
  }

  /// For语句其实会在解析时转换为While语句
  BlockStmt _parseForStmt() {
    var list_stmt = <ASTNode>[];
    expect([HTLexicon.FOR, HTLexicon.roundLeft], consume: true);
    // 递增变量
    final i = '__i${internalVarIndex++}';
    list_stmt.add(VarDeclStmt(TokenIdentifier(i, curFileName, curTok.line, curTok.column),
        declType: HTTypeId.number,
        initializer: ConstIntExpr(_context.addConstInt(0), curFileName, curTok.line, curTok.column)));
    // 指针
    var varname = match(HTLexicon.identifier).lexeme;
    var typeid = HTTypeId.ANY;
    if (expect([HTLexicon.colon], consume: true, error: false)) {
      typeid = _parseTypeId();
    }
    list_stmt.add(VarDeclStmt(TokenIdentifier(varname, curTok.fileName, curTok.line, curTok.column), declType: typeid));
    expect([HTLexicon.IN], consume: true);
    var list_obj = _parseExpr();
    // 条件语句
    var get_length =
        MemberGetExpr(list_obj, TokenIdentifier(HTLexicon.length, curFileName, curTok.line, curTok.column));
    var condition = BinaryExpr(SymbolExpr(TokenIdentifier(i, curFileName, curTok.line, curTok.column)),
        Token(HTLexicon.lesser, curFileName, curTok.line, curTok.column), get_length);
    // 在循环体之前手动插入递增语句和指针语句
    // 按下标取数组元素
    var loop_body = <ASTNode>[];
    // 这里一定要复制一个list_obj的表达式，否则在resolve的时候会因为是相同的对象出错，覆盖掉上面那个表达式的位置
    var sub_get_value =
        SubGetExpr(list_obj.clone(), SymbolExpr(TokenIdentifier(i, curFileName, curTok.line, curTok.column)));
    var assign_stmt = ExprStmt(AssignExpr(TokenIdentifier(varname, curFileName, curTok.line, curTok.column),
        Token(HTLexicon.assign, curFileName, curTok.line, curTok.column), sub_get_value));
    loop_body.add(assign_stmt);
    // 递增下标变量
    var increment_expr = BinaryExpr(
        SymbolExpr(TokenIdentifier(i, curFileName, curTok.line, curTok.column)),
        Token(HTLexicon.add, curFileName, curTok.line, curTok.column),
        ConstIntExpr(_context.addConstInt(1), curFileName, curTok.line, curTok.column));
    var increment_stmt = ExprStmt(AssignExpr(TokenIdentifier(i, curFileName, curTok.line, curTok.column),
        Token(HTLexicon.assign, curFileName, curTok.line, curTok.column), increment_expr));
    loop_body.add(increment_stmt);
    // 循环体
    expect([HTLexicon.roundRight], consume: true);
    if (expect([HTLexicon.curlyLeft], consume: true, error: false)) {
      loop_body.addAll(_parseBlock(style: ParseStyle.function));
    } else {
      loop_body.add(_parseStmt(style: ParseStyle.function));
    }
    list_stmt.add(WhileStmt(condition, BlockStmt(loop_body, curFileName, curTok.line, curTok.column)));
    return BlockStmt(list_stmt, curFileName, curTok.line, curTok.column);
  }

  List<ParamDeclStmt> _parseParameters() {
    var params = <ParamDeclStmt>[];
    var optionalStarted = false;
    var namedStarted = false;
    while ((curTok.type != HTLexicon.roundRight) &&
        (curTok.type != HTLexicon.squareRight) &&
        (curTok.type != HTLexicon.curlyRight) &&
        (curTok.type != HTLexicon.endOfFile)) {
      if (params.isNotEmpty) {
        expect([HTLexicon.comma], consume: true, error: false);
      }
      // 可选参数，根据是否有方括号判断，一旦开始了可选参数，则不再增加参数数量arity要求
      if (!optionalStarted) {
        optionalStarted = expect([HTLexicon.squareLeft], consume: true, error: false);
        if (!optionalStarted && !namedStarted) {
          //检查命名参数，根据是否有花括号判断
          namedStarted = expect([HTLexicon.curlyLeft], consume: true, error: false);
        }
      }

      var isVariadic = false;
      if (!namedStarted) {
        isVariadic = expect([HTLexicon.varargs], consume: true, error: false);
      }

      var name = match(HTLexicon.identifier);
      var typeid = HTTypeId.ANY;
      if (expect([HTLexicon.colon], consume: true, error: false)) {
        typeid = _parseTypeId();
      }

      ASTNode? initializer;
      if (optionalStarted || namedStarted) {
        //参数默认值
        if (expect([HTLexicon.assign], consume: true, error: false)) {
          initializer = _parseExpr();
        }
      }

      params.add(ParamDeclStmt(name,
          declType: typeid,
          initializer: initializer,
          isVariadic: isVariadic,
          isOptional: optionalStarted,
          isNamed: namedStarted));

      if (isVariadic) {
        break;
      }
    }

    if (optionalStarted) {
      expect([HTLexicon.squareRight], consume: true);
    } else if (namedStarted) {
      expect([HTLexicon.curlyRight], consume: true);
    }

    expect([HTLexicon.roundRight], consume: true);
    return params;
  }

  FuncDeclaration _parseFuncDeclaration(FunctionType functype, {bool isExtern = false, bool isStatic = false}) {
    final keyword = advance(1);
    Token? func_name;
    var typeParams = <String>[];
    if (curTok.type == HTLexicon.identifier) {
      func_name = advance(1);

      if (expect([HTLexicon.angleLeft], consume: true, error: false)) {
        while ((curTok.type != HTLexicon.angleRight) && (curTok.type != HTLexicon.endOfFile)) {
          if (typeParams.isNotEmpty) {
            expect([HTLexicon.comma], consume: true);
          }
          typeParams.add(advance(1).lexeme);
        }
        expect([HTLexicon.angleRight], consume: true);
      }
    }

    // if (functype == FuncStmtType.normal) {
    //   if (_declarations.containsKey(func_name)) throw HTErrorDefined(func_name, fileName, curTok.line, curTok.column);
    // }

    var arity = 0;
    var isVariadic = false;
    var params = <ParamDeclStmt>[];

    if (functype != FunctionType.getter) {
      // 之前还没有校验过左括号
      if (expect([HTLexicon.roundLeft], consume: true, error: false)) {
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
        if ((functype == FunctionType.setter) && (arity != 1)) {
          throw HTErrorSetter();
        }
      }
    }

    var return_type = HTTypeId.ANY;
    if ((functype != FunctionType.constructor) && (expect([HTLexicon.colon], consume: true, error: false))) {
      return_type = _parseTypeId();
    }

    var body = <ASTNode>[];
    if (expect([HTLexicon.curlyLeft], consume: true, error: false)) {
      // 处理函数定义部分的语句块
      body = _parseBlock(style: ParseStyle.function);
    }
    expect([HTLexicon.semicolon], consume: true, error: false);

    var stmt = FuncDeclaration(return_type, params, curFileName, keyword.line, keyword.column,
        id: func_name,
        typeParams: typeParams,
        arity: arity,
        definition: body,
        className: _curClassName,
        isExtern: isExtern,
        isStatic: isStatic,
        isVariadic: isVariadic,
        funcType: functype);

    // _declarations[stmt.id] = stmt;

    return stmt;
  }

  ClassDeclStmt _parseClassDeclStmt({bool isExtern = false}) {
    // 已经判断过了所以直接跳过Class关键字
    advance(1);

    final class_name = advance(1);

    if (_classStmts.containsKey(class_name.lexeme)) throw HTErrorDefined_Parser(class_name.lexeme);

    // TODO: 嵌套类?
    _curClassName = class_name.lexeme;

    // generic type参数
    var typeParams = <String>[];
    if (expect([HTLexicon.angleLeft], consume: true, error: false)) {
      while ((curTok.type != HTLexicon.angleRight) && (curTok.type != HTLexicon.endOfFile)) {
        if (typeParams.isNotEmpty) {
          expect([HTLexicon.comma], consume: true);
        }
        typeParams.add(advance(1).lexeme);
      }
      expect([HTLexicon.angleRight], consume: true);
    }

    // 继承父类
    SymbolExpr? super_class;
    ClassDeclStmt? super_class_decl;
    HTTypeId? super_class_type_args;
    if (expect([HTLexicon.EXTENDS], consume: true, error: false)) {
      if (curTok.lexeme == class_name.lexeme) {
        throw HTErrorUnexpected(class_name.lexeme);
      } else if (_classStmts[curTok.lexeme] == null) {
        throw HTErrorNotClass(curTok.lexeme);
      }

      super_class = SymbolExpr(curTok);
      super_class_decl = _classStmts[super_class.id.lexeme] as ClassDeclStmt?;
      advance(1);
      if (expect([HTLexicon.angleLeft], consume: true, error: false)) {
        // 类型传入参数
        super_class_type_args = _parseTypeId();
        expect([HTLexicon.angleRight], consume: true);
      }
    }

    // 类的定义体
    var variables = <VarDeclStmt>[];
    var methods = <FuncDeclaration>[];
    if (expect([HTLexicon.curlyLeft], consume: true, error: false)) {
      while ((curTok.type != HTLexicon.curlyRight) && (curTok.type != HTLexicon.endOfFile)) {
        var member = _parseStmt(style: isExtern ? ParseStyle.externalClass : ParseStyle.klass);
        if (member is VarDeclStmt) {
          variables.add(member);
        } else if (member is FuncDeclaration) {
          methods.add(member);
        }
      }
      expect([HTLexicon.curlyRight], consume: true);
    } else {
      expect([HTLexicon.semicolon], consume: true, error: false);
    }

    final stmt = ClassDeclStmt(class_name, variables, methods,
        typeParams: typeParams,
        superClass: super_class,
        superClassDeclStmt: super_class_decl,
        superClassTypeArgs: super_class_type_args,
        isExtern: isExtern);

    _classStmts[stmt.id.lexeme] = stmt;

    _curClassName = null;
    return stmt;
  }
}
