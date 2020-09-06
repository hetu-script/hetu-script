import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'common.dart';
import 'interpreter.dart';

enum _ClassType {
  none,
  normal,
  subClass,
}

/// 负责对语句列表进行分析，并生成变量作用域
class Resolver implements ExprVisitor, StmtVisitor {
  final Interpreter interpreter;

  /// 代码块列表，每个代码块包含一个字典：key：变量标识符，value：变量是否已初始化
  var _blocks = <Map<String, bool>>[];

  var _classes = <ClassStmt>[];
  var _funcs = <FuncStmt>[];

  String _curFileName;
  FuncStmtType _curFuncType;
  _ClassType _curClassType = _ClassType.none;

  Resolver(this.interpreter);

  void _beginBlock() => _blocks.add(<String, bool>{});
  void _endBlock() => _blocks.removeLast();

  void _declare(String name, int line, int column, {bool define = false, bool error = true}) {
    if (_blocks.isNotEmpty) {
      var block = _blocks.last;

      if (block.containsKey(name) && error) {
        throw HSErr_Defined(name, line, column, _curFileName);
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
        var distance = _blocks.length - 1 - i;
        interpreter.addVarPos(expr, distance);
        return;
      }
    }

    // Not found. Assume it is global.
  }

  void resolve(List<Stmt> statements, String fileName, {String libName = HS_Common.global}) {
    if ((libName != null) && (libName != HS_Common.global)) {
      _beginBlock();
    }
    _curFileName = fileName;

    _beginBlock();
    for (var stmt in statements) {
      _resolveStmt(stmt);
    }
    for (var klass in _classes) {
      _resolveClass(klass);
    }
    for (var func in _funcs) {
      _resolveFunction(func);
    }
    _endBlock();
    if ((libName != null) && (libName != HS_Common.global)) {
      _endBlock();
    }
  }

  void _resolveBlock(List<Stmt> statements) {
    for (var stmt in statements) {
      _resolveStmt(stmt);
    }
  }

  void _resolveExpr(Expr expr) => expr.accept(this);
  void _resolveStmt(Stmt stmt) => stmt.accept(this);

  void _resolveFunction(FuncStmt stmt) {
    var save = _curFuncType;
    _curFuncType = stmt.funcType;

    _beginBlock();
    if (stmt.arity == -1) {
      _declare(HS_Common.Arguments, stmt.keyword.line, stmt.keyword.column, define: true);
    } else {
      for (var param in stmt.params) {
        _declare(param.name.lexeme, param.name.line, param.name.column, define: true);
      }
    }
    _resolveBlock(stmt.definition);
    _endBlock();
    _curFuncType = save;
  }

  void _resolveClass(ClassStmt stmt) {
    _ClassType savedClassType = _curClassType;

    if (stmt.superClass != null) {
      if (stmt.name == stmt.superClass.name) {
        throw HSErr_Unexpected(stmt.superClass.toString(), stmt.keyword.line, stmt.keyword.column, _curFileName);
      }

      //_resolveExpr(stmt.superClass);

      _curClassType = _ClassType.subClass;
    } else {
      _curClassType = _ClassType.normal;
    }

    _beginBlock();
    for (var variable in stmt.variables) {
      if (variable.isStatic) {
        visitVarStmt(variable);
      }
    }

    var savedFuncList = _funcs;
    _funcs = <FuncStmt>[];
    // 类静态函数，先注册函数名
    for (var method in stmt.methods) {
      if (method.isStatic) {
        _declare(method.internalName, method.keyword.line, method.keyword.column, define: true);
        if ((method.internalName.startsWith(HS_Common.getFun) || method.internalName.startsWith(HS_Common.setFun)) &&
            !_blocks.last.containsKey(method.name)) {
          _declare(method.name, method.keyword.line, method.keyword.column, define: true);
        }
        if (method.funcType != FuncStmtType.constructor) {
          _funcs.add(method);
        }
      }
    }
    // 然后再解析函数定义
    for (var stmt in _funcs) {
      _resolveFunction(stmt);
    }

    _funcs = <FuncStmt>[];
    _beginBlock();
    // 注册实例中的成员变量
    _blocks.last[HS_Common.THIS] = true;
    for (var variable in stmt.variables) {
      if (!variable.isStatic) {
        visitVarStmt(variable);
      }
    }
    // 成员函数，先注册函数名
    for (var method in stmt.methods) {
      if (!method.isStatic) {
        if (method.funcType != FuncStmtType.constructor) {
          _declare(method.internalName, method.keyword.line, method.keyword.column, define: true);
          if ((method.internalName.startsWith(HS_Common.getFun) || method.internalName.startsWith(HS_Common.setFun)) &&
              !_blocks.last.containsKey(method.name)) {
            _declare(method.name, method.keyword.line, method.keyword.column, define: true);
          }
        }
        _funcs.add(method);
      }
    }
    // 然后再解析函数定义
    for (var stmt in _funcs) {
      _resolveFunction(stmt);
    }
    _funcs = savedFuncList;
    _endBlock();

    _endBlock();

    _curClassType = savedClassType;
  }

