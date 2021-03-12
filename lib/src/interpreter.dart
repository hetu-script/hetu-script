import 'dart:io';

import 'core.dart';
import 'common.dart';
import 'binding.dart';
import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'value.dart';
import 'namespace.dart';
import 'class.dart';
import 'function.dart';
import 'lexer.dart';
import 'parser.dart';
import 'lexicon.dart';

/// 负责对语句列表进行最终解释执行
class HT_Interpreter extends CodeRunner implements ExprVisitor, StmtVisitor {
  final bool debugMode;
  final ReadFileMethod readFileMethod;

  final _evaledFiles = <String>[];

  /// 全局命名空间
  HT_Namespace _globals;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _distances = <Expr, int>{};

  /// 常量表
  final _constants = <dynamic>[];

  /// 当前语句所在的命名空间
  HT_Namespace curContext;
  String _curFileName;
  String get curFileName => _curFileName;
  String _curDirectory;
  String get curDirectory => _curDirectory;

  dynamic _curStmtValue;

  HT_Interpreter({
    String sdkDirectory = 'hetu_lib/',
    String currentDirectory = 'script/',
    this.debugMode = false,
    this.readFileMethod = defaultReadFileMethod,
    Map<String, HT_ExternFunc> externalFunctions = const {},
  }) {
    curContext = _globals = HT_Namespace(id: HT_Lexicon.globals);

    // load external functions.
    loadExternalFunctions(HT_BaseBinding.externFuncs);
    loadExternalFunctions(externalFunctions);

    // load classes and functions in core library.
    for (final file in coreLibs.keys) {
      eval(coreLibs[file], fileName: file);
    }
  }

