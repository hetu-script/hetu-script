import 'package:hetu_script/hetu.dart';

import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'common.dart';
import 'interpreter.dart';
import 'namespace.dart';

//> function-type
// enum _FunctionType {
//   none,
//   normal,
//   constructor,
//   method,
// }

// enum _ClassType {
//   none,
//   normal,
//   subClass,
// }

/// 负责对语句列表进行分析，并生成变量作用域
class Resolver implements ExprVisitor, StmtVisitor {
  final Interpreter interpreter;

  /// 代码块列表，每个代码块包含一个字典：key：变量标识符，value：变量是否已初始化
  // var _blocks = <Map<String, bool>>[];

  var _funcStmts = <FuncStmt, HS_Function>{};

  //_FunctionType _curFuncType = _FunctionType.none;
  //_ClassType _curClassType = _ClassType.none;

  Namespace _curContext;
  String _curFileName;

  Resolver(this.interpreter);

  // void _beginBlock() => _blocks.add(<String, bool>{});
  // void _endBlock() => _blocks.removeLast();

  // void _declare(String name, int line, int column, {bool define = false, bool error = true}) {
  //   if (_blocks.isNotEmpty) {
  //     var block = _blocks.last;

  //     if (block.containsKey(name) && error) {
  //       throw HSErr_Defined(name, line, column, interpreter.curFileName);
  //     }
  //     block[name] = define;
  //   }
  // }

  // void _define(String name) {
  //   if (_blocks.isNotEmpty) {
  //     _blocks.last[name] = true;
  //   }
  // }

  // void _addLocal(Expr expr, String varname) {
  //   for (var i = _blocks.length - 1; i >= 0; --i) {
  //     if (_blocks[i].containsKey(varname)) {
  //       var distance = _blocks.length - 1 - i;
  //       interpreter.addLocal(expr, distance);
  //       return;
  //     }
  //   }

  //   //print('$varname not found in local.');
  //   // Not found. Assume it is global.
  // }

  void resolve(List<Stmt> statements, Namespace context, String fileName) {
    _curContext = context;
    _curFileName = fileName;

    //_beginBlock();
    for (var stmt in statements) {
      _resolveStmt(stmt);
    }
    for (var stmt in _funcStmts.keys) {
      _resolveFunction(stmt, _funcStmts[stmt]); //, _funcStmts[stmt]);
    }
    //_endBlock();
  }

  void _addExpr(Expr expr, String varname) {
    var space = _curContext;
    String fullName = _curContext.fullName;
    while (!space.contains(varname)) {
      space = _curContext.closure;
      if (space == null) {
        throw HSErr_Undefined(varname, null, null, _curFileName);
      }
      fullName += HS_Common.Dot + space.name;
    }

    if (_curContext.closure is! HS_Class) {
      interpreter.addVarPos(expr, fullName);
    }
  }

  void _resolveBlock(List<Stmt> statements) {
    for (var stmt in statements) {
      _resolveStmt(stmt);
    }
  }

  void _resolveFunction(FuncStmt stmt, String fullName, {HS_Class klass}) //, _FunctionType type)
  {
    //var enclosingFunctionType = _curFuncType;
    //_curFuncType = type;
    var save = _curContext;
    _curContext = interpreter.defineSpace(HS_Function()(closure: _curContext));
    //_curContext = Namespace.getSpace(fullName, null, null, _curFileName);
    _curContext.declare(HS_Common.This, null, null, _curFileName);

    //_beginBlock();
    if (stmt.arity == -1) {
      assert(stmt.params.length == 1);
      _curContext.declare(
          stmt.params.first.name.lexeme, stmt.params.first.name.line, stmt.params.first.name.column, _curFileName);
      //_declare(stmt.params.first.name.lexeme, stmt.params.first.name.line, stmt.params.first.name.column, define: true);
    } else {
      for (var param in stmt.params) {
        _curContext.declare(param.name.lexeme, param.name.line, param.name.column, _curFileName);
        //_declare(param.name.lexeme, param.name.line, param.name.column, define: true);
      }
    }
    _resolveBlock(stmt.definition);
    _curContext = save;
    //_endBlock();
    //_curFuncType = enclosingFunctionType;
  }

  void _resolveExpr(Expr expr) => expr.accept(this);
  void _resolveStmt(Stmt stmt) => stmt.accept(this);

  /// Null并没有任何变量需要解析，因此这里留空
  @override
  dynamic visitNullExpr(NullExpr expr) {}

  /// 字面量并没有任何变量需要解析，因此这里留空
  @override
  dynamic visitLiteralExpr(LiteralExpr expr) {}

  @override
  dynamic visitListExpr(ListExpr expr) {
    for (var item in expr.list) {
      _resolveExpr(item);
    }
  }

