import 'dart:io';

import 'package:path/path.dart' as path;

import 'errors.dart';
import 'common.dart';
import 'expression.dart';
import 'statement.dart';
import 'namespace.dart';
import 'class.dart';
import 'function.dart';
import 'buildin.dart';
import 'lexer.dart';
import 'parser.dart';
import 'resolver.dart';

/// 负责对语句列表进行最终解释执行
class Interpreter implements ExprVisitor, StmtVisitor {
  static String _sdkDir;
  String workingDir;

  var _evaledFiles = <String>[];

  final global = Namespace(name: HS_Common.Global);
  final extern = Namespace(name: HS_Common.Extern);

  /// 全局命名空间
  final Map<String, Namespace> _spaces = {};

  Namespace getSpace(String fullName, int line, int column, String fileName, {Namespace closure}) {
    if (!_spaces.containsKey(fullName)) {
      _spaces[fullName] = Namespace(name: fullName.split('.').last, fullName: fullName, closure: closure);
    }
    return _spaces[fullName];
  }

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  //final _locals = <Expr, int>{};

  final _varPos = <Expr, String>{};

  /// 常量表
  final _constants = <dynamic>[];

  /// 当前语句所在的命名空间
  Namespace curContext;
  String _curFileName;
  String get curFileName => _curFileName;

  Interpreter() {
    _spaces.addAll({
      HS_Common.Global: global,
      HS_Common.Extern: extern,
    });
  }

  void init({
    String hetuSdkDir,
    String workingDir,
    String language = 'enUS',
    Map<String, HS_External> bindMap,
    Map<String, HS_External> linkMap,
  }) {
    try {
      _sdkDir = hetuSdkDir ?? 'hetu_core';
      this.workingDir = workingDir ?? path.current;

      // 必须在绑定函数前加载基础类Object和Function，因为函数本身也是对象
      curContext = global;
      print('Hetu: Loading core library.');
      eval(HS_Buildin.coreLib, 'core.ht');

      // 绑定外部函数
      linkAll(HS_Buildin.linkmap);
      linkAll(linkMap);

      // 载入基础库
      evalf(path.join(hetuSdkDir, 'value.ht'));
      evalf(path.join(hetuSdkDir, 'system.ht'));
      evalf(path.join(hetuSdkDir, 'console.ht'));
    } catch (e) {
      stdout.write('\x1B[32m');
      print(e);
      print('Hetu init failed!');
      stdout.write('\x1B[m');
    }
  }

  void eval(String script, String fileName,
      {String libName = HS_Common.Global,
      ParseStyle style = ParseStyle.library,
      String invokeFunc = null,
      List<dynamic> args}) {
    if ((libName != null) && (libName != HS_Common.Global)) {
      curContext = Namespace(name: libName);
    }
    final _lexer = Lexer();
    final _parser = Parser(this);
    final _resolver = Resolver(this);
    var tokens = _lexer.lex(script);
    var statements = _parser.parse(tokens, fileName, style: style);
    _resolver.resolve(statements, curContext, fileName);
    for (var stmt in statements) {
      evaluateStmt(stmt);
    }
    if ((style != ParseStyle.commandLine) && (invokeFunc != null)) {
      invoke(invokeFunc, args: args);
    }
  }

  /// 解析文件
  void evalf(String filepath,
      {String libName = HS_Common.Global,
      ParseStyle style = ParseStyle.library,
      String invokeFunc = null,
      List<dynamic> args}) {
    _curFileName = path.absolute(filepath);
    if (!_evaledFiles.contains(curFileName)) {
      print('Hetu: Loading $filepath...');
      _evaledFiles.add(curFileName);

      eval(File(curFileName).readAsStringSync(), curFileName,
          libName: libName, style: style, invokeFunc: invokeFunc, args: args);
    }
    _curFileName = null;
  }