  @override
  dynamic eval(
    String content, {
    String fileName,
    String libName = HT_Lexicon.globals,
    HT_Context context,
    ParseStyle style = ParseStyle.library,
    String invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    _curFileName = fileName ?? '__anonymousScript' + (Lexer.fileIndex++).toString();

    curContext = context ?? _globals;
    final statements = Lexer(this, content, fileName: _curFileName).lex().parse(style: style).resolve(libName: libName);
    for (final stmt in statements) {
      _curStmtValue = evaluateStmt(stmt);
    }
    if (invokeFunc != null) {
      if (style == ParseStyle.library) {
        return invoke(invokeFunc, positionalArgs: positionalArgs, namedArgs: namedArgs);
      }
    } else {
      return _curStmtValue;
    }
  }

  /// 解析文件
  Future<dynamic> evalf(
    String fileName, {
    String directory,
    String libName,
    ParseStyle style = ParseStyle.library,
    String invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    final savedFileName = _curFileName;
    final savedFileDirectory = _curDirectory;
    _curFileName = fileName;
    _curDirectory = directory ?? File(_curFileName).parent.path;
    dynamic result;
    if (!_evaledFiles.contains(curFileName)) {
      if (debugMode) print('hetu: Loading $fileName...');
      _evaledFiles.add(curFileName);

      HT_Namespace library_namespace;
      if ((libName != null) && (libName != HT_Lexicon.globals)) {
        library_namespace = HT_Namespace(id: libName, closure: _globals);
        _globals.define(libName, this, declType: HT_Type.NAMESPACE, value: library_namespace);
      }

      var content = await readFileMethod(_curFileName);

      result = eval(content,
          fileName: curFileName,
          context: library_namespace,
          style: style,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs);
    }
    _curFileName = savedFileName;
    _curDirectory = savedFileDirectory;
    return result;
  }

  dynamic evalfSync(
    String fileName, {
    String directory,
    String libName,
    ParseStyle style = ParseStyle.library,
    String invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    final savedFileName = _curFileName;
    final savedFileDirectory = _curDirectory;
    _curFileName = fileName;
    _curDirectory = directory ?? File(_curFileName).path;
    dynamic result;
    if (!_evaledFiles.contains(curFileName)) {
      if (debugMode) print('hetu: Loading $fileName...');
      _evaledFiles.add(curFileName);

      HT_Namespace library_namespace;
      if ((libName != null) && (libName != HT_Lexicon.globals)) {
        _globals.define(libName, this, declType: HT_Type.NAMESPACE);
        library_namespace = HT_Namespace(id: libName, closure: library_namespace);
      }

      var content = readFileSync(_curFileName);
      result = eval(content,
          fileName: curFileName,
          context: library_namespace,
          style: style,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs);
    }
    _curFileName = savedFileName;
    _curDirectory = savedFileDirectory;
    return result;
  }

  void addVarPos(Expr expr, int distance) {
    _distances[expr] = distance;
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

  /// 载入外部函数 必须在脚本中存在一个对应声明
  ///
  /// 此种形式的外部函数通常用于需要进行参数类型判断的情况
  /// TODO: 这里的做法是错误的，不应该另外保存一遍
  @override
  void loadExternalFunctions(Map<String, HT_ExternFunc> lib) {
    for (final key in lib.keys) {
      _globals.define(
        HT_Lexicon.externals + key,
        this,
        value: lib[key],
        isImmutable: true,
        isDynamic: true,
      );
    }
  }

  dynamic _getValue(String name, Expr expr) {
    var distance = _distances[expr];
    if (distance != null) {
      return curContext.fetchAt(name, distance, expr.line, expr.column, this);
    }

    return _globals.fetch(name, expr.line, expr.column, this);
  }

  // dynamic unwrap(dynamic value, int line, int column, String fileName) {
  //   if (value is HT_Value) {
  //     return value;
  //   } else if (value is num) {
  //     return HT_DartObject_Number(value, line, column, this);
  //   } else if (value is bool) {
  //     return HT_DartObject_Boolean(value, line, column, this);
  //   } else if (value is String) {
  //     return HT_DartObject_String(value, line, column, this);
  //   } else {
  //     return value;
  //   }
  // }

  void defineGlobal(String key, {HT_Type declType, dynamic value, bool isImmutable = false, bool isDynamic = false}) {
    _globals.define(key, this, declType: declType, value: value, isImmutable: isImmutable, isDynamic: isDynamic);
  }

  dynamic fetchGlobal(String key) {
    return _globals.fetch(key, null, null, this, from: _globals.fullName);
  }

  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {
    // TODO: name应该可以解析出类名，这样就可以调用类的静态函数
    // if (classname == null) {
    var func = _globals.fetch(functionName, null, null, this, recursive: false);
    if (func is HT_Function) {
      return func.call(this, null, null, positionalArgs: positionalArgs, namedArgs: namedArgs);
    } else {
      throw HTErr_Undefined(functionName, curFileName, null, null);
    }
    // } else {
    //   var klass = _globals.fetch(classname, null, null, this, recursive: false);
    //   if (klass is HT_Class) {
    //     // 只能调用公共函数
    //     var func = klass.fetch(name, null, null, this, recursive: false);
    //     if (func is HT_Function) {
    //       return func.call(this, null, null, namedArgs: args);
    //     } else {
    //       throw HTErr_Callable(name, curFileName, null, null);
    //     }
    //   } else {
    //     throw HTErr_Undefined(classname, curFileName, null, null);
    //   }
    // }
  }

  dynamic executeBlock(List<Stmt> statements, HT_Namespace environment) {
    var saved_context = curContext;

    try {
      curContext = environment;
      for (final stmt in statements) {
        _curStmtValue = evaluateStmt(stmt);
      }
    } finally {
      curContext = saved_context;
    }

    return _curStmtValue;
  }

  dynamic evaluateStmt(Stmt stmt) => stmt.accept(this);

  dynamic evaluateExpr(Expr expr) => expr.accept(this);

  @override
  dynamic visitNullExpr(NullExpr expr) => null;

  @override
  dynamic visitConstExpr(ConstExpr expr) => _constants[expr.constIndex];

  @override
  dynamic visitGroupExpr(GroupExpr expr) => evaluateExpr(expr.inner);

  @override
  dynamic visitLiteralVectorExpr(LiteralVectorExpr expr) {
    var list = [];
    for (final item in expr.vector) {
      list.add(evaluateExpr(item));
    }
    return list;
  }

  @override
  dynamic visitLiteralDictExpr(LiteralDictExpr expr) {
    var map = {};
    for (final key_expr in expr.map.keys) {
      var key = evaluateExpr(key_expr);
      var value = evaluateExpr(expr.map[key_expr]);
      map[key] = value;
    }
    return map;
  }

  @override
  dynamic visitLiteralFunctionExpr(LiteralFunctionExpr expr) {
    return HT_Function(funcStmt: expr.funcStmt, declContext: curContext);
  }

  @override
  dynamic visitSymbolExpr(SymbolExpr expr) => _getValue(expr.id.lexeme, expr);

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    var value = evaluateExpr(expr.value);

    if (expr.op.lexeme == HT_Lexicon.subtract) {
      if (value is num) {
        return -value;
      } else {
        throw HTErr_UndefinedOperator(value.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
      }
    } else if (expr.op.lexeme == HT_Lexicon.not) {
      if (value is bool) {
        return !value;
      } else {
        throw HTErr_UndefinedOperator(value.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
      }
    } else {
      throw HTErr_UndefinedOperator(value.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
    }
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    var left = evaluateExpr(expr.left);
    var right;
    if (expr.op.type == HT_Lexicon.and) {
      if (left is bool) {
        // 如果逻辑和操作的左操作数是假，则直接返回，不再判断后面的值
        if (!left) {
          return false;
        } else {
          right = evaluateExpr(expr.right);
          if (right is bool) {
            return left && right;
          } else {
            throw HTErr_UndefinedBinaryOperator(
                left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
          }
        }
      } else {
        throw HTErr_UndefinedBinaryOperator(
            left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
      }
    } else {
      right = evaluateExpr(expr.right);

      // 操作符重载??
      if (expr.op.type == HT_Lexicon.or) {
        if (left is bool) {
          if (right is bool) {
            return left || right;
          } else {
            throw HTErr_UndefinedBinaryOperator(
                left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
          }
        } else {
          throw HTErr_UndefinedBinaryOperator(
              left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
        }
      } else if (expr.op.type == HT_Lexicon.equal) {
        return left == right;
      } else if (expr.op.type == HT_Lexicon.notEqual) {
        return left != right;
      } else if (expr.op.type == HT_Lexicon.add || expr.op.type == HT_Lexicon.subtract) {
        if ((left is String) && (right is String)) {
          return left + right;
        } else if ((left is num) && (right is num)) {
          if (expr.op.lexeme == HT_Lexicon.add) {
            return left + right;
          } else if (expr.op.lexeme == HT_Lexicon.subtract) {
            return left - right;
          }
        } else {
          throw HTErr_UndefinedBinaryOperator(
              left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
        }
      } else if (expr.op.type == HT_Lexicon.IS) {
        if (right is HT_Class) {
          return HT_TypeOf(left).id == right.id;
        } else {
          throw HTErr_NotType(right.toString(), curFileName, expr.op.line, expr.op.column);
        }
      } else if ((expr.op.type == HT_Lexicon.multiply) ||
          (expr.op.type == HT_Lexicon.devide) ||
          (expr.op.type == HT_Lexicon.modulo) ||
          (expr.op.type == HT_Lexicon.greater) ||
          (expr.op.type == HT_Lexicon.greaterOrEqual) ||
          (expr.op.type == HT_Lexicon.lesser) ||
          (expr.op.type == HT_Lexicon.lesserOrEqual)) {
        if ((expr.op.type == HT_Lexicon.IS) && (right is HT_Class)) {
        } else if (left is num) {
          if (right is num) {
            if (expr.op.type == HT_Lexicon.multiply) {
              return left * right;
            } else if (expr.op.type == HT_Lexicon.devide) {
              return left / right;
            } else if (expr.op.type == HT_Lexicon.modulo) {
              return left % right;
            } else if (expr.op.type == HT_Lexicon.greater) {
              return left > right;
            } else if (expr.op.type == HT_Lexicon.greaterOrEqual) {
              return left >= right;
            } else if (expr.op.type == HT_Lexicon.lesser) {
              return left < right;
            } else if (expr.op.type == HT_Lexicon.lesserOrEqual) {
              return left <= right;
            }
          } else {
            throw HTErr_UndefinedBinaryOperator(
                left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
          }
        } else {
          throw HTErr_UndefinedBinaryOperator(
              left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
        }
      } else {
        throw HTErr_UndefinedBinaryOperator(
            left.toString(), right.toString(), expr.op.lexeme, curFileName, expr.op.line, expr.op.column);
      }
    }
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    var callee = evaluateExpr(expr.callee);
    var positionalArgs = [];
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      positionalArgs.add(evaluateExpr(expr.positionalArgs[i]));
    }

    var namedArgs = <String, dynamic>{};
    for (var name in expr.namedArgs.keys) {
      namedArgs[name] = evaluateExpr(expr.namedArgs[name]);
    }

    if (callee is HT_Function) {
      // 普通函数
      if (callee.funcStmt.funcType != FuncStmtType.constructor) {
        if (callee.declContext is HT_Object) {
          return callee.call(this, expr.line, expr.column,
              positionalArgs: positionalArgs, namedArgs: namedArgs, object: callee.declContext);
        } else {
          return callee.call(this, expr.line, expr.column, positionalArgs: positionalArgs, namedArgs: namedArgs);
        }
      } else {
        final className = callee.funcStmt.className;
        final klass = _globals.fetch(className, expr.line, expr.column, this);
        if (klass is HT_Class) {
          if (!klass.isExtern) {
            // 命名构造函数
            return klass.createInstance(this, expr.line, expr.column,
                constructorName: callee.id, positionalArgs: positionalArgs, namedArgs: namedArgs);
          } else {
            // 外部命名构造函数
            final HT_ExternFunc extern = _globals.fetch(
                '${HT_Lexicon.externals}${klass.id}${HT_Lexicon.memberGet}${callee.id}', expr.line, expr.column, this);
            HT_Reflect object = extern(this, positionalArgs: positionalArgs, namedArgs: namedArgs);
            object.init(callee.id, this);
            return object;
          }
        } else {
          throw HTErr_Callable(callee.toString(), curFileName, expr.callee.line, expr.callee.column);
        }
      }
    } else if (callee is HT_Class) {
      if (!callee.isExtern) {
        // 默认构造函数
        return callee.createInstance(this, expr.line, expr.column,
            positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else {
        // 外部默认构造函数
        final HT_ExternFunc extern =
            _globals.fetch('${HT_Lexicon.externals}${callee.id}', expr.line, expr.column, this);
        HT_Reflect object = extern(this, positionalArgs: positionalArgs, namedArgs: namedArgs);
        object.init(callee.id, this);
        return object;
      }
    } // 外部函数
    else if (callee is Function) {
      return Function.apply(callee, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
    } else {
      throw HTErr_Callable(callee.toString(), curFileName, expr.callee.line, expr.callee.column);
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    var value = evaluateExpr(expr.value);
    var distance = _distances[expr];
    if (distance != null) {
      // 尝试设置当前环境中的本地变量
      curContext.assignAt(expr.variable.lexeme, value, distance, expr.line, expr.column, this);
    } else {
      _globals.assign(expr.variable.lexeme, value, expr.line, expr.column, this);
    }

    // 返回右值
    return value;
  }

  @override
  dynamic visitThisExpr(ThisExpr expr) => _getValue(HT_Lexicon.THIS, expr);

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {
    var collection = evaluateExpr(expr.collection);
    var key = evaluateExpr(expr.key);
    if (collection is HT_DartObject_List) {
      return collection.value.elementAt(key);
    } else if (collection is List) {
      return collection[key];
    } else if (collection is HT_DartObject_Map) {
      return collection.value[key];
    } else if (collection is Map) {
      return collection[key];
    }

    throw HTErr_SubGet(collection.toString(), expr.fileName, expr.line, expr.column);
  }

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {
    var collection = evaluateExpr(expr.collection);
    var key = evaluateExpr(expr.key);
    var value = evaluateExpr(expr.value);
    if ((collection is List) || (collection is Map)) {
      return collection[key] = value;
    } else if ((collection is HT_DartObject_List) || (collection is HT_DartObject_Map)) {
      collection.value[key] = value;
    }

    throw HTErr_SubGet(collection.toString(), expr.fileName, expr.line, expr.column);
  }

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    var object = evaluateExpr(expr.collection);

    if (object is num) {
      object = HT_DartObject_Number(object)..init(HT_Lexicon.number, this);
    } else if (object is bool) {
      object = HT_DartObject_Boolean(object)..init(HT_Lexicon.boolean, this);
    } else if (object is String) {
      object = HT_DartObject_String(object)..init(HT_Lexicon.string, this);
    } else if (object is List) {
      object = HT_DartObject_List(object)..init(HT_Lexicon.list, this);
    } else if (object is Map) {
      object = HT_DartObject_Map(object)..init(HT_Lexicon.map, this);
    }

    if ((object is HT_Object) || (object is HT_Class)) {
      return object.fetch(expr.key.lexeme, expr.line, expr.column, this, from: curContext.fullName);
    }
    //如果是Dart对象，通过反射获取成员
    else if (object is HT_Reflect) {
      return object.getProperty(expr.key.lexeme);
    }

    throw HTErr_Get(object.toString(), expr.fileName, expr.line, expr.column);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    dynamic object = evaluateExpr(expr.collection);
    var value = evaluateExpr(expr.value);
    if ((object is HT_Object) || (object is HT_Class)) {
      object.assign(expr.key.lexeme, value, expr.line, expr.column, this, from: curContext.fullName);
      return value;
    }
    //如果是Dart对象，通过反射获取成员
    else if (object is HT_Reflect) {
      return object.setProperty(expr.key.lexeme, value);
    }

    throw HTErr_Get(object.toString(), expr.fileName, expr.key.line, expr.key.column);
  }

  @override
  dynamic visitImportStmt(ImportStmt stmt) {}

  @override
  dynamic visitExprStmt(ExprStmt stmt) => evaluateExpr(stmt.expr);

  @override
  dynamic visitBlockStmt(BlockStmt stmt) => executeBlock(stmt.block, HT_Namespace(closure: curContext));

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {
    if (stmt.expr != null) {
      throw evaluateExpr(stmt.expr);
    }
    throw null;
  }

  @override
  dynamic visitIfStmt(IfStmt stmt) {
    var value = evaluateExpr(stmt.condition);
    if (value is bool) {
      if (value) {
        _curStmtValue = evaluateStmt(stmt.thenBranch);
      } else if (stmt.elseBranch != null) {
        _curStmtValue = evaluateStmt(stmt.elseBranch);
      }
      return _curStmtValue;
    } else {
      throw HTErr_Condition(stmt.condition.line, stmt.condition.column, stmt.condition.fileName);
    }
  }

  @override
  dynamic visitWhileStmt(WhileStmt stmt) {
    var value = evaluateExpr(stmt.condition);
    if (value is bool) {
      while ((value is bool) && (value)) {
        try {
          _curStmtValue = evaluateStmt(stmt.loop);
          value = evaluateExpr(stmt.condition);
        } catch (error) {
          if (error is HT_Break) {
            return _curStmtValue;
          } else if (error is HT_Continue) {
            continue;
          } else {
            rethrow;
          }
        }
      }
    } else {
      throw HTErr_Condition(stmt.condition.line, stmt.condition.column, stmt.condition.fileName);
    }
  }

  @override
  dynamic visitBreakStmt(BreakStmt stmt) {
    throw HT_Break();
  }

  @override
  dynamic visitContinueStmt(ContinueStmt stmt) {
    throw HT_Continue();
  }

  @override
  dynamic visitVarDeclStmt(VarDeclStmt stmt) {
    dynamic value;
    if (stmt.initializer != null) {
      value = evaluateExpr(stmt.initializer);
    }

    curContext.define(
      stmt.id.lexeme,
      this,
      line: stmt.id.line,
      column: stmt.id.column,
      value: value,
      declType: stmt.declType,
      isExtern: stmt.isExtern,
      isImmutable: stmt.isImmutable,
      isDynamic: stmt.isDynamic,
    );

    return value;
  }

  @override
  dynamic visitFuncDeclStmt(FuncDeclStmt stmt) {
    HT_Function func;
    if (stmt.funcType != FuncStmtType.constructor) {
      HT_ExternFunc externFunc;
      if (stmt.isExtern) {
        externFunc = _globals.fetch('${HT_Lexicon.externals}${stmt.id}', stmt.keyword.line, stmt.keyword.column, this,
            from: _globals.fullName);
      }
      func = HT_Function(funcStmt: stmt, extern: externFunc, declContext: curContext);
      curContext.define(stmt.id, this,
          declType: func.typeid, line: stmt.keyword.line, column: stmt.keyword.column, value: func);
    }
    return func;
  }

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {
    HT_Class superClass;
    if (stmt.id != HT_Lexicon.rootClass) {
      if (stmt.superClass == null) {
        superClass = _globals.fetch(HT_Lexicon.rootClass, stmt.keyword.line, stmt.keyword.column, this);
      } else {
        dynamic super_class = _getValue(stmt.superClass.id.lexeme, stmt.superClass);
        if (super_class is! HT_Class) {
          throw HTErr_Extends(superClass.id, curFileName, stmt.keyword.line, stmt.keyword.column);
        }
        superClass = super_class;
      }
    }

    final klass = HT_Class(stmt.id, superClass, this, isExtern: stmt.isExtern, closure: curContext);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    curContext.define(stmt.id, this,
        declType: HT_Type.CLASS, line: stmt.keyword.line, column: stmt.keyword.column, value: klass);

    //继承所有父类的成员变量和方法
    if (superClass != null) {
      for (final variable in superClass.variables.values) {
        if (variable.isStatic) {
          dynamic value;
          if (variable.initializer != null) {
            value = evaluateExpr(variable.initializer);
          }
          // else if (variable.isExtern) {
          //   value = externs.fetch('${stmt.name}${HT_Lexicon.memberGet}${variable.name.lexeme}', variable.name.line,
          //       variable.name.column, this,
          //       from: externs.fullName);
          // }

          klass.define(variable.id.lexeme, this,
              declType: variable.declType,
              line: variable.id.line,
              column: variable.id.column,
              value: value,
              isExtern: variable.isExtern,
              isImmutable: variable.isImmutable,
              isDynamic: variable.isDynamic);
        } else {
          klass.addVariable(variable);
        }
      }
    }

    var save = curContext;
    curContext = klass;
    for (final variable in stmt.variables) {
      if (variable.isStatic) {
        dynamic value;
        if (variable.initializer != null) {
          value = evaluateExpr(variable.initializer);
        }
        // else if (variable.isExtern) {
        //   value = externs.fetch('${stmt.name}${HT_Lexicon.memberGet}${variable.name.lexeme}', variable.name.line,
        //       variable.name.column, this,
        //       from: externs.fullName);
        // }

        klass.define(variable.id.lexeme, this,
            declType: variable.declType,
            line: variable.id.line,
            column: variable.id.column,
            value: value,
            isExtern: variable.isExtern,
            isImmutable: variable.isImmutable,
            isDynamic: variable.isDynamic);
      } else {
        klass.addVariable(variable);
      }
    }
    curContext = save;

    for (final method in stmt.methods) {
      // if (klass.contains(method.internalName)) {
      //   throw HTErr_Defined(method.name, method.keyword.line, method.keyword.column, curFileName);
      // }

      HT_Function func;
      if (method.isStatic || method.funcType == FuncStmtType.constructor) {
        HT_ExternFunc externFunc;
        if (method.isExtern) {
          final externName = method.funcType == FuncStmtType.constructor
              ? '${HT_Lexicon.externals}${stmt.id}'
              : '${HT_Lexicon.externals}${stmt.id}${HT_Lexicon.memberGet}${method.id}';
          externFunc =
              _globals.fetch(externName, method.keyword.line, method.keyword.column, this, from: _globals.fullName);
        }
        func = HT_Function(funcStmt: method, internalName: method.internalName, extern: externFunc, declContext: klass);
        klass.define(method.internalName, this,
            declType: func.typeid, line: method.keyword.line, column: method.keyword.column, value: func);
      } else {
        if (!method.isExtern) {
          func = HT_Function(funcStmt: method, internalName: method.internalName);
          klass.define(method.internalName, this,
              declType: func.typeid, line: method.keyword.line, column: method.keyword.column, value: func);
        }
        // 外部实例成员不在这里注册
      }
    }

    return klass;
  }
}
