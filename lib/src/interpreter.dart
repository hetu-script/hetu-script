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
  final _literals = <HSVal_Literal>[];

  /// 保存当前语句所在的命名空间
  Namespace _curSpace;

  /// 全局命名空间
  final _global = Namespace();

  /// external函数的空间
  final _external = Namespace();

  Context() {
    _curSpace = _global;
  }

  void addLocal(Expr expr, int distance) {
    _locals[expr] = distance;
  }

  /// 定义一个常量，然后返回数组下标
  /// 相同值的常量不会重复定义
  int addLiteral(HSVal_Literal literal) {
    for (var i = 0; i < _literals.length; ++i) {
      if (_literals[i].value == literal.value) {
        return i;
      }
    }

    _literals.add(literal);
    return _literals.length - 1;
  }

  void define(String name, HS_Value value) {
    if (_global.contains(name)) {
      throw HSErr_Defined(name);
    } else {
      _global.define(name, value.type, value: value);
    }
  }

  void bind(String name, Call function) {
    if (_global.contains(name)) {
      throw HSErr_Defined(name);
    } else {
      var func_obj = HS_Function(name, bindFunc: function);
      _global.define(name, HS_Common.Function, value: func_obj);
    }
  }

  /// 绑定外部函数
  void bindAll(Map<String, Call> bindMap) {
    if (bindMap != null) {
      for (var key in bindMap.keys) {
        bind(key, bindMap[key]);
      }
    }
  }

  void link(String name, Call function) {
    if (_external.contains(name)) {
      throw HSErr_Defined(name);
    } else {
      var func_obj = HS_Function(name, bindFunc: function);
      _external.define(name, HS_Common.Function, value: func_obj);
    }
  }

  /// 链接外部函数
  void linkAll(Map<String, Call> linkMap) {
    if (linkMap != null) {
      for (var key in linkMap.keys) {
        link(key, linkMap[key]);
      }
    }
  }

  HS_Value fetch(String name) => _global.fetch(name);

  HS_Value _getVar(String name, Expr expr) {
    var distance = _locals[expr];
    if (distance != null) {
      // 尝试获取当前环境中的本地变量
      return _curSpace.fetchAt(distance, name);
    } else {
      try {
        // 尝试获取当前实例中的类成员变量
        HS_Instance instance = _curSpace.fetch(HS_Common.This);
        return instance.get(name);
      } catch (e) {
        if ((e is HSErr_UndefinedMember) || (e is HSErr_Undefined)) {
          // 尝试获取全局变量
          return _global.fetch(name);
        } else {
          throw e;
        }
      }
    }
  }

  // HS_Value convert(dynamic value) {
  //   if (value is HS_Value) {
  //     return value;
  //   } else if (value is num) {
  //     return HSVal_Num(value);
  //   } else if (value is bool) {
  //     return HSVal_Bool(value);
  //   } else if (value is String) {
  //     return HSVal_String(value);
  //   } else {
  //     throw HSErr_Unsupport(value);
  //   }
  // }

  void interpreter(List<Stmt> statements,
      {bool commandLine = false, String invokeFunc = null, List<HS_Instance> args}) {
    for (var stmt in statements) {
      execute(stmt);
    }

    if ((!commandLine) && (invokeFunc != null)) {
      invoke(invokeFunc, args: args);
    }
  }

  void invoke(String name, {List<HS_Instance> args}) {
    var func = _global.fetch(name);
    if (func is HS_Function) {
      func.call(args ?? []);
    } else {
      throw HSErr_Undefined(name);
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
      case HS_Common.Subtract:
        {
          if (value is HSVal_Num) {
            return HSVal_Num(-value.value);
          } else {
            throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case HS_Common.Not:
        {
          if (value is HSVal_Bool) {
            return HSVal_Bool(!value.value);
          } else {
            throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      default:
        throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
        break;
    }
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    var left = (evaluate(expr.left) as HSVal_Literal).value;
    var right = (evaluate(expr.right) as HSVal_Literal).value;

    // TODO 操作符重载
    switch (expr.op.type) {
      case HS_Common.Or:
      case HS_Common.And:
        {
          if (left is bool) {
            if (right is bool) {
              if (expr.op.type == HS_Common.Or) {
                return HSVal_Bool(left || right);
              } else if (expr.op.type == HS_Common.And) {
                return HSVal_Bool(left && right);
              }
            } else {
              throw HSErr_UndefinedOperator(right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
            }
          } else {
            throw HSErr_UndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case HS_Common.Equal:
        return HSVal_Bool(left == right);
        break;
      case HS_Common.NotEqual:
        return HSVal_Bool(left != right);
        break;
      case HS_Common.Add:
      case HS_Common.Subtract:
        {
          if ((left is String) || (right is String)) {
            return HSVal_String(left + right);
          } else if ((left is num) && (right is num)) {
            if (expr.op.lexeme == HS_Common.Add) {
              return HSVal_Num(left + right);
            } else if (expr.op.lexeme == HS_Common.Subtract) {
              return HSVal_Num(left - right);
            }
          } else {
            throw HSErr_UndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      case HS_Common.Multiply:
      case HS_Common.Devide:
      case HS_Common.Modulo:
      case HS_Common.Greater:
      case HS_Common.GreaterOrEqual:
      case HS_Common.Lesser:
      case HS_Common.LesserOrEqual:
        {
          if (left is num) {
            if (right is num) {
              if (expr.op.type == HS_Common.Multiply) {
                return HSVal_Num(left * right);
              } else if (expr.op.type == HS_Common.Devide) {
                return HSVal_Num(left / right);
              } else if (expr.op.type == HS_Common.Modulo) {
                return HSVal_Num(left % right);
              } else if (expr.op.type == HS_Common.Greater) {
                return HSVal_Bool(left > right);
              } else if (expr.op.type == HS_Common.GreaterOrEqual) {
                return HSVal_Bool(left >= right);
              } else if (expr.op.type == HS_Common.Lesser) {
                return HSVal_Bool(left < right);
              } else if (expr.op.type == HS_Common.LesserOrEqual) {
                return HSVal_Bool(left <= right);
              }
            } else {
              throw HSErr_UndefinedOperator(right.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
            }
          } else {
            throw HSErr_UndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
          }
        }
        break;
      default:
        throw HSErr_UndefinedOperator(left.toString(), expr.op.lexeme, expr.op.line, expr.op.column);
        break;
    }
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    var callee = evaluate(expr.callee);
    var args = <HS_Instance>[];
    for (var arg in expr.args) {
      //var value = convert(evaluate(arg));
      var value = evaluate(arg);
      args.add(value);
    }

    if (callee is HS_Function) {
      if ((callee.arity >= 0) && (callee.arity != expr.args.length)) {
        throw HSErr_Arity(expr.args.length, callee.arity, expr.callee.line, expr.callee.column);
      } else if (callee.funcStmt != null) {
        for (var i = 0; i < callee.funcStmt.params.length; ++i) {
          var param_token = callee.funcStmt.params[i].typename;
          var arg = args[i];
          if ((param_token.lexeme != HS_Common.Dynamic) && (arg.type != param_token.lexeme)) {
            throw HSErr_ArgType(arg.type, param_token.lexeme, param_token.line, param_token.column);
          }
        }
      }

      if (!callee.isConstructor) {
        return callee.call(args);
      } else {
        //TODO命名构造函数
      }
    } else if (callee is HS_Class) {
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
      throw HSErr_Callable(callee.toString(), expr.callee.line, expr.callee.column);
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    //var value = convert(evaluate(expr.value));
    var value = evaluate(expr.value);

    var distance = _locals[expr];
    if (distance != null) {
      // 尝试设置当前环境中的本地变量
      _curSpace.assignAt(distance, expr.variable.lexeme, value);
    } else {
      try {
        // 尝试设置当前实例中的类成员变量
        HS_Instance instance = _curSpace.fetch(HS_Common.This);
        instance.set(expr.variable.lexeme, value);
      } catch (e) {
        if (e is HSErr_Undefined) {
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
    HS_Instance value;
    if (stmt.initializer != null) {
      //value = convert(evaluate(stmt.initializer));
      value = evaluate(stmt.initializer);
    }

    if (stmt.typename.lexeme == HS_Common.Dynamic) {
      _curSpace.define(stmt.varname.lexeme, stmt.typename.lexeme, value: value);
    } else if (stmt.typename.lexeme == HS_Common.Var) {
      // 如果用了var关键字，则从初始化表达式推断变量类型
      if (value != null) {
        _curSpace.define(stmt.varname.lexeme, value.type, value: value);
      } else {
        _curSpace.define(stmt.varname.lexeme, HS_Common.Dynamic);
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
    if (value is HSVal_Bool) {
      if (value.value) {
        execute(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        execute(stmt.elseBranch);
      }
    } else {
      throw HSErr_Condition(stmt.condition.line, stmt.condition.column);
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    var value = evaluate(stmt.condition);
    if (value is HSVal_Bool) {
      try {
        while ((value is HSVal_Bool) && (value.value)) {
          execute(stmt.loop);
          value = evaluate(stmt.condition);
        }
      } catch (error) {
        if (error is HS_Break) {
          return;
        } else {
          throw error;
        }
      }
    } else {
      throw HSErr_Condition(stmt.condition.line, stmt.condition.column);
    }
  }

  @override
  void visitBreakStmt(BreakStmt stmt) {
    throw HS_Break();
  }

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {}

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {}

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    var object = evaluate(expr.collection);
    if (object is HS_Instance) {
      return object.get(expr.key.lexeme);
    } else if (object is HS_Class) {
      return object.get(expr.key.lexeme);
    }

    throw HSErr_Get(object.toString(), expr.key.line, expr.key.column);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    HS_Instance object = evaluate(expr.collection);
    if (object is HS_Instance) {
      HS_Instance value = evaluate(expr.value);
      object.set(expr.key.lexeme, value);
      return value;
    }
  }

  @override
  void visitFuncStmt(FuncStmt stmt) {
    var function = HS_Function(stmt.name.lexeme, funcStmt: stmt, closure: _curSpace, isConstructor: false);
    _curSpace.define(stmt.name.lexeme, HS_Common.Function, value: function);
  }

  @override
  void visitExternFuncStmt(ExternFuncStmt stmt) {
    var externFunc = _external.fetch(stmt.name.lexeme);
    _curSpace.define(stmt.name.lexeme, HS_Common.Function, value: externFunc);
  }

  @override
  // 构造函数本身不注册为变量
  void visitConstructorStmt(ConstructorStmt stmt) {}

  @override
  void visitClassStmt(ClassStmt stmt) {
    HS_Class superClass;

    if ((stmt.superClass != null)) {
      superClass = evaluate(stmt.superClass);
      if (superClass is! HS_Class) {
        throw HSErr_Extends(superClass.name, stmt.superClass.line, stmt.superClass.column);
      }

      _curSpace = Namespace(_curSpace);
      _curSpace.define(HS_Common.Super, HS_Common.Class, value: superClass);
    }

    var methods = <String, HS_Function>{};
    for (var stmt in stmt.methods) {
      if (stmt is ExternFuncStmt) {
        var externFunc = _external.fetch(stmt.name.lexeme);
        methods[stmt.name.lexeme] = externFunc;
      } else {
        var func =
            HS_Function(stmt.name.lexeme, funcStmt: stmt, closure: _curSpace, isConstructor: stmt is ConstructorStmt);
        methods[stmt.name.lexeme] = func;
      }
    }

    var hetuClass =
        HS_Class(stmt.name.lexeme, superClassName: superClass?.name, decls: stmt.variables, methods: methods);

    // 在class中define static变量和函数

    if (superClass != null) {
      _curSpace = _curSpace.enclosing;
    }

    _curSpace.define(stmt.name.lexeme, HS_Common.Class, value: hetuClass);
  }
}
