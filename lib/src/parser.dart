import 'errors.dart';
import 'expression.dart';
import 'token.dart';
import 'lexicon.dart';
import 'type.dart';
import 'interpreter.dart';
import 'context.dart';

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
  final Interpreter interpreter;
  late List<Token> _tokens;
  late HT_Context _context;
  late String _curFileName;

  var _tokPos = 0;
  String? _curClassName;

  static int internalVarIndex = 0;

  static final Map<String, ASTNode> _classStmts = {};

  Parser(this.interpreter);

  List<ASTNode> parse(List<Token> tokens, HT_Context context, String fileName,
      [ParseStyle style = ParseStyle.library]) {
    _tokens = tokens;
    _context = context;
    _curFileName = fileName;

    final statements = <ASTNode>[];
    while (curTok.type != HT_Lexicon.endOfFile) {
      var stmt = _parseStmt(style: style);
      if (stmt is ImportStmt) {
        final save = interpreter.curFileName;
        final file_path = interpreter.workingDirectory + '/' + stmt.path;
        interpreter.evalfSync(file_path, libName: stmt.nameSpace);
        interpreter.curFileName = save;
      } else {
        statements.add(stmt);
      }
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
            throw HT_Error_Expected(tokTypes[i], curTok.lexeme);
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

    throw HT_Error_Expected(tokenType, curTok.lexeme);
  }

  /// 前进指定距离，返回原先位置的Token
  Token advance(int distance) {
    _tokPos += distance;
    interpreter.curLine = curTok.line;
    interpreter.curColumn = curTok.column;
    return peek(-distance);
  }

  /// 获得相对于目前位置一定距离的Token，不改变目前位置
  Token peek(int pos) {
    if ((_tokPos + pos) < _tokens.length) {
      return _tokens[_tokPos + pos];
    } else {
      return Token(HT_Lexicon.endOfFile, _curFileName, -1, -1);
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

  HT_TypeId _parseTypeId() {
    final type_name = advance(1).lexeme;
    var type_args = <HT_TypeId>[];
    if (expect([HT_Lexicon.angleLeft], consume: true, error: false)) {
      while ((curTok.type != HT_Lexicon.angleRight) && (curTok.type != HT_Lexicon.endOfFile)) {
        type_args.add(_parseTypeId());
        expect([HT_Lexicon.comma], consume: true, error: false);
      }
      expect([HT_Lexicon.angleRight], consume: true);
    }

    return HT_TypeId(type_name, arguments: type_args);
  }

  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  ASTNode _parseAssignmentExpr() {
    final expr = _parseLogicalOrExpr();

    if (HT_Lexicon.assignments.contains(curTok.type)) {
      final op = advance(1);
      final value = _parseAssignmentExpr();

      if (expr is SymbolExpr) {
        return AssignExpr(expr.id, op, value);
      } else if (expr is MemberGetExpr) {
        return MemberSetExpr(expr.collection, expr.key, value);
      } else if (expr is SubGetExpr) {
        return SubSetExpr(expr.collection, expr.key, value);
      }

      throw HT_Error_InvalidLeftValue(op.lexeme);
    }

    return expr;
  }

  /// 逻辑或 or ，优先级 5，左合并
  ASTNode _parseLogicalOrExpr() {
    var expr = _parseLogicalAndExpr();
    while (curTok.type == HT_Lexicon.or) {
      final op = advance(1);
      final right = _parseLogicalAndExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑和 and ，优先级 6，左合并
  ASTNode _parseLogicalAndExpr() {
    var expr = _parseEqualityExpr();
    while (curTok.type == HT_Lexicon.and) {
      final op = advance(1);
      final right = _parseEqualityExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  ASTNode _parseEqualityExpr() {
    var expr = _parseRelationalExpr();
    while (HT_Lexicon.equalitys.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseRelationalExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  ASTNode _parseRelationalExpr() {
    var expr = _parseAdditiveExpr();
    while (HT_Lexicon.relationals.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseAdditiveExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 加法 +, -，优先级 13，左合并
  ASTNode _parseAdditiveExpr() {
    var expr = _parseMultiplicativeExpr();
    while (HT_Lexicon.additives.contains(curTok.type)) {
      final op = advance(1);
      final right = _parseMultiplicativeExpr();
      expr = BinaryExpr(expr, op, right);
    }
    return expr;
  }

  /// 乘法 *, /, %，优先级 14，左合并
  ASTNode _parseMultiplicativeExpr() {
    var expr = _parseUnaryPrefixExpr();
    while (HT_Lexicon.multiplicatives.contains(curTok.type)) {
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
    if (HT_Lexicon.unaryPrefixs.contains(curTok.type)) {
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
      if (expect([HT_Lexicon.call], consume: true, error: false)) {
        var positionalArgs = <ASTNode>[];
        var namedArgs = <String, ASTNode>{};

        while ((curTok.type != HT_Lexicon.roundRight) && (curTok.type != HT_Lexicon.endOfFile)) {
          final arg = _parseExpr();
          if (expect([HT_Lexicon.colon], consume: false)) {
            if (arg is SymbolExpr) {
              advance(1);
              var value = _parseExpr();
              namedArgs[arg.id.lexeme] = value;
            } else {
              throw HT_Error_Unexpected(
                curTok.lexeme,
              );
            }
          } else {
            positionalArgs.add(arg);
          }

          if (curTok.type != HT_Lexicon.roundRight) {
            expect([HT_Lexicon.comma], consume: true);
          }
        }
        expect([HT_Lexicon.roundRight], consume: true);
        expr = CallExpr(expr, positionalArgs, namedArgs);
      } else if (expect([HT_Lexicon.memberGet], consume: true, error: false)) {
        final name = match(HT_Lexicon.identifier);
        expr = MemberGetExpr(expr, name);
      } else if (expect([HT_Lexicon.subGet], consume: true, error: false)) {
        var index_expr = _parseExpr();
        expect([HT_Lexicon.squareRight], consume: true);
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
      case HT_Lexicon.NULL:
        advance(1);
        return NullExpr(_curFileName, peek(-1).line, peek(-1).column);
      case HT_Lexicon.TRUE:
        return BooleanExpr(true, _curFileName, peek(-1).line, peek(-1).column);
      case HT_Lexicon.FALSE:
        return BooleanExpr(false, _curFileName, peek(-1).line, peek(-1).column);
      case HT_Lexicon.integer:
        var index = _context.addConstInt(curTok.literal);
        advance(1);
        return ConstIntExpr(index, _curFileName, peek(-1).line, peek(-1).column);
      case HT_Lexicon.float:
        var index = _context.addConstFloat(curTok.literal);
        advance(1);
        return ConstFloatExpr(index, _curFileName, peek(-1).line, peek(-1).column);
      case HT_Lexicon.string:
        var index = _context.addConstString(curTok.literal);
        advance(1);
        return ConstStringExpr(index, _curFileName, peek(-1).line, peek(-1).column);
      case HT_Lexicon.THIS:
        advance(1);
        return ThisExpr(peek(-1));
      case HT_Lexicon.identifier:
        advance(1);
        return SymbolExpr(peek(-1));
      case HT_Lexicon.roundLeft:
        advance(1);
        var innerExpr = _parseExpr();
        expect([HT_Lexicon.roundRight], consume: true);
        return GroupExpr(innerExpr);
      case HT_Lexicon.squareLeft:
        final line = curTok.line;
        final column = advance(1).column;
        var list_expr = <ASTNode>[];
        while (curTok.type != HT_Lexicon.squareRight) {
          list_expr.add(_parseExpr());
          if (curTok.type != HT_Lexicon.squareRight) {
            expect([HT_Lexicon.comma], consume: true);
          }
        }
        expect([HT_Lexicon.squareRight], consume: true);
        return LiteralVectorExpr(_curFileName, line, column, list_expr);
      case HT_Lexicon.curlyLeft:
        final line = curTok.line;
        final column = advance(1).column;
        var map_expr = <ASTNode, ASTNode>{};
        while (curTok.type != HT_Lexicon.curlyRight) {
          var key_expr = _parseExpr();
          expect([HT_Lexicon.colon], consume: true);
          var value_expr = _parseExpr();
          expect([HT_Lexicon.comma], consume: true, error: false);
          map_expr[key_expr] = value_expr;
        }
        expect([HT_Lexicon.curlyRight], consume: true);
        return LiteralDictExpr(_curFileName, line, column, map_expr);

      case HT_Lexicon.FUN:
        return _parseFuncDeclaration(FunctionType.literal);

      default:
        throw HT_Error_Unexpected(curTok.lexeme);
    }
  }

  ASTNode _parseStmt({ParseStyle style = ParseStyle.library}) {
    if (curTok.type == HT_Lexicon.newLine) advance(1);
    switch (style) {
      case ParseStyle.library:
        final isExtern = expect([HT_Lexicon.EXTERNAL], consume: true, error: false);
        // import语句
        if (expect([HT_Lexicon.IMPORT])) {
          return _parseImportStmt();
        } // var变量声明
        if (expect([HT_Lexicon.VAR])) {
          return _parseVarStmt(isExtern: isExtern, isDynamic: true);
        } // let
        else if (expect([HT_Lexicon.LET])) {
          return _parseVarStmt(isExtern: isExtern);
        } // const
        else if (expect([HT_Lexicon.CONST])) {
          return _parseVarStmt(isExtern: isExtern, isImmutable: true);
        } // 类声明
        else if (expect([HT_Lexicon.CLASS])) {
          return _parseClassDeclStmt(isExtern: isExtern);
        } // 函数声明
        else if (expect([HT_Lexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.normal, isExtern: isExtern);
        } else {
          throw HT_Error_Unexpected(curTok.lexeme);
        }
      case ParseStyle.function:
        // 函数块中不能出现extern或者static关键字的声明
        // var变量声明
        if (expect([HT_Lexicon.VAR])) {
          return _parseVarStmt(isDynamic: true);
        } // let
        else if (expect([HT_Lexicon.LET])) {
          return _parseVarStmt();
        } // const
        else if (expect([HT_Lexicon.CONST])) {
          return _parseVarStmt(isImmutable: true);
        } // 函数声明
        else if (expect([HT_Lexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.normal);
        } // 赋值语句
        else if (expect([HT_Lexicon.identifier, HT_Lexicon.assign])) {
          return _parseAssignStmt();
        } //If语句
        else if (expect([HT_Lexicon.IF])) {
          return _parseIfStmt();
        } // While语句
        else if (expect([HT_Lexicon.WHILE])) {
          return _parseWhileStmt();
        } // For语句
        else if (expect([HT_Lexicon.FOR])) {
          return _parseForStmt();
        } // 跳出语句
        else if (expect([HT_Lexicon.BREAK])) {
          return BreakStmt(advance(1));
        } // 继续语句
        else if (expect([HT_Lexicon.CONTINUE])) {
          return ContinueStmt(advance(1));
        } // 返回语句
        else if (curTok.type == HT_Lexicon.RETURN) {
          return _parseReturnStmt();
        }
        // 表达式
        else {
          return _parseExprStmt();
        }
      case ParseStyle.klass:
        final isExtern = expect([HT_Lexicon.EXTERNAL], consume: true, error: false);
        final isStatic = expect([HT_Lexicon.STATIC], consume: true, error: false);
        // var变量声明
        if (expect([HT_Lexicon.VAR])) {
          return _parseVarStmt(isExtern: isExtern, isStatic: isStatic, isDynamic: true);
        } // let
        else if (expect([HT_Lexicon.LET])) {
          return _parseVarStmt(isExtern: isExtern, isStatic: isStatic);
        } // const
        else if (expect([HT_Lexicon.CONST])) {
          if (!isStatic) throw HT_Error_ConstMustBeStatic(curTok.lexeme);
          return _parseVarStmt(isExtern: isExtern, isStatic: true, isImmutable: true);
        } // 构造函数
        else if (curTok.lexeme == HT_Lexicon.CONSTRUCT) {
          return _parseFuncDeclaration(FunctionType.constructor, isExtern: isExtern, isStatic: isStatic);
        } // setter函数声明
        else if (curTok.lexeme == HT_Lexicon.GET) {
          return _parseFuncDeclaration(FunctionType.getter, isExtern: isExtern, isStatic: isStatic);
        } // getter函数声明
        else if (curTok.lexeme == HT_Lexicon.SET) {
          return _parseFuncDeclaration(FunctionType.setter, isExtern: isExtern, isStatic: isStatic);
        } // 成员函数声明
        else if (expect([HT_Lexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.method, isExtern: isExtern, isStatic: isStatic);
        } else {
          throw HT_Error_Unexpected(curTok.lexeme);
        }
      case ParseStyle.externalClass:
        expect([HT_Lexicon.EXTERNAL], consume: true, error: false);
        final isStatic = expect([HT_Lexicon.STATIC], consume: true, error: false);
        // var变量声明
        if (expect([HT_Lexicon.VAR])) {
          return _parseVarStmt(isExtern: true, isStatic: isStatic, isDynamic: true);
        } // let
        else if (expect([HT_Lexicon.LET])) {
          return _parseVarStmt(isExtern: true, isStatic: isStatic);
        } // const
        else if (expect([HT_Lexicon.CONST])) {
          if (!isStatic) throw HT_Error_ConstMustBeStatic(curTok.lexeme);
          return _parseVarStmt(isExtern: true, isStatic: true, isImmutable: false);
        } // 构造函数
        else if (curTok.lexeme == HT_Lexicon.CONSTRUCT) {
          return _parseFuncDeclaration(FunctionType.constructor, isExtern: true, isStatic: isStatic);
        } // setter函数声明
        else if (curTok.lexeme == HT_Lexicon.GET) {
          return _parseFuncDeclaration(FunctionType.getter, isExtern: true, isStatic: isStatic);
        } // getter函数声明
        else if (curTok.lexeme == HT_Lexicon.SET) {
          return _parseFuncDeclaration(FunctionType.setter, isExtern: true, isStatic: isStatic);
        } // 成员函数声明
        else if (expect([HT_Lexicon.FUN])) {
          return _parseFuncDeclaration(FunctionType.method, isExtern: true, isStatic: isStatic);
        } else {
          throw HT_Error_Unexpected(curTok.lexeme);
        }
    }
  }

  List<ASTNode> _parseBlock({ParseStyle style = ParseStyle.library}) {
    var stmts = <ASTNode>[];
    while ((curTok.type != HT_Lexicon.curlyRight) && (curTok.type != HT_Lexicon.endOfFile)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HT_Lexicon.curlyRight], consume: true);
    return stmts;
  }

  BlockStmt _parseBlockStmt({ParseStyle style = ParseStyle.library}) {
    var stmts = <ASTNode>[];
    var line = curTok.line;
    var column = curTok.column;
    while ((curTok.type != HT_Lexicon.curlyRight) && (curTok.type != HT_Lexicon.endOfFile)) {
      stmts.add(_parseStmt(style: style));
    }
    expect([HT_Lexicon.curlyRight], consume: true);
    return BlockStmt(stmts, _curFileName, line, column);
  }

  ImportStmt _parseImportStmt() {
    // 之前校验过了所以这里直接跳过
    final keyword = advance(1);
    String fileName = match(HT_Lexicon.string).literal;
    String? spaceName;
    if (expect([HT_Lexicon.AS], consume: true, error: false)) {
      spaceName = match(HT_Lexicon.identifier).lexeme;
    }
    var stmt = ImportStmt(keyword, fileName, spaceName);
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    return stmt;
  }

  /// 变量声明语句
  VarDeclStmt _parseVarStmt(
      {bool isExtern = false, bool isStatic = false, bool isDynamic = false, bool isImmutable = false}) {
    advance(1);
    final var_name = match(HT_Lexicon.identifier);

    // if (_declarations.containsKey(var_name)) throw HT_Error_Defined(var_name.lexeme, fileName, curTok.line, curTok.column);

    var decl_type = HT_TypeId.ANY;
    if (expect([HT_Lexicon.colon], consume: true, error: false)) {
      decl_type = _parseTypeId();
    }

    ASTNode? initializer;
    if (expect([HT_Lexicon.assign], consume: true, error: false)) {
      initializer = _parseExpr();
    }
    // 语句结尾
    expect([HT_Lexicon.semicolon], consume: true, error: false);
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
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    var expr = AssignExpr(name, token, value);
    return ExprStmt(expr);
  }

  ExprStmt _parseExprStmt() {
    var stmt = ExprStmt(_parseExpr());
    // 语句结尾
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    return stmt;
  }

  ReturnStmt _parseReturnStmt() {
    var keyword = advance(1);
    ASTNode? expr;
    if (!expect([HT_Lexicon.semicolon], consume: true, error: false)) {
      expr = _parseExpr();
    }
    expect([HT_Lexicon.semicolon], consume: true, error: false);
    return ReturnStmt(keyword, expr);
  }

  IfStmt _parseIfStmt() {
    advance(1);
    expect([HT_Lexicon.roundLeft], consume: true);
    var condition = _parseExpr();
    expect([HT_Lexicon.roundRight], consume: true);
    ASTNode? thenBranch;
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      thenBranch = _parseBlockStmt(style: ParseStyle.function);
    } else {
      thenBranch = _parseStmt(style: ParseStyle.function);
    }
    ASTNode? elseBranch;
    if (expect([HT_Lexicon.ELSE], consume: true, error: false)) {
      if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
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
    expect([HT_Lexicon.roundLeft], consume: true);
    var condition = _parseExpr();
    expect([HT_Lexicon.roundRight], consume: true);
    ASTNode? loop;
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      loop = _parseBlockStmt(style: ParseStyle.function);
    } else {
      loop = _parseStmt(style: ParseStyle.function);
    }
    return WhileStmt(condition, loop);
  }

  /// For语句其实会在解析时转换为While语句
  BlockStmt _parseForStmt() {
    var list_stmt = <ASTNode>[];
    expect([HT_Lexicon.FOR, HT_Lexicon.roundLeft], consume: true);
    // 递增变量
    final i = '__i${internalVarIndex++}';
    list_stmt.add(VarDeclStmt(TokenIdentifier(i, _curFileName, curTok.line, curTok.column),
        declType: HT_TypeId.number,
        initializer: ConstIntExpr(_context.addConstInt(0), _curFileName, curTok.line, curTok.column)));
    // 指针
    var varname = match(HT_Lexicon.identifier).lexeme;
    var typeid = HT_TypeId.ANY;
    if (expect([HT_Lexicon.colon], consume: true, error: false)) {
      typeid = _parseTypeId();
    }
    list_stmt.add(VarDeclStmt(TokenIdentifier(varname, curTok.fileName, curTok.line, curTok.column), declType: typeid));
    expect([HT_Lexicon.IN], consume: true);
    var list_obj = _parseExpr();
    // 条件语句
    var get_length =
        MemberGetExpr(list_obj, TokenIdentifier(HT_Lexicon.length, _curFileName, curTok.line, curTok.column));
    var condition = BinaryExpr(SymbolExpr(TokenIdentifier(i, _curFileName, curTok.line, curTok.column)),
        Token(HT_Lexicon.lesser, _curFileName, curTok.line, curTok.column), get_length);
    // 在循环体之前手动插入递增语句和指针语句
    // 按下标取数组元素
    var loop_body = <ASTNode>[];
    // 这里一定要复制一个list_obj的表达式，否则在resolve的时候会因为是相同的对象出错，覆盖掉上面那个表达式的位置
    var sub_get_value =
        SubGetExpr(list_obj.clone(), SymbolExpr(TokenIdentifier(i, _curFileName, curTok.line, curTok.column)));
    var assign_stmt = ExprStmt(AssignExpr(TokenIdentifier(varname, _curFileName, curTok.line, curTok.column),
        Token(HT_Lexicon.assign, _curFileName, curTok.line, curTok.column), sub_get_value));
    loop_body.add(assign_stmt);
    // 递增下标变量
    var increment_expr = BinaryExpr(
        SymbolExpr(TokenIdentifier(i, _curFileName, curTok.line, curTok.column)),
        Token(HT_Lexicon.add, _curFileName, curTok.line, curTok.column),
        ConstIntExpr(_context.addConstInt(1), _curFileName, curTok.line, curTok.column));
    var increment_stmt = ExprStmt(AssignExpr(TokenIdentifier(i, _curFileName, curTok.line, curTok.column),
        Token(HT_Lexicon.assign, _curFileName, curTok.line, curTok.column), increment_expr));
    loop_body.add(increment_stmt);
    // 循环体
    expect([HT_Lexicon.roundRight], consume: true);
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      loop_body.addAll(_parseBlock(style: ParseStyle.function));
    } else {
      loop_body.add(_parseStmt(style: ParseStyle.function));
    }
    list_stmt.add(WhileStmt(condition, BlockStmt(loop_body, _curFileName, curTok.line, curTok.column)));
    return BlockStmt(list_stmt, _curFileName, curTok.line, curTok.column);
  }

  List<ParamDeclStmt> _parseParameters() {
    var params = <ParamDeclStmt>[];
    var optionalStarted = false;
    var namedStarted = false;
    while ((curTok.type != HT_Lexicon.roundRight) &&
        (curTok.type != HT_Lexicon.squareRight) &&
        (curTok.type != HT_Lexicon.curlyRight) &&
        (curTok.type != HT_Lexicon.endOfFile)) {
      if (params.isNotEmpty) {
        expect([HT_Lexicon.comma], consume: true, error: false);
      }
      // 可选参数，根据是否有方括号判断，一旦开始了可选参数，则不再增加参数数量arity要求
      if (!optionalStarted) {
        optionalStarted = expect([HT_Lexicon.squareLeft], consume: true, error: false);
        if (!optionalStarted && !namedStarted) {
          //检查命名参数，根据是否有花括号判断
          namedStarted = expect([HT_Lexicon.curlyLeft], consume: true, error: false);
        }
      }

      var isVariadic = false;
      if (!namedStarted) {
        isVariadic = expect([HT_Lexicon.varargs], consume: true, error: false);
      }

      var name = match(HT_Lexicon.identifier);
      var typeid = HT_TypeId.ANY;
      if (expect([HT_Lexicon.colon], consume: true, error: false)) {
        typeid = _parseTypeId();
      }

      ASTNode? initializer;
      if (optionalStarted || namedStarted) {
        //参数默认值
        if (expect([HT_Lexicon.assign], consume: true, error: false)) {
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
      expect([HT_Lexicon.squareRight], consume: true);
    } else if (namedStarted) {
      expect([HT_Lexicon.curlyRight], consume: true);
    }

    expect([HT_Lexicon.roundRight], consume: true);
    return params;
  }

  FuncDeclaration _parseFuncDeclaration(FunctionType functype, {bool isExtern = false, bool isStatic = false}) {
    final keyword = advance(1);
    Token? func_name;
    var typeParams = <String>[];
    if (curTok.type == HT_Lexicon.identifier) {
      func_name = advance(1);

      if (expect([HT_Lexicon.angleLeft], consume: true, error: false)) {
        while ((curTok.type != HT_Lexicon.angleRight) && (curTok.type != HT_Lexicon.endOfFile)) {
          if (typeParams.isNotEmpty) {
            expect([HT_Lexicon.comma], consume: true);
          }
          typeParams.add(advance(1).lexeme);
        }
        expect([HT_Lexicon.angleRight], consume: true);
      }
    }

    // if (functype == FuncStmtType.normal) {
    //   if (_declarations.containsKey(func_name)) throw HT_Error_Defined(func_name, fileName, curTok.line, curTok.column);
    // }

    var arity = 0;
    var isVariadic = false;
    var params = <ParamDeclStmt>[];

    if (functype != FunctionType.getter) {
      // 之前还没有校验过左括号
      if (expect([HT_Lexicon.roundLeft], consume: true, error: false)) {
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
          throw HT_Error_Setter();
        }
      }
    }

    var return_type = HT_TypeId.ANY;
    if ((functype != FunctionType.constructor) && (expect([HT_Lexicon.colon], consume: true, error: false))) {
      return_type = _parseTypeId();
    }

    var body = <ASTNode>[];
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      // 处理函数定义部分的语句块
      body = _parseBlock(style: ParseStyle.function);
    }
    expect([HT_Lexicon.semicolon], consume: true, error: false);

    var stmt = FuncDeclaration(return_type, params, _curFileName, keyword.line, keyword.column,
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

    if (_classStmts.containsKey(class_name.lexeme)) throw HT_Error_Defined_Parser(class_name.lexeme);

    // TODO: 嵌套类?
    _curClassName = class_name.lexeme;

    // generic type参数
    var typeParams = <String>[];
    if (expect([HT_Lexicon.angleLeft], consume: true, error: false)) {
      while ((curTok.type != HT_Lexicon.angleRight) && (curTok.type != HT_Lexicon.endOfFile)) {
        if (typeParams.isNotEmpty) {
          expect([HT_Lexicon.comma], consume: true);
        }
        typeParams.add(advance(1).lexeme);
      }
      expect([HT_Lexicon.angleRight], consume: true);
    }

    // 继承父类
    SymbolExpr? super_class;
    ClassDeclStmt? super_class_decl;
    HT_TypeId? super_class_type_args;
    if (expect([HT_Lexicon.EXTENDS], consume: true, error: false)) {
      if (curTok.lexeme == class_name.lexeme) {
        throw HT_Error_Unexpected(class_name.lexeme);
      } else if (_classStmts[curTok.lexeme] == null) {
        throw HT_Error_NotClass(curTok.lexeme);
      }

      super_class = SymbolExpr(curTok);
      super_class_decl = _classStmts[super_class.id.lexeme] as ClassDeclStmt?;
      advance(1);
      if (expect([HT_Lexicon.angleLeft], consume: true, error: false)) {
        // 类型传入参数
        super_class_type_args = _parseTypeId();
        expect([HT_Lexicon.angleRight], consume: true);
      }
    }

    // 类的定义体
    var variables = <VarDeclStmt>[];
    var methods = <FuncDeclaration>[];
    if (expect([HT_Lexicon.curlyLeft], consume: true, error: false)) {
      while ((curTok.type != HT_Lexicon.curlyRight) && (curTok.type != HT_Lexicon.endOfFile)) {
        var member = _parseStmt(style: isExtern ? ParseStyle.externalClass : ParseStyle.klass);
        if (member is VarDeclStmt) {
          variables.add(member);
        } else if (member is FuncDeclaration) {
          methods.add(member);
        }
      }
      expect([HT_Lexicon.curlyRight], consume: true);
    } else {
      expect([HT_Lexicon.semicolon], consume: true, error: false);
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