  /// 解析目录下所有文件
  void evald(String dir, {ParseStyle style = ParseStyle.library, String invokeFunc = null, List<dynamic> args}) {
    var _dir = Directory(dir);
    var filelist = _dir.listSync();
    for (var file in filelist) {
      if (file is File) evalf(file.path);
    }
  }

  /// 解析命令行
  dynamic evalc(String input) {
    HS_Error.clear();
    try {
      final _lexer = Lexer();
      final _parser = Parser(this);
      var tokens = _lexer.lex(input, commandLine: true);
      var statements = _parser.parse(tokens, null, style: ParseStyle.commandLine);
      return executeBlock(statements, curContext);
    } catch (e) {
      print(e);
    } finally {
      HS_Error.output();
    }
  }

  // void addLocal(Expr expr, int distance) {
  //   _locals[expr] = distance;
  // }

  void addVarPos(Expr expr, String fullName) {
    _varPos[expr] = fullName;
  }

  /// 定义一个常量，然后返回数组下标
  /// 相同值的常量不会重复定义
  int addLiteral(dynamic literal) {
    var index = _constants.indexOf(literal);
    if (index == -1) {
      index = _constants.length;
      _constants.add(literal);
      return index;
    } else {
      return index;
    }
  }

  /// 链接外部函数，链接时必须在河图中存在一个函数声明
  ///
  /// 此种形式的外部函数通常用于需要进行参数类型判断的情况
  void link(String name, HS_External function) {
    if (extern.contains(name)) {
      throw HSErr_Defined(name, null, null, curFileName);
    } else {
      extern.define(name, HS_Common.Dynamic, null, null, this, value: function);
    }
  }

  void linkAll(Map<String, HS_External> linkMap) {
    if (linkMap != null) {
      for (var key in linkMap.keys) {
        link(key, linkMap[key]);
      }
    }
  }

  dynamic _getVar(String name, Expr expr) {
    var full_name = _varPos[expr];
    if (full_name != null) {
      // 尝试获取当前环境中的本地变量
      return _spaces[full_name].fetch(name, expr.line, expr.column, this, from: curContext.fullName, recursive: false);
    }

    return curContext.fetch(name, expr.line, expr.column, this, from: curContext.fullName, recursive: true);
  }

  dynamic unwrap(dynamic value, int line, int column, String fileName) {
    if (value is HS_Value) {
      return value;
    } else if (value is num) {
      return HSVal_Num(value, line, column, this);
    } else if (value is bool) {
      return HSVal_Bool(value, line, column, this);
    } else if (value is String) {
      return HSVal_String(value, line, column, this);
    } else {
      return value;
    }
  }

  // void interpreter(List<Stmt> statements, {bool commandLine = false, String invokeFunc = null, List<dynamic> args}) {
  //   for (var stmt in statements) {
  //     evaluateStmt(stmt);
  //   }

  //   if ((!commandLine) && (invokeFunc != null)) {
  //     invoke(invokeFunc, args: args);
  //   }
  // }

  dynamic invoke(String name, {String classname, List<dynamic> args}) {
    HS_Error.clear();
    try {
      if (classname == null) {
        var func = global.fetch(name, null, null, this, recursive: false);
        if (func is HS_Function) {
          return func.call(this, null, null, args ?? []);
        } else {
          throw HSErr_Undefined(name, null, null, curFileName);
        }
      } else {
        var klass = global.fetch(classname, null, null, this, recursive: false);
        if (klass is HS_Class) {
          // 只能调用公共函数
          var func = klass.fetch(name, null, null, this, recursive: false);
          if (func is HS_Function) {
            return func.call(this, null, null, args ?? []);
          } else {
            throw HSErr_Callable(name, null, null, curFileName);
          }
        } else {
          throw HSErr_Undefined(classname, null, null, curFileName);
        }
      }
    } catch (e) {
      print(e);
    } finally {
      HS_Error.output();
    }
  }

