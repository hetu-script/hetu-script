import 'errors.dart';
import 'common.dart';
import 'expression.dart';
import 'statement.dart';
import 'namespace.dart';
import 'class.dart';
import 'function.dart';

Context globalContext = Context();

/// 负责对语句列表进行最终解释执行
class Context implements ExprVisitor, StmtVisitor {
  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _locals = <Expr, int>{};

  ///
  final _literals = <Literal>[];

  /// 保存当前语句所在的命名空间
  Namespace _curSpace;

  /// 全局命名空间
  final _global = Namespace();

  Context() {
    _curSpace = _global;
  }

  void addLocal(Expr expr, int distance) {
    _locals[expr] = distance;
  }

  /// 定义一个常量，然后返回数组下标
  /// 相同值的常量不会重复定义
  int addLiteral(Literal literal) {
    for (var i = 0; i < _literals.length; ++i) {
      if (_literals[i].value == literal.value) {
        return i;
      }
    }

    _literals.add(literal);
    return _literals.length - 1;
  }

  void define(String name, Value value) {
    if (_global.contains(name)) {
      throw HetuErrorDefined(name);
    } else {
      _global.define(name, value.type, value: value);
    }
  }

  void bind(String name, Call function) {
    if (_global.contains(name)) {
      throw HetuErrorDefined(name);
    } else {
      var func_obj = Subroutine(name, extern: function);
      _global.define(name, Common.Function, value: func_obj);
    }
  }

  void bindAll(Map<String, Call> bindMap) {
    // 绑定外部函数
    if (bindMap != null) {
      for (var key in bindMap.keys) {
        bind(key, bindMap[key]);
      }
    }
  }

  Value fetch(String name) => _global.fetch(name);

  Value _getVar(String name, Expr expr) {
    var distance = _locals[expr];
    if (distance != null) {
      // 尝试获取当前环境中的本地变量
      return _curSpace.fetchAt(distance, name);
    } else {
      try {
        // 尝试获取当前实例中的类成员变量
        Instance instance = _curSpace.fetch(Common.This);
        return instance.get(name);
      } catch (e) {
        if ((e is HetuErrorUndefinedMember) || (e is HetuErrorUndefined)) {
          // 尝试获取全局变量
          return _global.fetch(name);
        } else {
          throw e;
        }
      }
    }
  }

  void interpreter(List<Stmt> statements, {bool commandLine = false, String invokeFunc = null, List<Instance> args}) {
    for (var stmt in statements) {
      execute(stmt);
    }

    if ((!commandLine) && (invokeFunc != null)) {
      invoke(invokeFunc, args: args);
    }
  }

  void invoke(String name, {List<Instance> args}) {
    var func = _global.fetch(name);
    if (func is Subroutine) {
      func.call(args ?? []);
    } else {
      throw HetuErrorUndefined(name);
    }
  }

  void executeBlock(List<Stmt> statements, Namespace environment) {
    var save = _curSpace;
    try {
      _curSpace = environment;
      for (var stmt in statements) {
        execute(stmt);
      }
    } finally {
      _curSpace = save;
    }
  }

  dynamic execute(Stmt stmt) => stmt.accept(this);

  dynamic evaluate(Expr expr) => expr.accept(this);

  @override
  dynamic visitLiteralExpr(LiteralExpr expr) {
    return _literals[expr.constantIndex];
  }

  @override
  dynamic visitVarExpr(VarExpr expr) => _getVar(expr.name.lexeme, expr);

  @override
  dynamic visitGroupExpr(GroupExpr expr) => evaluate(expr.expr);

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    var value = evaluate(expr.value);

