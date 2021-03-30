import '../errors.dart';
import 'ast.dart';
import '../lexicon.dart';
import '../common.dart';

/// 负责对语句列表进行分析，并生成变量作用域
class HTAstResolver implements ASTNodeVisitor {
  int _curLine = 0;
  int get curLine => _curLine;
  int _curColumn = 0;
  int get curColumn => _curColumn;
  late final String curFileName;

  /// 代码块列表，每个代码块包含一个字典：key：变量标识符，value：变量是否已初始化
  final _blocks = <Map<String, bool>>[];

  final _classes = <ClassDeclStmt>[];
  final _funcs = <FuncDeclStmt>[];

  FunctionType? _curFuncType;
  ClassType? _curClassType;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _distances = <ASTNode, int>{};

  // 返回每个表达式对应的求值深度
  Map<ASTNode, int> resolve(List<ASTNode> statements, String fileName) {
    curFileName = fileName;

    _beginBlock();
    for (final stmt in statements) {
      _resolveASTNode(stmt);
    }
    for (final klass in _classes) {
      _resolveClass(klass);
    }
    var funcs = List.from(_funcs);
    for (final func in funcs) {
      _resolveFunction(func);
    }
    _endBlock();
    return _distances;
  }

  void _beginBlock() => _blocks.add(<String, bool>{});
  void _endBlock() => _blocks.removeLast();

  void _declare(String name, {bool define = false, bool error = true}) {
    if (_blocks.isNotEmpty) {
      var block = _blocks.last;

      if (block.containsKey(name) && error) {
        // throw HTErrorDefined(name, line, column, curFileName);
      }
      block[name] = define;
    }
  }

  void _define(String name) {
    if (_blocks.isNotEmpty) {
      _blocks.last[name] = true;
    }
  }

  void _lookUpVar(ASTNode expr, String varname) {
    for (var i = _blocks.length - 1; i >= 0; --i) {
      if (_blocks[i].containsKey(varname)) {
        _distances[expr] = _blocks.length - 1 - i;
        return;
      }
    }

    // Not found. Assume it is global.
  }

  void _resolveBlock(List<ASTNode> statements) {
    for (final stmt in statements) {
      _resolveASTNode(stmt);
    }
  }

  void _resolveFunction(FuncDeclStmt stmt) {
    var save = _curFuncType;
    _curFuncType = stmt.funcType;

    _beginBlock();
    for (final param in stmt.params) {
      visitParamDeclStmt(param);
    }
    if (stmt.definition != null) _resolveBlock(stmt.definition!);
    _endBlock();
    _curFuncType = save;
  }

  void _resolveClass(ClassDeclStmt stmt) {
    final savedClassType = _curClassType;

    _curClassType = ClassType.normal;

    _beginBlock();

    // 类自己的默认构造函数
    _declare(stmt.id.lexeme, define: true);

    // _blocks.last[HTLexicon.SUPER] = true;

    // 注册类静态变量
    var staticFuncStmts = <FuncDeclStmt>[];
    for (final varStmt in stmt.variables) {
      if (varStmt.isStatic) {
        visitVarDeclStmt(varStmt);
      }
    }

    // 注册静态函数名（不包含命名构造函数，因为后者不会在没有类名时单独使用）
    for (final funcStmt in stmt.methods) {
      if (funcStmt.isStatic) {
        _declare(funcStmt.id!.lexeme, define: true);
        staticFuncStmts.add(funcStmt);
      } else if (funcStmt.funcType == FunctionType.constructor) {
        staticFuncStmts.add(funcStmt);
      }
    }

    // 解析静态函数定义
    for (final funcStmt in staticFuncStmts) {
      if (funcStmt.funcType != FunctionType.constructor) {
        _resolveFunction(funcStmt);
      }
    }

    _beginBlock();
    _blocks.last[HTLexicon.THIS] = true;
    // 递归获取所有父类的成员变量和成员函数
    var instanceFuncStmts = <FuncDeclStmt>[];
    ClassDeclStmt? curStmt = stmt;
    while (curStmt != null) {
      // 注册变量名
      for (final varStmt in curStmt.variables) {
        if (!varStmt.isStatic) {
          if (curStmt != stmt && varStmt.id.lexeme.startsWith(HTLexicon.underscore)) {
            continue;
          }
          visitVarDeclStmt(varStmt);
        }
      }

      // 注册函数名
      for (final funcStmt in curStmt.methods) {
        if (!funcStmt.isStatic && (funcStmt.funcType != FunctionType.constructor)) {
          if (curStmt != stmt && funcStmt.id != null && funcStmt.id!.lexeme.startsWith(HTLexicon.underscore)) {
            continue;
          }
          _declare(funcStmt.id!.lexeme, define: true);
          instanceFuncStmts.add(funcStmt);
        }
      }

      curStmt = curStmt.superClassDeclStmt;
    }
    // 构造函数定义部分需要在实例中解析
    for (final funcStmt in staticFuncStmts) {
      if (funcStmt.funcType == FunctionType.constructor) {
        _resolveFunction(funcStmt);
      }
    }
    // 解析函数定义
    for (final funcStmt in instanceFuncStmts) {
      _resolveFunction(funcStmt);
    }

    _endBlock();

    _endBlock();

    _curClassType = savedClassType;
  }