  void executeBlock(List<Stmt> statements, Namespace environment) {
    var saved_context = curContext;

    try {
      curContext = environment;
      for (var stmt in statements) {
        evaluateStmt(stmt);
      }
    } finally {
      curContext = saved_context;
    }
  }

  dynamic evaluateStmt(Stmt stmt) => stmt.accept(this);

  //dynamic evaluateExpr(Expr expr) => unwrap(expr.accept(this));
  dynamic evaluateExpr(Expr expr) => expr.accept(this);

  @override
  dynamic visitNullExpr(NullExpr expr) => null;

  @override
  dynamic visitLiteralExpr(LiteralExpr expr) => _constants[expr.constantIndex];

  @override
  dynamic visitListExpr(ListExpr expr) {
    var list = [];
    for (var item in expr.list) {
      list.add(evaluateExpr(item));
    }
    return list;
  }

  @override
  dynamic visitMapExpr(MapExpr expr) {
    var map = {};
    for (var key_expr in expr.map.keys) {
      var key = evaluateExpr(key_expr);
      var value = evaluateExpr(expr.map[key_expr]);
      map[key] = value;
    }
    return map;
  }

  @override
  dynamic visitVarExpr(VarExpr expr) => _getVar(expr.name.lexeme, expr);

  @override
  dynamic visitGroupExpr(GroupExpr expr) => evaluateExpr(expr.inner);

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    var value = evaluateExpr(expr.value);