  /// Null并没有任何变量需要解析，因此这里留空
  @override
  dynamic visitNullExpr(NullExpr expr) {}

  /// 字面量并没有任何变量需要解析，因此这里留空
  @override
  dynamic visitLiteralExpr(LiteralExpr expr) {}

  @override
  dynamic visitGroupExpr(GroupExpr expr) => _resolveExpr(expr.inner);

  @override
  dynamic visitVectorExpr(VectorExpr expr) {
    for (var item in expr.vector) {
      _resolveExpr(item);
    }
  }

  @override
  dynamic visitBlockExpr(BlockExpr expr) {
    for (var key in expr.map.keys) {
      _resolveExpr(key);
      _resolveExpr(expr.map[key]);
    }
  }

  // @override
  // dynamic visitTypeExpr(TypeExpr expr) {}

  @override
  dynamic visitVarExpr(VarExpr expr) {
    if (_blocks.isNotEmpty && _blocks.last[expr.name] == false) {
      throw HSErr_Initialized(expr.name.lexeme, expr.line, expr.column, _curFileName);
    }

    _lookUpVar(expr, expr.name.lexeme);
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

    for (var arg in expr.args) {
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
  void visitMemberSetExpr(MemberSetExpr expr) {
    _resolveExpr(expr.collection);
    _resolveExpr(expr.value);
  }

  @override
  dynamic visitImportStmt(ImportStmt stmt) {}

  @override
  void visitVarStmt(VarStmt stmt) {
    if (stmt.initializer != null) {
      _resolveExpr(stmt.initializer);
      _declare(stmt.name.lexeme, stmt.name.line, stmt.name.column, define: true);
    } else {
      _define(stmt.name.lexeme);
    }
  }

  @override
  void visitExprStmt(ExprStmt stmt) => _resolveExpr(stmt.expr);

  @override
  void visitBlockStmt(BlockStmt stmt) {
    _beginBlock();
    _resolveBlock(stmt.block);
    _endBlock();
  }

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    if ((_curFuncType == null) || (_curFuncType == FuncStmtType.constructor)) {
      throw HSErr_Unexpected(stmt.keyword.lexeme, stmt.keyword.line, stmt.keyword.column, _curFileName);
    }

    if (stmt.expr != null) {
      _resolveExpr(stmt.expr);
    }
  }

  @override
  void visitIfStmt(IfStmt stmt) {
    _resolveExpr(stmt.condition);
    _resolveStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) {
      _resolveStmt(stmt.elseBranch);
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    _resolveExpr(stmt.condition);
    _resolveStmt(stmt.loop);
  }

  @override
  void visitBreakStmt(BreakStmt stmt) {}

  @override
  void visitContinueStmt(ContinueStmt stmt) {}

  @override
  void visitThisExpr(ThisExpr expr) {
    if (_curClassType == _ClassType.none) {
      throw HSErr_Unexpected(expr.keyword.lexeme, expr.line, expr.column, _curFileName);
    }

    _lookUpVar(expr, expr.keyword.lexeme);
  }

  @override
  void visitFuncStmt(FuncStmt stmt) {
    _declare(stmt.name, stmt.keyword.line, stmt.keyword.column, define: true);
    _funcs.add(stmt);
  }

  @override
  void visitClassStmt(ClassStmt stmt) {
    _declare(stmt.name, stmt.keyword.line, stmt.keyword.column, define: true);
    _classes.add(stmt);
  }
}
