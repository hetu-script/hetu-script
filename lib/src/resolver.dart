import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'lexicon.dart';
import 'common.dart';

enum _ClassType {
  none,
  normal,
}

/// 负责对语句列表进行分析，并生成变量作用域
class Resolver implements ExprVisitor, StmtVisitor {
  final CodeRunner interpreter;
  late final String _curFileName;
  String _libName = HT_Lexicon.global;

  /// 代码块列表，每个代码块包含一个字典：key：变量标识符，value：变量是否已初始化
  final _blocks = <Map<String, bool>>[];

  final _classes = <ClassDeclStmt>[];
  final _funcs = <FuncDeclStmt>[];

  FuncStmtType? _curFuncType;
  _ClassType _curClassType = _ClassType.none;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _distances = <Expr, int>{};

  Resolver(this.interpreter);

  // 返回每个表达式对应的求值深度
  Map<Expr, int> resolve(List<Stmt> statements, String fileName, {String libName = HT_Lexicon.global}) {
    _curFileName = fileName;
    _libName = libName;
    if (_libName != HT_Lexicon.global) _beginBlock();

    _beginBlock();
    for (final stmt in statements) {
      _resolveStmt(stmt);
    }
    for (final klass in _classes) {
      _resolveClass(klass);
    }
    for (final func in _funcs) {
      _resolveFunction(func);
    }
    _endBlock();
    if (libName != HT_Lexicon.global) {
      _endBlock();
    }

    return _distances;
  }

  void _beginBlock() => _blocks.add(<String, bool>{});
  void _endBlock() => _blocks.removeLast();

  void _declare(String name, int? line, int? column, {bool define = false, bool error = true}) {
    if (_blocks.isNotEmpty) {
      var block = _blocks.last;

      if (block.containsKey(name) && error) {
        // throw HTErr_Defined(name, line, column, _curFileName);
      }
      block[name] = define;
    }
  }

  void _define(String name) {
    if (_blocks.isNotEmpty) {
      _blocks.last[name] = true;
    }
  }

  void _lookUpVar(Expr expr, String varname) {
    for (var i = _blocks.length - 1; i >= 0; --i) {
      if (_blocks[i].containsKey(varname)) {
        _distances[expr] = _blocks.length - 1 - i;
        return;
      }
    }

    // Not found. Assume it is global.
  }