    switch (expr.op.lexeme) {
      case HS_Common.Subtract:
        {
          if (value is num) {
            return -value;
          } else {
            throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
          }
        }
        break;
      case HS_Common.Not:
        {
          if (value is bool) {
            return !value;
          } else {
            throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
          }
        }
        break;
      default:
        throw HSErr_UndefinedOperator(value.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
        break;
    }
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    var left = evaluateExpr(expr.left);
    var right;
    if (expr.op == HS_Common.And) {
      if (left is bool) {
        // 如果逻辑和操作的左操作数是假，则直接返回，不再判断后面的值
        if (!left) {
          return false;
        } else {
          right = evaluateExpr(expr.right);
          if (right is bool) {
            return left && right;
          } else {
            throw HSErr_UndefinedBinaryOperator(
                left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
          }
        }
      } else {
        throw HSErr_UndefinedBinaryOperator(
            left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
      }
    } else {
      right = evaluateExpr(expr.right);

      // TODO 操作符重载
      switch (expr.op.type) {
        case HS_Common.Or:
          {
            if (left is bool) {
              if (right is bool) {
                return left || right;
              } else {
                throw HSErr_UndefinedBinaryOperator(
                    left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
              }
            } else {
              throw HSErr_UndefinedBinaryOperator(
                  left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
            }
          }
          break;
        case HS_Common.Equal:
          return left == right;
          break;
        case HS_Common.NotEqual:
          return left != right;
          break;
        case HS_Common.Add:
        case HS_Common.Subtract:
          {
            if ((left is String) && (right is String)) {
              return left + right;
            } else if ((left is num) && (right is num)) {
              if (expr.op.lexeme == HS_Common.Add) {
                return left + right;
              } else if (expr.op.lexeme == HS_Common.Subtract) {
                return left - right;
              }
            } else {
              throw HSErr_UndefinedBinaryOperator(
                  left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
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
        case HS_Common.Is:
          {
            if ((expr.op == HS_Common.Is) && (right is HS_Class)) {
              return HS_TypeOf(left) == right.name;
            } else if (left is num) {
              if (right is num) {
                if (expr.op == HS_Common.Multiply) {
                  return left * right;
                } else if (expr.op == HS_Common.Devide) {
                  return left / right;
                } else if (expr.op == HS_Common.Modulo) {
                  return left % right;
                } else if (expr.op == HS_Common.Greater) {
                  return left > right;
                } else if (expr.op == HS_Common.GreaterOrEqual) {
                  return left >= right;
                } else if (expr.op == HS_Common.Lesser) {
                  return left < right;
                } else if (expr.op == HS_Common.LesserOrEqual) {
                  return left <= right;
                }
              } else {
                throw HSErr_UndefinedBinaryOperator(
                    left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
              }
            } else {
              throw HSErr_UndefinedBinaryOperator(
                  left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
            }
          }
          break;
        default:
          throw HSErr_UndefinedBinaryOperator(
              left.toString(), right.toString(), expr.op.lexeme, expr.op.line, expr.op.column, curFileName);
          break;
      }
    }
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    var callee = evaluateExpr(expr.callee);
    var args = <dynamic>[];
    for (var arg in expr.args) {
      var value = evaluateExpr(arg);
      args.add(value);
    }

    if (callee is HS_Function) {
      if (callee.funcStmt.functype != FuncStmtType.constructor) {
        return callee.call(this, expr.line, expr.column, args ?? []);
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

      return callee.createInstance(this, expr.line, expr.column, curContext, args: args);
    } else {
      throw HSErr_Callable(callee.toString(), expr.callee.line, expr.callee.column, curFileName);
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    var value = evaluateExpr(expr.value);
    var full_name = _varPos[expr];
    if (full_name != null) {
      // 尝试设置当前环境中的本地变量
      _spaces[full_name].assign(expr.variable.lexeme, value, expr.line, expr.column, this,
          from: curContext.fullName, recursive: false);
    } else {
      // 尝试设置当前实例中的类成员变量
      HS_Instance instance = curContext.fetch(HS_Common.This, expr.line, expr.column, this);
      instance.setValue(expr.variable.lexeme, value, expr.line, expr.column, this);
    }

    // 返回右值
    return value;
  }

  @override
  dynamic visitThisExpr(ThisExpr expr) => _getVar(HS_Common.This, expr);

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {
    var collection = evaluateExpr(expr.collection);
    var key = evaluateExpr(expr.key);
    if (collection is HSVal_List) {
      return collection.value.elementAt(key);
    } else if (collection is List) {
      return collection[key];
    } else if (collection is HSVal_Map) {
      return collection.value[key];
    } else if (collection is Map) {
      return collection[key];
    }

    throw HSErr_SubGet(collection.toString(), expr.line, expr.column, expr.fileName);
  }

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {
    var collection = evaluateExpr(expr.collection);
    var key = evaluateExpr(expr.key);
    var value = evaluateExpr(expr.value);
    if ((collection is HSVal_List) || (collection is HSVal_Map)) {
      collection.value[key] = value;
    } else if ((collection is List) || (collection is Map)) {
      return collection[key] = value;
    }

    throw HSErr_SubGet(collection.toString(), expr.line, expr.column, expr.fileName);
  }

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    var object = evaluateExpr(expr.collection);

    if (object is num) {
      object = HSVal_Num(object, expr.line, expr.column, this);
    } else if (object is bool) {
      object = HSVal_Bool(object, expr.line, expr.column, this);
    } else if (object is String) {
      object = HSVal_String(object, expr.line, expr.column, this);
    } else if (object is List) {
      object = HSVal_List(object, expr.line, expr.column, this);
    } else if (object is Map) {
      object = HSVal_Map(object, expr.line, expr.column, this);
    }

    if (object is HS_Instance) {
      return object.getValue(expr.key.lexeme, expr.line, expr.column, this);
    } else if (object is HS_Class) {
      return object.fetch(expr.key.lexeme, expr.line, expr.column, this, from: curContext.fullName);
    }

    throw HSErr_Get(object.toString(), expr.line, expr.column, expr.fileName);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    dynamic object = evaluateExpr(expr.collection);
    var value = evaluateExpr(expr.value);
    if (object is HS_Instance) {
      object.setValue(expr.key.lexeme, value, expr.line, expr.column, this);
    } else if (object is HS_Class) {
      object.assign(expr.key.lexeme, value, expr.line, expr.column, this, from: curContext.fullName);
      return value;
    }

    throw HSErr_Get(object.toString(), expr.key.line, expr.key.column, expr.fileName);
  }

  // TODO: import as 命名空间
  @override
  dynamic visitImportStmt(ImportStmt stmt) {
    String file_path;
    if (stmt.filepath.startsWith('hetu:')) {
      file_path = stmt.filepath.substring(5);
      file_path = path.join(_sdkDir, file_path + '.ht');
    } else {
      file_path = path.join(workingDir, stmt.filepath);
    }
    evalf(file_path, libName: stmt.asspace);
  }

  @override
  void visitVarStmt(VarStmt stmt) {
    dynamic value;
    if (stmt.initializer != null) {
      value = evaluateExpr(stmt.initializer);
    }

    if (stmt.typename.lexeme == HS_Common.Dynamic) {
      curContext.define(stmt.name.lexeme, stmt.typename.lexeme, stmt.typename.line, stmt.typename.column, this,
          value: value);
    } else if (stmt.typename.lexeme == HS_Common.Var) {
      // 如果用了var关键字，则从初始化表达式推断变量类型
      if (value != null) {
        curContext.define(stmt.name.lexeme, HS_TypeOf(value), stmt.typename.line, stmt.typename.column, this,
            value: value);
      } else {
        curContext.define(stmt.name.lexeme, HS_Common.Dynamic, stmt.typename.line, stmt.typename.column, this);
      }
    } else {
      // 接下来define函数会判断类型是否符合声明
      curContext.define(stmt.name.lexeme, stmt.typename.lexeme, stmt.typename.line, stmt.typename.column, this,
          value: value);
    }
  }

  @override
  void visitExprStmt(ExprStmt stmt) => evaluateExpr(stmt.expr);

  @override
  void visitBlockStmt(BlockStmt stmt) {
    executeBlock(stmt.block, defineSpace(Namespace(closure: curContext)));
  }

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    if (stmt.expr != null) {
      throw evaluateExpr(stmt.expr);
    }
    throw null;
  }

  @override
  void visitIfStmt(IfStmt stmt) {
    var value = evaluateExpr(stmt.condition);
    if (value is bool) {
      if (value) {
        evaluateStmt(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        evaluateStmt(stmt.elseBranch);
      }
    } else {
      throw HSErr_Condition(stmt.condition.line, stmt.condition.column, stmt.condition.fileName);
    }
  }

  @override
  void visitWhileStmt(WhileStmt stmt) {
    var value = evaluateExpr(stmt.condition);
    if (value is bool) {
      while ((value is bool) && (value)) {
        try {
          evaluateStmt(stmt.loop);
          value = evaluateExpr(stmt.condition);
        } catch (error) {
          if (error is HS_Break) {
            return;
          } else if (error is HS_Continue) {
            continue;
          } else {
            throw error;
          }
        }
      }
    } else {
      throw HSErr_Condition(stmt.condition.line, stmt.condition.column, stmt.condition.fileName);
    }
  }

  @override
  void visitBreakStmt(BreakStmt stmt) {
    throw HS_Break();
  }

  @override
  void visitContinueStmt(ContinueStmt stmt) {
    throw HS_Continue();
  }

  @override
  void visitFuncStmt(FuncStmt stmt) {
    // 构造函数本身不注册为变量
    if (stmt.functype != FuncStmtType.constructor) {
      HS_Function func;
      HS_External externFunc;
      if (stmt.isExtern) {
        externFunc = extern.fetch(stmt.name.lexeme, stmt.name.line, stmt.name.column, this, from: HS_Common.Extern);
      }
      func = HS_Function(stmt.internalName, stmt, extern: externFunc, closure: curContext);

      curContext.define(stmt.name.lexeme, HS_Common.FunctionObj, stmt.name.line, stmt.name.column, this, value: func);
    }
  }

  @override
  void visitClassStmt(ClassStmt stmt) {
    HS_Class superClass;

    //TODO: while superClass != null, inherit all...

    // if (stmt.superClass == null) {
    //   if (stmt.name.lexeme != HS_Common.Object)
    //     superClass = global.fetch(HS_Common.Object, stmt.name.line, stmt.name.column, this);
    // } else {
    //   superClass = evaluateExpr(stmt.superClass);
    //   if (superClass is! HS_Class) {
    //     throw HSErr_Extends(superClass.name, stmt.superClass.line, stmt.superClass.column, curFileName);
    //   }
    // }

    var klass = HS_Class(stmt.name.lexeme);
    //,superClass: superClass);

    if (stmt.superClass != null) {
      klass.define(HS_Common.Super, HS_Common.Class, stmt.name.line, stmt.name.column, curFileName, value: superClass);
    }

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    Namespace space;
    space = _isGlobal && !stmt.name.lexeme.startsWith(HS_Common.Underscore) ? _globalContext : curContext;
    space.define(stmt.name.lexeme, HS_Common.Class, stmt.name.line, stmt.name.column, curFileName, value: klass);

    for (var variable in stmt.variables) {
      if (variable.isStatic) {
        dynamic value;
        if (variable.initializer != null) {
          var save = curContext;
          curContext = klass;
          value = globalInterpreter.evaluateExpr(variable.initializer);
          curContext = save;
        } else if (variable.isExtern) {
          value = globalInterpreter.fetchExternal('${stmt.name.lexeme}${HS_Common.Dot}${variable.name.lexeme}',
              variable.name.line, variable.name.column, curFileName);
        }

        if (variable.typename.lexeme == HS_Common.Dynamic) {
          klass.define(variable.name.lexeme, variable.typename.lexeme, variable.typename.line, variable.typename.column,
              curFileName,
              value: value);
        } else if (variable.typename.lexeme == HS_Common.Var) {
          // 如果用了var关键字，则从初始化表达式推断变量类型
          if (value != null) {
            klass.define(
                variable.name.lexeme, HS_TypeOf(value), variable.typename.line, variable.typename.column, curFileName,
                value: value);
          } else {
            klass.define(
                variable.name.lexeme, HS_Common.Dynamic, variable.typename.line, variable.typename.column, curFileName);
          }
        } else {
          // 接下来define函数会判断类型是否符合声明
          klass.define(variable.name.lexeme, variable.typename.lexeme, variable.typename.line, variable.typename.column,
              curFileName,
              value: value);
        }
      } else {
        klass.addVariable(variable);
      }
    }

    for (var method in stmt.methods) {
      if (klass.containsKey(method.name.lexeme)) {
        throw HSErr_Defined(method.name.lexeme, method.name.line, method.name.column, curFileName);
      }

      HS_Function func;
      if (method.isExtern) {
        var externFunc = globalInterpreter.fetchExternal('${stmt.name.lexeme}${HS_Common.Dot}${method.internalName}',
            method.name.line, method.name.column, curFileName);
        func = HS_Function(method.internalName, //method.name.line, method.name.column, curFileName,
            className: stmt.name.lexeme,
            funcStmt: method,
            extern: externFunc,
            functype: method.functype,
            arity: method.arity);
      } else {
        Namespace closure;
        if (method.isStatic) {
          // 静态函数外层是类本身
          closure = klass;
        } else {
          // 成员函数外层是实例，在某个实例取出函数的时候才绑定到那个实例上
          closure = null;
        }
        func = HS_Function(method.internalName, //method.name.line, method.name.column, curFileName,
            className: stmt.name.lexeme,
            funcStmt: method,
            closure: closure,
            functype: method.functype,
            arity: method.arity);
      }
      if (method.isStatic) {
        klass.define(method.internalName, HS_Common.FunctionObj, method.name.line, method.name.column, curFileName,
            value: func);
      } else {
        klass.addMethod(method.internalName, func, method.name.line, method.name.column, curFileName);
      }
    }
  }
}