  @override
  dynamic visitMapExpr(MapExpr expr) {
    for (var key in expr.map.keys) {
      _resolveExpr(key);
      _resolveExpr(expr.map[key]);
    }
  }

  @override
  dynamic visitVarExpr(VarExpr expr) => _addExpr(expr, expr.name.lexeme);
  // if (_blocks.isNotEmpty && _blocks.last[expr.name] == false) {
  //   throw HSErr_Undefined(expr.name.lexeme, expr.line, expr.column, interpreter.curFileName);
  // }

  // _addLocal(expr, expr.name.lexeme);

  @override
  dynamic visitGroupExpr(GroupExpr expr) => _resolveExpr(expr.inner);

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
    //_addLocal(expr, expr.variable.lexeme);
    return null;
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
    if (stmt.isStatic) {
      //if (!stmt.isStatic) {
      if (stmt.initializer != null) {
        _resolveExpr(stmt.initializer);
        //_declare(stmt.name.lexeme, stmt.name.line, stmt.name.column, define: true);
      } else {
        //_define(stmt.name.lexeme);
      }
      _curContext.declare(stmt.name.lexeme, stmt.name.line, stmt.name.column, _curFileName);
    }
  }

  @override
  void visitExprStmt(ExprStmt stmt) => _resolveExpr(stmt.expr);

  @override
  void visitBlockStmt(BlockStmt stmt) {
    var save = _curContext;
    _curContext = interpreter.defineSpace(Namespace(closure: _curContext));
    //_beginBlock();
    _resolveBlock(stmt.block);
    _curContext = save;
    //_endBlock();
  }

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    //if (_curFuncType == _FunctionType.none) {
    if (_curContext is HS_Function) {
      if (stmt.expr != null) {
        if ((_curContext as HS_Function).funcStmt.functype == FuncStmtType.constructor //_FunctionType.constructor
            ) {
          throw HSErr_Unexpected(stmt.keyword.lexeme, stmt.keyword.line, stmt.keyword.column, _curFileName);
        }
        _resolveExpr(stmt.expr);
      }
    } else {
      throw HSErr_Unexpected(stmt.keyword.lexeme, stmt.keyword.line, stmt.keyword.column, _curFileName);
    }
    //}
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
  void visitFuncStmt(FuncStmt stmt) {
    _curContext.declare(stmt.name.lexeme, stmt.name.line, stmt.name.column, _curFileName);
    var funcobj = HS_Function(stmt.name.lexeme, stmt, closure: _curContext);
    _funcStmts[stmt] = funcobj;
  }

  @override
  void visitClassStmt(ClassStmt stmt) {
    var klass = HS_Class(stmt.name.lexeme);

    // 因为类本身就是一个命名空间，因此这里需要define而不是declare
    _curContext.define(stmt.name.lexeme, HS_Common.Class, stmt.name.line, stmt.name.column, interpreter, value: klass);

    var savedSpace = _curContext;
    _curContext = klass;

    for (var variable in stmt.variables) {
      if (variable.isStatic) {
        if (klass.contains(variable.name.lexeme)) {
          throw HSErr_Defined(variable.name.lexeme, variable.name.line, variable.name.column, _curFileName);
        }

        if (variable.initializer != null) {
          _resolveExpr(variable.initializer);
        }

        klass.declare(variable.name.lexeme, variable.name.line, variable.name.column, _curFileName);
      }
    }

    var savedFuncStmts = _funcStmts;
    _funcStmts = <FuncStmt, String>{};
    // 先注册函数名
    for (var method in stmt.methods) {
      if (klass.contains(method.name.lexeme)) {
        throw HSErr_Defined(method.name.lexeme, method.name.line, method.name.column, _curFileName);
      }

      if (!method.isStatic) {
        klass.declare(method.internalName, method.name.line, method.name.column, _curFileName);
        if ((method.internalName.startsWith(HS_Common.Getter) || method.internalName.startsWith(HS_Common.Setter)) &&
            !klass.contains(method.name.lexeme)) {
          klass.declare(method.name.lexeme, method.name.line, method.name.column, _curFileName);
        }
        _funcStmts[method] = klass.fullName + HS_Common.Dot + method.internalName;
      }
    }
    // 然后再解析函数定义
    for (var stmt in _funcStmts.keys) {
      _resolveFunction(stmt, _funcStmts[stmt]);
    }

    _funcStmts = savedFuncStmts;

    _curContext = savedSpace;
  }

  @override
  void visitThisExpr(ThisExpr expr) {
    if (_curContext.closure is! HS_Class) {
      throw HSErr_Unexpected(expr.keyword.lexeme, expr.line, expr.column, _curFileName);
    }

    _addExpr(expr, expr.keyword.lexeme);
  }
}