    switch (expr.op.lexeme) {
      case Common.Subtract:
        {
          if (value is num) {
            return -value;
          } else {
            throw HetuErrorUndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case Common.Not:
        {
          if (value is bool) {
            return !value;
          } else {
            throw HetuErrorUndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      default:
        throw HetuErrorUndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
        break;
    }
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    var left = evaluate(expr.left);
    var right = evaluate(expr.right);

    // TODO 操作符重载
    switch (expr.op.type) {
      case Common.Or:
      case Common.And:
        {
          if (left is bool) {
            if (right is bool) {
              if (expr.op.type == Common.Or) {
                return left || right;
              } else if (expr.op.type == Common.And) {
                return left && right;
              }
            } else {
              throw HetuErrorUndefinedOperator(right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
            }
          } else {
            throw HetuErrorUndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case Common.Equal:
        return left == right;
        break;
      case Common.NotEqual:
        return left != right;
        break;
      case Common.Add:
      case Common.Subtract:
        {
          if ((left is String) || (right is String)) {
            return left + right;
          } else if ((left is num) && (right is num)) {
            if (expr.op.lexeme == Common.Add) {
              return left + right;
            } else if (expr.op.lexeme == Common.Subtract) {
              return left - right;
            }
          } else {
            throw HetuErrorUndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case Common.Multiply:
      case Common.Devide:
      case Common.Modulo:
      case Common.Greater:
      case Common.GreaterOrEqual:
      case Common.Lesser:
      case Common.LesserOrEqual:
        {
          if (left is num) {
            if (right is num) {
              if (expr.op.type == Common.Multiply) {
                return left * right;
              } else if (expr.op.type == Common.Devide) {
                return left / right;
              } else if (expr.op.type == Common.Modulo) {
                return left % right;
              } else if (expr.op.type == Common.Greater) {
                return left > right;
              } else if (expr.op.type == Common.GreaterOrEqual) {
                return left >= right;
              } else if (expr.op.type == Common.Lesser) {
                return left < right;
              } else if (expr.op.type == Common.LesserOrEqual) {
                return left <= right;
              }
            } else {
              throw HetuErrorUndefinedOperator(right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
            }
          } else {
            throw HetuErrorUndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      default:
        throw HetuErrorUndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
        break;
    }
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    var callee = evaluate(expr.callee);
    var args = <Instance>[];
    for (var arg in expr.args) {
      var value = evaluate(arg);
      if (value is num) {
        value = LNum(value);
      } else if (value is bool) {
        value = LBool(value);
      } else if (value is String) {
        value = LString(value);
      }
      args.add(evaluate(arg));
    }

    if (callee is Subroutine) {
      if ((callee.arity >= 0) && (callee.arity != expr.args.length)) {
        throw HetuErrorArity(expr.args.length, callee.arity, expr.callee.line, expr.callee.column);
      } else if (callee.funcStmt != null) {
        for (var i = 0; i < callee.funcStmt.params.length; ++i) {
          var param_token = callee.funcStmt.params[i].typename;
          var arg = args[i];
          if (arg.type != param_token.lexeme) {
            throw HetuErrorArgType(arg.type, param_token.lexeme, param_token.line, param_token.column);
          }
        }
      }

      if (!callee.isConstructor) {
        return callee.call(args);
      } else {
        //TODO命名构造函数
      }
    } else if (callee is Class) {
      // for (var i = 0; i < callee.varStmts.length; ++i) {
      //   var param_type_token = callee.varStmts[i].typename;
      //   var arg = args[i];
      //   if (arg.type != param_type_token.lexeme) {
      //     throw HetuError(
      //         '(Interpreter) The argument type "${arg.type}" can\'t be assigned to the parameter type "${param_type_token.lexeme}".'
      //         ' [${param_type_token.line}, ${param_type_token.column}].');
      //   }
      // }

      return callee.createInstance(args: args);
    } else {
      throw HetuErrorCallable(callee.toString(), expr.callee.line, expr.callee.column);
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    var value = evaluate(expr.value);

    var distance = _locals[expr];
    if (distance != null) {
      // 尝试设置当前环境中的本地变量
      _curSpace.assignAt(distance, expr.variable.lexeme, value);
    } else {
      try {
        // 尝试设置当前实例中的类成员变量
        Instance instance = _curSpace.fetch(Common.This);
        instance.set(expr.variable.lexeme, value);
      } catch (e) {
        if (e is HetuErrorUndefined) {
          // 尝试设置全局变量
          _global.assign(expr.variable.lexeme, value);
        } else {
          throw e;
        }
      }
    }

    // 返回右值
    return value;
  }

  @override
  dynamic visitThisExpr(ThisExpr expr) {
    return _getVar(expr.keyword.lexeme, expr);
  }

  @override
  void visitVarStmt(VarStmt stmt) {
    Instance value;
    if (stmt.initializer != null) {
      value = evaluate(stmt.initializer);
    }

    if (stmt.typename.lexeme == Common.Dynamic) {
      _curSpace.define(stmt.varname.lexeme, stmt.typename.lexeme, value: value);
    } else if (stmt.typename.lexeme == Common.Var) {
      // 如果用了var关键字，则从初始化表达式推断变量类型
      if (value != null) {
        _curSpace.define(stmt.varname.lexeme, value.type, value: value);
      } else {
        _curSpace.define(stmt.varname.lexeme, Common.Dynamic);
      }
    } else {
      // 接下来define函数会判断类型是否符合声明
      _curSpace.define(stmt.varname.lexeme, stmt.typename.lexeme, value: value);
    }
  }

  @override
  void visitExprStmt(ExprStmt stmt) => evaluate(stmt.expr);

  @override
  void visitBlockStmt(BlockStmt stmt) => executeBlock(stmt.block, Namespace(_curSpace));

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    if (stmt.expr != null) {
      throw evaluate(stmt.expr);
    }
    throw null;
  }

  @override
  void visitIfStmt(IfStmt stmt) {
    var value = evaluate(stmt.condition);
    if (value is bool) {
      if (value) {
        execute(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        execute(stmt.elseBranch);
      }
    } else {
      throw HetuErrorCondition(stmt.condition.line, stmt.condition.column);
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    var value = evaluate(stmt.condition);
    if (value is bool) {
      try {
        while ((value is bool) && (value)) {
          execute(stmt.loop);
          value = evaluate(stmt.condition);
        }
      } catch (error) {
        if (error is HetuBreak) {
          return;
        } else {
          throw error;
        }
      }
    } else {
      throw HetuErrorCondition(stmt.condition.line, stmt.condition.column);
    }
  }

  @override
  void visitBreakStmt(BreakStmt stmt) {
    throw HetuBreak();
  }

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {}

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {}

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    var object = evaluate(expr.collection);
    if (object is Instance) {
      return object.get(expr.key.lexeme);
    } else if (object is Class) {
      return object.get(expr.key.lexeme);
    }

    throw HetuErrorGet(object.toString(), expr.key.line, expr.key.column);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    Instance object = evaluate(expr.collection);
    if (object is Instance) {
      Instance value = evaluate(expr.value);
      object.set(expr.key.lexeme, value);
      return value;
    }
  }

  @override
  void visitFuncStmt(FuncStmt stmt) {
    var function = Subroutine(stmt.name.lexeme, funcStmt: stmt, closure: _curSpace, isConstructor: false);
    _curSpace.define(stmt.name.lexeme, Common.Function, value: function);
  }

  @override
  // 构造函数本身不注册为变量
  void visitConstructorStmt(ConstructorStmt stmt) {}

  @override
  void visitClassStmt(ClassStmt stmt) {
    Class superClass;

    if ((stmt.superClass != null)) {
      superClass = evaluate(stmt.superClass);
      if (superClass is! Class) {
        throw HetuErrorExtends(superClass.name, stmt.superClass.line, stmt.superClass.column);
      }

      _curSpace = Namespace(_curSpace);
      _curSpace.define(Common.Super, Common.Class, value: superClass);
    }

    var methods = <String, Subroutine>{};
    for (var stmt in stmt.methods) {
      if (stmt is FuncStmt) {
        var function =
            Subroutine(stmt.name.lexeme, funcStmt: stmt, closure: _curSpace, isConstructor: stmt is ConstructorStmt);
        methods[stmt.name.lexeme] = function;
      }
    }

    var hetuClass = Class(stmt.name.lexeme, superClass: superClass, decls: stmt.variables, methods: methods);

    // 在class中define static变量和函数

    _curSpace.define(stmt.name.lexeme, Common.Class, value: hetuClass);

    if (superClass != null) {
      _curSpace = _curSpace.enclosing;
    }
  }
}
