import 'errors.dart';
import 'constants.dart';
import 'token.dart';
import 'expression.dart';
import 'statement.dart';
import 'environment.dart';
import 'object.dart';

Interpreter globalInterpreter = Interpreter();

/// 负责对语句列表进行最终解释执行
class Interpreter implements ExprVisitor, StmtVisitor {
  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _locals = <Expr, int>{};

  /// 当前模块变量
  Environment _environment;

  /// 全局变量
  final _globals = Environment();

  Interpreter() {
    _environment = _globals;
  }

  void bindAll(Map<String, HetuFunctionCall> bindMap) {
    // 绑定外部函数
    if (bindMap != null) {
      for (var key in bindMap.keys) {
        bind(key, bindMap[key]);
      }
    }
  }

  void bind(String name, HetuFunctionCall function) {
    if (_globals.contains(name)) {
      throw HetuError('(Interpreter) Function [${name}] is already defined.');
    } else {
      if (function == null) {
        throw HetuError('(Interpreter) Function [${name}] is null.');
      } else {
        var func_obj = HetuFunction(name, extern: function);
        _globals.define(name, Constants.Function, value: func_obj);
      }
    }
  }

  dynamic _getVar(Token varname, Expr expr) {
    var distance = _locals[expr];
    if (distance != null) {
      // 尝试获取当前环境中的本地变量
      return _environment.searchByToken(distance, varname);
    } else {
      try {
        // 尝试获取当前实例中的类成员变量
        HetuInstance instance = _environment.getByName(Constants.This);
        return instance.memberGetByToken(varname);
      } catch (e) {
        if (e is HetuErrorSymbolNotFound) {
          // 尝试获取全局变量
          return _globals.getByToken(varname);
        } else {
          throw e;
        }
      }
    }
  }

  void interpreter(List<Stmt> statements, Map<Expr, int> locals,
      {bool commandLine = false, String invokeFunc = null, List<dynamic> args}) {
    if (locals != null) {
      _locals.addAll(locals);
    }

    for (var stmt in statements) {
      execute(stmt);
    }

    if ((!commandLine) && (invokeFunc != null)) {
      invoke(invokeFunc, args: args);
    }
  }

  void invoke(String name, {List<HetuObject> args}) {
    var func = _globals.getByName(name);
    if (func is HetuFunction) {
      func.call(args ?? []);
    } else {
      throw HetuError('(Interpreter) Could not find function "${name}".');
    }
  }

  void executeBlock(List<Stmt> statements, Environment environment) {
    var save = _environment;
    try {
      _environment = environment;
      for (var stmt in statements) {
        execute(stmt);
      }
    } finally {
      _environment = save;
    }
  }

  dynamic execute(Stmt stmt) => stmt.accept(this);

  dynamic evaluate(Expr expr) => expr.accept(this);

  @override
  dynamic visitLiteralExpr(LiteralExpr expr) {
    HetuObject result = HetuObject.Null;
    if (expr.value.literal is num) {
      result = HetuNum(expr.value.literal);
    } else if (expr.value.literal is bool) {
      result = HetuBool(expr.value.literal);
    } else if (expr.value.literal is String) {
      result = HetuString(expr.value.literal);
    }
    return result;
  }

  @override
  dynamic visitVarExpr(VarExpr expr) => _getVar(expr.name, expr);

  @override
  dynamic visitGroupExpr(GroupExpr expr) => evaluate(expr.expr);

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    HetuObject result = HetuObject.Null;
    HetuObject value = evaluate(expr.value);