  void _resolveASTNode(ASTNode ast) => ast.accept(this);

  /// Null并没有任何变量需要解析，因此这里留空
  @override
  dynamic visitNullExpr(NullExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
  }

  /// 字面量并没有任何变量需要解析，因此这里留空

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
  }

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
  }

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
  }

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
  }

  @override
  dynamic visitGroupExpr(GroupExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.inner);
  }

  @override
  dynamic visitLiteralVectorExpr(LiteralVectorExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    for (final item in expr.vector) {
      _resolveASTNode(item);
    }
  }

  @override
  dynamic visitLiteralDictExpr(LiteralDictExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    for (final key in expr.map.keys) {
      _resolveASTNode(key);
      _resolveASTNode(expr.map[key]!);
    }
  }

  // @override
  // dynamic visitTypeExpr(TypeExpr expr) {}

  @override
  dynamic visitSymbolExpr(SymbolExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    if (_blocks.isNotEmpty && _blocks.last[expr.id.lexeme] == false) {
      throw HTErrorInitialized(expr.id.lexeme);
    }

    _lookUpVar(expr, expr.id.lexeme);
  }

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.value);
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.left);
    _resolveASTNode(expr.right);
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.callee);

    for (final arg in expr.positionalArgs) {
      _resolveASTNode(arg);
    }

    for (final arg in expr.namedArgs.values) {
      _resolveASTNode(arg);
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.value);
    _lookUpVar(expr, expr.variable.lexeme);
  }

  @override
  dynamic visitThisExpr(ThisExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    if (_curClassType == null) {
      throw HTErrorUnexpected(expr.keyword.lexeme);
    }

    _lookUpVar(expr, expr.keyword.lexeme);
  }

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.collection);
    _resolveASTNode(expr.key);
  }

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.collection);
    _resolveASTNode(expr.key);
    _resolveASTNode(expr.value);
  }

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.collection);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    _resolveASTNode(expr.collection);
    _resolveASTNode(expr.value);
  }

  @override
  dynamic visitImportStmt(ImportStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
  }

  @override
  dynamic visitExprStmt(ExprStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    _resolveASTNode(stmt.expr);
  }

  @override
  dynamic visitBlockStmt(BlockStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    _beginBlock();
    _resolveBlock(stmt.block);
    _endBlock();
  }

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    if ((_curFuncType == null) || (_curFuncType == FunctionType.constructor)) {
      throw HTErrorReturn();
    }

    if (stmt.value != null) {
      _resolveASTNode(stmt.value!);
    }
  }

  @override
  dynamic visitIfStmt(IfStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    _resolveASTNode(stmt.condition);
    _resolveASTNode(stmt.thenBranch!);
    if (stmt.elseBranch != null) {
      _resolveASTNode(stmt.elseBranch!);
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    _resolveASTNode(stmt.condition);
    _resolveASTNode(stmt.loop!);
  }

  @override
  dynamic visitBreakStmt(BreakStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
  }

  @override
  dynamic visitContinueStmt(ContinueStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
  }

  @override
  void visitVarDeclStmt(VarDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    if (stmt.initializer != null) {
      _resolveASTNode(stmt.initializer!);
      _declare(stmt.id.lexeme, define: true);
    } else {
      _define(stmt.id.lexeme);
    }
  }

  @override
  void visitParamDeclStmt(ParamDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    if (stmt.initializer != null) {
      _resolveASTNode(stmt.initializer!);
    }
    _declare(stmt.id.lexeme, define: true);
  }

  @override
  void visitFuncDeclStmt(FuncDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    if (stmt.id != null) {
      _declare(stmt.id!.lexeme, define: true);
      _funcs.add(stmt);
    } else {
      _resolveFunction(stmt);
    }
  }

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    _declare(stmt.id.lexeme, define: true);
    _classes.add(stmt);
  }

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    _declare(stmt.id.lexeme, define: true);
  }
}