  void _resolveBlock(List<Stmt> statements) {
    for (final stmt in statements) {
      _resolveStmt(stmt);
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

    _curClassType = _ClassType.normal;

    _beginBlock();
    // TODO: super表达式
    _blocks.last[HT_Lexicon.SUPER] = true;

    // 递归获取所有父类的静态变量和静态函数
    var static_var_stmt = <VarDeclStmt>[];
    var static_func_stmt = <FuncDeclStmt>[];
    ClassDeclStmt? cur_stmt = stmt;
    while (cur_stmt != null) {
      for (final varStmt in cur_stmt.variables) {
        if (varStmt.isStatic) {
          static_var_stmt.add(varStmt);
        }
      }

      for (final funcStmt in cur_stmt.methods) {
        if (funcStmt.isStatic || (funcStmt.funcType == FuncStmtType.constructor)) {
          if ((funcStmt.internalName.startsWith(HT_Lexicon.getter) ||
                  funcStmt.internalName.startsWith(HT_Lexicon.setter)) &&
              !_blocks.last.containsKey(funcStmt.id)) {
            _declare(funcStmt.id, funcStmt.keyword.line, funcStmt.keyword.column, define: true);
          } else {
            _declare(funcStmt.internalName, funcStmt.keyword.line, funcStmt.keyword.column, define: true);
          }
          static_func_stmt.add(funcStmt);
        }
      }

      cur_stmt = cur_stmt.superClassDeclStmt;
    }
    // 注册变量名
    for (final varStmt in static_var_stmt) {
      visitVarDeclStmt(varStmt);
    }
    // 解析函数定义
    for (final funcStmt in static_func_stmt) {
      if (funcStmt.funcType != FuncStmtType.constructor) {
        _resolveFunction(funcStmt);
      }
    }

    _beginBlock();
    _blocks.last[HT_Lexicon.THIS] = true;
    // 递归获取所有父类的成员变量和成员函数
    var instance_var_stmt = <VarDeclStmt>[];
    var instance_func_stmt = <FuncDeclStmt>[];
    cur_stmt = stmt;
    while (cur_stmt != null) {
      for (final varStmt in cur_stmt.variables) {
        if (!varStmt.isStatic) {
          instance_var_stmt.add(varStmt);
        }
      }

      for (final funcStmt in cur_stmt.methods) {
        if (!funcStmt.isStatic && (funcStmt.funcType != FuncStmtType.constructor)) {
          _declare(funcStmt.internalName, funcStmt.keyword.line, funcStmt.keyword.column, define: true);
          if ((funcStmt.internalName.startsWith(HT_Lexicon.getter) ||
                  funcStmt.internalName.startsWith(HT_Lexicon.setter)) &&
              !_blocks.last.containsKey(funcStmt.id)) {
            _declare(funcStmt.id, funcStmt.keyword.line, funcStmt.keyword.column, define: true);
          }
          instance_func_stmt.add(funcStmt);
        }
      }

      cur_stmt = cur_stmt.superClassDeclStmt;
    }
    // 注册变量名
    for (final varStmt in instance_var_stmt) {
      if (!varStmt.isStatic) {
        visitVarDeclStmt(varStmt);
      }
    }
    for (final funcStmt in static_func_stmt) {
      if (funcStmt.funcType == FuncStmtType.constructor) {
        _resolveFunction(funcStmt);
      }
    }
    // 解析函数定义
    for (final funcStmt in instance_func_stmt) {
      _resolveFunction(funcStmt);
    }

    _endBlock();

    _endBlock();

    _curClassType = savedClassType;
  }

  void _resolveExpr(Expr expr) => expr.accept(this);
  void _resolveStmt(Stmt stmt) => stmt.accept(this);

  /// Null并没有任何变量需要解析，因此这里留空
  @override
  dynamic visitNullExpr(NullExpr expr) {}

  /// 字面量并没有任何变量需要解析，因此这里留空

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) {}

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) {}

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {}

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {}

  @override
  dynamic visitGroupExpr(GroupExpr expr) => _resolveExpr(expr.inner);

  @override
  dynamic visitLiteralVectorExpr(LiteralVectorExpr expr) {
    for (final item in expr.vector) {
      _resolveExpr(item);
    }
  }

  @override
  dynamic visitLiteralDictExpr(LiteralDictExpr expr) {
    for (final key in expr.map.keys) {
      _resolveExpr(key);
      _resolveExpr(expr.map[key]!);
    }
  }

  @override
  dynamic visitLiteralFunctionExpr(LiteralFunctionExpr expr) {
    _resolveFunction(expr.funcStmt);
  }

  // @override
  // dynamic visitTypeExpr(TypeExpr expr) {}

  @override
  dynamic visitSymbolExpr(SymbolExpr expr) {
    if (_blocks.isNotEmpty && _blocks.last[expr.id.lexeme] == false) {
      throw HTErr_Initialized(expr.id.lexeme, _curFileName, expr.line, expr.column);
    }

    _lookUpVar(expr, expr.id.lexeme);
  }

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    _resolveExpr(expr.value);
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    _resolveExpr(expr.callee);

    for (final arg in expr.positionalArgs) {
      _resolveExpr(arg);
    }

    for (final arg in expr.namedArgs.values) {
      _resolveExpr(arg);
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    _resolveExpr(expr.value);
    _lookUpVar(expr, expr.variable.lexeme);
  }

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {
    _resolveExpr(expr.collection);
    _resolveExpr(expr.key);
  }

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {
    _resolveExpr(expr.collection);
    _resolveExpr(expr.key);
    _resolveExpr(expr.value);
  }

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    _resolveExpr(expr.collection);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    _resolveExpr(expr.collection);
    _resolveExpr(expr.value);
  }

  @override
  dynamic visitImportStmt(ImportStmt stmt) {}

  @override
  dynamic visitExprStmt(ExprStmt stmt) => _resolveExpr(stmt.expr);

  @override
  dynamic visitBlockStmt(BlockStmt stmt) {
    _beginBlock();
    _resolveBlock(stmt.block);
    _endBlock();
  }

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {
    if ((_curFuncType == null) || (_curFuncType == FuncStmtType.constructor)) {
      throw HTErr_Unexpected(stmt.keyword.lexeme, _curFileName, stmt.keyword.line, stmt.keyword.column);
    }

    if (stmt.expr != null) {
      _resolveExpr(stmt.expr!);
    }
  }

  @override
  dynamic visitIfStmt(IfStmt stmt) {
    _resolveExpr(stmt.condition);
    _resolveStmt(stmt.thenBranch!);
    if (stmt.elseBranch != null) {
      _resolveStmt(stmt.elseBranch!);
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    _resolveExpr(stmt.condition);
    _resolveStmt(stmt.loop!);
  }

  @override
  dynamic visitBreakStmt(BreakStmt stmt) {}

  @override
  dynamic visitContinueStmt(ContinueStmt stmt) {}

  @override
  dynamic visitThisExpr(ThisExpr expr) {
    if (_curClassType == _ClassType.none) {
      throw HTErr_Unexpected(expr.keyword.lexeme, _curFileName, expr.line, expr.column);
    }

    _lookUpVar(expr, expr.keyword.lexeme);
  }

  @override
  void visitVarDeclStmt(VarDeclStmt stmt) {
    if (stmt.initializer != null) {
      _resolveExpr(stmt.initializer!);
      _declare(stmt.id.lexeme, stmt.id.line, stmt.id.column, define: true);
    } else {
      _define(stmt.id.lexeme);
    }
  }

  @override
  void visitParamDeclStmt(ParamDeclStmt stmt) {
    if (stmt.initializer != null) {
      _resolveExpr(stmt.initializer!);
    }
    _declare(stmt.id.lexeme, stmt.id.line, stmt.id.column, define: true);
  }

  @override
  void visitFuncDeclStmt(FuncDeclStmt stmt) {
    _declare(stmt.id, stmt.keyword.line, stmt.keyword.column, define: true);
    _funcs.add(stmt);
  }

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {
    _declare(stmt.id, stmt.keyword.line, stmt.keyword.column, define: true);
    _classes.add(stmt);
  }

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {
    _declare(stmt.id, stmt.keyword.line, stmt.keyword.column, define: true);
  }
}