    switch (expr.op.text) {
      case Constants.Subtract:
        {
          if (value is HetuNum) {
            result = HetuNum(-value.literal);
          } else {
            throw HetuError('(Interpreter) Undefined negetive operator [${expr.op.text}] on [${value}].'
                ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
          }
        }
        break;
      case Constants.Not:
        {
          if (value is HetuBool) {
            result = HetuBool(!value.literal);
          } else {
            throw HetuError('(Interpreter) Undefined logical not operator [${expr.op.text}] on [${value}].'
                ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
          }
        }
        break;
      default:
        throw HetuError(
            '(Environment) Unknown unary operator [${value}]. [${expr.op.lineNumber}, ${expr.op.colNumber}].');
        break;
    }

    return result;
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    HetuObject result = HetuObject.Null;
    HetuObject left = evaluate(expr.left);
    HetuObject right = evaluate(expr.right);

    // TODO 操作符重载??
    switch (expr.op.type) {
      case Constants.Or:
      case Constants.And:
        {
          if (left is HetuBool) {
            if (right is HetuBool) {
              if (expr.op.type == Constants.Or) {
                result = HetuBool(left.literal || right.literal);
              } else if (expr.op.type == Constants.And) {
                result = HetuBool(left.literal && right.literal);
              }
            } else {
              throw HetuError('(Interpreter) Undefined logical operator [${expr.op.text}] on [${left}] and [${right}].'
                  ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
            }
          } else {
            throw HetuError('(Interpreter) Undefined logical operator [${expr.op.text}] on [${left}] and [${right}].'
                ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
          }
        }
        break;
      case Constants.Equal:
        result = HetuBool(left == right);
        break;
      case Constants.NotEqual:
        result = HetuBool(left != right);
        break;
      case Constants.Add:
      case Constants.Subtract:
        {
          if ((left is HetuString) || (right is HetuString)) {
            result = HetuString(left.toString() + right.toString());
          } else if ((left is HetuNum) && (right is HetuNum)) {
            if (expr.op.text == Constants.Add) {
              result = HetuNum(left.literal + right.literal);
            } else if (expr.op.text == Constants.Subtract) {
              result = HetuNum(left.literal - right.literal);
            }
          } else {
            throw HetuError('(Interpreter) Undefined additive operator [${expr.op.text}] on [${left}] and [${right}].'
                ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
          }
        }
        break;
      case Constants.Multiply:
      case Constants.Devide:
      case Constants.Modulo:
      case Constants.Greater:
      case Constants.GreaterOrEqual:
      case Constants.Lesser:
      case Constants.LesserOrEqual:
        {
          if (left is HetuNum) {
            if (right is HetuNum) {
              if (expr.op.type == Constants.Multiply) {
                result = HetuNum(left.literal * right.literal);
              } else if (expr.op.type == Constants.Devide) {
                result = HetuNum(left.literal / right.literal);
              } else if (expr.op.type == Constants.Modulo) {
                result = HetuNum(left.literal % right.literal);
              } else if (expr.op.type == Constants.Greater) {
                result = HetuBool(left.literal > right.literal);
              } else if (expr.op.type == Constants.GreaterOrEqual) {
                result = HetuBool(left.literal >= right.literal);
              } else if (expr.op.type == Constants.Lesser) {
                result = HetuBool(left.literal < right.literal);
              } else if (expr.op.type == Constants.LesserOrEqual) {
                result = HetuBool(left.literal <= right.literal);
              }
            } else {
              throw HetuError(
                  '(Interpreter) Undefined multipicative operator [${expr.op.text}] on [${left}] and [${right}].'
                  ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
            }
          } else {
            throw HetuError(
                '(Interpreter) Undefined multipicative operator [${expr.op.text}] on [${left}] and [${right}].'
                ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
          }
        }
        break;
      default:
        throw HetuError('(Interpreter) Unknown binary operator [${expr.op.text}].'
            ' [${expr.op.lineNumber}, ${expr.op.colNumber}].');
        break;
    }

    return result;
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    HetuObject callee = evaluate(expr.callee);
    HetuObject result = HetuObject.Null;
    var args = <HetuObject>[];
    for (var arg in expr.args) {
      args.add(evaluate(arg));
    }

    if (callee is HetuFunction) {
      if ((callee.arity >= 0) && (callee.arity != expr.args.length)) {
        throw HetuError(
            '(Interpreter) Number of arguments (${expr.args.length}) doesn\'t match the parameters (${callee.arity}). '
            ' [${expr.callee.lineNumber}, ${expr.callee.colNumber}].');
      } else if (callee.funcStmt != null) {
        for (var i = 0; i < callee.funcStmt.params.length; ++i) {
          var param_token = callee.funcStmt.params[i].typename;
          var arg = args[i];
          if (arg.type != param_token.text) {
            throw HetuError(
                '(Interpreter) The argument type "${arg.type}" can\'t be assigned to the parameter type "${param_token.text}".'
                ' [${param_token.lineNumber}, ${param_token.colNumber}].');
          }
        }
      }

      if (!callee.isConstructor) {
        result = callee.call(args);
      } else {
        //TODO命名构造函数
      }
    } else if (callee is HetuClass) {
      // for (var i = 0; i < callee.varStmts.length; ++i) {
      //   var param_type_token = callee.varStmts[i].typename;
      //   var arg = args[i];
      //   if (arg.type != param_type_token.text) {
      //     throw HetuError(
      //         '(Interpreter) The argument type "${arg.type}" can\'t be assigned to the parameter type "${param_type_token.text}".'
      //         ' [${param_type_token.lineNumber}, ${param_type_token.colNumber}].');
      //   }
      // }

      result = callee.getInstance(args);
    } else {
      throw HetuError('(Interpreter) Object [${callee}] is not callable.'
          ' [${expr.callee.lineNumber}, ${expr.callee.colNumber}].');
    }

    return result;
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    var value = evaluate(expr.value);

    var distance = _locals[expr];
    if (distance != null) {
      // 尝试设置当前环境中的本地变量
      _environment.assignAt(distance, expr.variable, value);
    } else {
      try {
        // 尝试设置当前实例中的类成员变量
        HetuInstance instance = _environment.getByName(Constants.This);
        instance.variableSet(expr.variable, value);
      } catch (e) {
        if (e is HetuErrorSymbolNotFound) {
          // 尝试设置全局变量
          _globals.assign(expr.variable, value);
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
    return _getVar(expr.keyword, expr);
  }

  @override
  void visitVarStmt(VarStmt stmt) {
    HetuObject value;
    if (stmt.initializer != null) {
      value = evaluate(stmt.initializer);
      if (value is HetuNull) {
        HetuError.add('(Interpreter) Don\'t explicitly initialize variables to null.'
            ' [${stmt.varname.lineNumber}, ${stmt.varname.colNumber}].');
      }
    }

    if (stmt.typename.text == Constants.Dynamic) {
      _environment.declare(stmt.varname, stmt.typename.text, value: value);
    } else if (stmt.typename.text == Constants.Var) {
      // 如果用了var关键字，则从初始化表达式推断变量类型
      if (value != null) {
        _environment.declare(stmt.varname, value.type, value: value);
      } else {
        _environment.declare(stmt.varname, Constants.Dynamic);
      }
    } else {
      if (value != null) {
        _environment.declare(stmt.varname, stmt.typename.text, value: value);
      } else {
        _environment.declare(stmt.varname, stmt.typename.text);
      }
    }
  }

  @override
  void visitExprStmt(ExprStmt stmt) => evaluate(stmt.expr);

  @override
  void visitBlockStmt(BlockStmt stmt) => executeBlock(stmt.block, Environment.enclose(_environment));

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    HetuObject value = HetuObject.Null;
    if (stmt.expr != null) {
      value = evaluate(stmt.expr);
    }
    throw value;
  }

  @override
  void visitIfStmt(IfStmt stmt) {
    HetuBool value = evaluate(stmt.condition);
    if (value != null) {
      if (value.literal) {
        execute(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        execute(stmt.elseBranch);
      }
    } else {
      throw HetuError('(Interpreter) Condition expression must evaluate to type "bool".'
          ' [${stmt.condition.lineNumber}, ${stmt.condition.colNumber}].');
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    HetuBool value = evaluate(stmt.condition);
    if (value != null) {
      try {
        while ((value != null) && (value.literal)) {
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
      throw HetuError('(Interpreter) Condition expression must evaluate to type "bool".'
          ' [${stmt.condition.lineNumber}, ${stmt.condition.colNumber}].');
    }
  }

  @override
  void visitBreakStmt(BreakStmt stmt) {
    throw HetuBreak();
  }

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    HetuObject object = evaluate(expr.collection);
    if (object is HetuInstance) {
      return object.memberGetByToken(expr.key);
    } else if (object is HetuClass) {
      return object.getMethodByToken(expr.key);
    }

    throw HetuError('(Interpreter) [${object}] is not a collection or object.'
        ' [${expr.key.lineNumber}, ${expr.key.colNumber}].');
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    HetuObject object = evaluate(expr.collection);
    if (object is HetuInstance) {
      HetuObject value = evaluate(expr.value);
      object.variableSet(expr.key, value);
      return value;
    }
  }

  @override
  void visitFuncStmt(FuncStmt stmt) {
    var function = HetuFunction(stmt.name.text, funcStmt: stmt, closure: _environment, isConstructor: false);
    _environment.declare(stmt.name, Constants.Function, value: function);
  }

  @override
  // 构造函数本身不注册为变量
  void visitConstructorStmt(ConstructorStmt stmt) {}

  @override
  void visitClassStmt(ClassStmt stmt) {
    HetuClass superClass = null;

    if (stmt.superClass != null) {
      superClass = evaluate(stmt.superClass);
      if (superClass is! HetuClass) {
        throw HetuError('(Interpreter) [${superClass.name}] is not a classname.'
            ' [${stmt.superClass.lineNumber}, ${stmt.superClass.colNumber}].');
      }

      _environment = Environment.enclose(_environment);
      _environment.define(Constants.Super, Constants.Class, value: superClass);
    }

    var methods = <String, HetuFunction>{};
    for (var stmt in stmt.methods) {
      if (stmt is FuncStmt) {
        var function =
            HetuFunction(stmt.name.text, funcStmt: stmt, closure: _environment, isConstructor: stmt is ConstructorStmt);
        methods[stmt.name.text] = function;
      }
    }

    var hetuClass = HetuClass(stmt.name.text, superClass, stmt.variables, methods);

    _environment.declare(stmt.name, Constants.Class, value: hetuClass);

    if (superClass != null) {
      _environment = _environment.enclosing;
    }
  }
}
