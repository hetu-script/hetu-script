import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'token.dart';
import 'constants.dart';

//> function-type
enum _FunctionType {
  none,
  normal,
  constructor,
  method,
}

enum _ClassType {
  none,
  normal,
  subClass,
}

/// 负责对语句列表进行分析，并生成变量作用域
class Resolver implements ExprVisitor, StmtVisitor {
  /// 代码块列表，每个代码块包含一个字典：key：变量标识符，value：变量是否已初始化
  final _blocks = <Map<String, bool>>[];
  final _locals = <Expr, int>{};
  _FunctionType _curFuncType = _FunctionType.none;
  _ClassType _curClassType = _ClassType.none;

  void _beginBlock() => _blocks.add(<String, bool>{});
  void _endBlock() => _blocks.removeLast();

  void _declare(Token varTok, {bool define = false}) {
    if (_blocks.isNotEmpty) {
      var block = _blocks.last;

      if (block.containsKey(varTok.text)) {
        throw HetuError('(Resolver) Variable [${varTok.text}] already declared in this scope. '
            ' [${varTok.lineNumber}, ${varTok.colNumber}].');
      }
      block[varTok.text] = define;
    }
  }

  void _define(String name) {
    if (_blocks.isNotEmpty) {
      _blocks.last[name] = true;
    }
  }

  void _addLocal(Expr expr, String varname) {
    for (var i = _blocks.length - 1; i >= 0; --i) {
      if (_blocks[i].containsKey(varname)) {
        _locals[expr] = _blocks.length - 1 - i;
        return;
      }
    }

    //print('$varname not found in local.');
    // Not found. Assume it is global.
  }

  Map<Expr, int> resolve(List<Stmt> statements) {
    var result = <Expr, int>{};
    if (statements != null) {
      for (var stmt in statements) {
        _resolveStmt(stmt);
      }
      result = _locals;
    }
    return result;
  }

  void _resolveExpr(Expr expr) => expr.accept(this);
  void _resolveStmt(Stmt stmt) => stmt.accept(this);

  void _resolveFunction(FuncStmt stmt, _FunctionType type) {
    var enclosingFunctionType = _curFuncType;
    _curFuncType = type;

    _beginBlock();
    for (var param in stmt.params) {
      _declare(param.varname, define: true);
    }
    resolve(stmt.definition);
    _endBlock();
    _curFuncType = enclosingFunctionType;
  }

  /// 字面量并没有任何变量需要解析，因此这里留空
  @override
  dynamic visitLiteralExpr(LiteralExpr expr) {}

  @override
  dynamic visitVarExpr(VarExpr expr) {
    if (_blocks.isNotEmpty && _blocks.last[expr.name] == false) {
      throw HetuError('(Resolver) Cannot use uninitialized variable [${expr.name.text}] '
          ' [${expr.lineNumber}, ${expr.colNumber}].');
    }

    _addLocal(expr, expr.name.text);
  }

  @override
  dynamic visitGroupExpr(GroupExpr expr) => _resolveExpr(expr.expr);

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
    _addLocal(expr, expr.variable.text);
    return null;
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
  void visitVarStmt(VarStmt stmt) {
    if (stmt.initializer != null) {
      _resolveExpr(stmt.initializer);
      _declare(stmt.varname, define: true);
    } else {
      _define(stmt.varname.text);
    }
    return null;
  }

  @override
  void visitExprStmt(ExprStmt stmt) => _resolveExpr(stmt.expr);

  @override
  void visitBlockStmt(BlockStmt stmt) {
    _beginBlock();
    resolve(stmt.block);
    _endBlock();
  }

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    if (_curFuncType == _FunctionType.none) {
      throw HetuError('(Resolver) Cannot return from top-level code. '
          ' [${stmt.keyword.lineNumber}, ${stmt.keyword.colNumber}].');
    }
    if (stmt.expr != null) {
      if (_curFuncType == _FunctionType.constructor) {
        throw HetuError('(Resolver) Cannot return from an initializer, '
            ' [${stmt.keyword.lineNumber}, ${stmt.keyword.colNumber}].');
      }
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
  void visitFuncStmt(FuncStmt stmt) {
    _declare(stmt.name, define: true);
    _resolveFunction(stmt, _FunctionType.normal);
  }

  @override
  void visitConstructorStmt(ConstructorStmt stmt) {
    _resolveFunction(stmt, _FunctionType.constructor);
  }

  @override
  void visitClassStmt(ClassStmt stmt) {
    _ClassType enclosingClass = _curClassType;

    _declare(stmt.name, define: true);

    if (stmt.superClass != null) {
      if (stmt.name.text == stmt.superClass.name.text) {
        throw HetuError('(Resolver) A class cannot inherit from itself, '
            ' [${stmt.name.lineNumber}, ${stmt.name.colNumber}].');
      }

      _resolveExpr(stmt.superClass);
      _beginBlock();
      _blocks.last[Constants.Super] = true;

      _curClassType = _ClassType.subClass;
    } else {
      _curClassType = _ClassType.normal;
    }

    _beginBlock();
    _blocks.last[Constants.This] = true;

    for (var method in stmt.methods) {
      if (method is ConstructorStmt) {
        _resolveFunction(method, _FunctionType.constructor);
      } else {
        _resolveFunction(method, _FunctionType.method);
      }
    }

    for (var variable in stmt.variables) {
      visitVarStmt(variable);
    }

    _endBlock();

    if (stmt.superClass != null) _endBlock();

    _curClassType = enclosingClass;
  }

  @override
  void visitThisExpr(ThisExpr expr) {
    if (_curClassType == _ClassType.none) {
      throw HetuError('(Resolver) Cannot use "this" outside of a method. '
          ' [${expr.keyword.lineNumber}, ${expr.keyword.colNumber}].');
    }

    _addLocal(expr, expr.keyword.text);
  }
}
