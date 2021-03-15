import 'dart:io';

import 'core.dart';
import 'common.dart';
import 'extern_class.dart';
import 'errors.dart';
import 'expression.dart';
import 'statement.dart';
import 'value.dart';
import 'type.dart';
import 'namespace.dart';
import 'class.dart';
import 'function.dart';
import 'lexer.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'extern_object.dart';
import 'resolver.dart';

/// 负责对语句列表进行最终解释执行
class HT_Interpreter with Binding implements CodeRunner, ExprVisitor, StmtVisitor {
  static var _fileIndex = 0;

  final bool debugMode;
  final ReadFileMethod readFileMethod;

  final _evaledFiles = <String>[];

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _distances = <Expr, int>{};

  /// 全局命名空间
  late HT_Namespace _globals;

  /// 当前语句所在的命名空间
  late HT_Namespace curNamespace;

  late String _curFileName;
  String? _curDirectory;
  @override
  String get curFileName => _curFileName;
  @override
  String? get curDirectory => _curDirectory;

  dynamic _curStmtValue;

  HT_Interpreter(
      {String sdkDirectory = 'hetu_lib/',
      String currentDirectory = 'script/',
      this.debugMode = false,
      this.readFileMethod = defaultReadFileMethod,
      Map<String, Function> externalFunctions = const {}}) {
    curNamespace = _globals = HT_Namespace(id: HT_Lexicon.global);

    // load external functions.
    // loadExternalFunctions(HT_ExternalNamespace.externFuncs);
    // loadExternalFunctions(externalFunctions);

    // load classes and functions in core library.
    for (final file in coreLibs.keys) {
      eval(coreLibs[file]!, fileName: file);
    }

    for (var key in HT_Extern_Global.functions.keys) {
      bindExternalFunction(key, HT_Extern_Global.functions[key]!);
    }

    bindExternalNamespace(HT_Extern_Global.number, HT_ExternClass_Number());
    bindExternalNamespace(HT_Extern_Global.boolean, HT_ExternClass_Bool());
    bindExternalNamespace(HT_Extern_Global.string, HT_ExternClass_String());
    bindExternalNamespace(HT_Extern_Global.math, HT_ExternClass_Math());
    bindExternalNamespace(HT_Extern_Global.system, HT_ExternClass_System(this));
    bindExternalNamespace(HT_Extern_Global.console, HT_ExternClass_Console());

    for (var key in externalFunctions.keys) {
      bindExternalFunction(key, externalFunctions[key]!);
    }
  }

  @override
  dynamic eval(
    String content, {
    String? fileName,
    String libName = HT_Lexicon.global,
    HT_Context? context,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    _curFileName = fileName ?? HT_Lexicon.anonymousFile + (_fileIndex++).toString();

    curNamespace = context is HT_Namespace ? context : _globals;
    var tokens = Lexer().lex(content);
    final statements = Parser(this).parse(tokens, curNamespace, _curFileName, style);
    _distances.addAll(Resolver(this).resolve(statements, _curFileName, libName: libName));

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

  @override
  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {
    // TODO: name应该可以解析出类名，这样就可以调用类的静态函数
    // if (classname == null) {
    var func = _globals.fetch(functionName, null, null, this, recursive: false);
    if (func is HT_Function) {
      return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
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

  /// 解析文件
  @override
  Future<dynamic> evalf(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
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

      HT_Namespace? library_namespace;
      if ((libName != null) && (libName != HT_Lexicon.global)) {
        library_namespace = HT_Namespace(id: libName, closure: _globals);
        _globals.define(libName, this, declType: HT_TypeId.namespace, value: library_namespace);
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

  @override
  dynamic evalfSync(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
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

      HT_Namespace? library_namespace;
      if ((libName != null) && (libName != HT_Lexicon.global)) {
        _globals.define(libName, this, declType: HT_TypeId.namespace);
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

  dynamic _getValue(String name, Expr expr) {
    var distance = _distances[expr];
    if (distance != null) {
      return curNamespace.fetchAt(name, distance, expr.line, expr.column, this);
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

  void defineGlobal(String key,
      {HT_TypeId? declType, dynamic value, bool isImmutable = false, bool isDynamic = false}) {
    _globals.define(key, this, declType: declType, value: value, isImmutable: isImmutable, isDynamic: isDynamic);
  }

  dynamic fetchGlobal(String key) {
    return _globals.fetch(key, null, null, this, from: _globals.fullName);
  }

  dynamic executeBlock(List<Stmt> statements, HT_Namespace environment) {
    var saved_context = curNamespace;

    try {
      curNamespace = environment;
      for (final stmt in statements) {
        _curStmtValue = evaluateStmt(stmt);
      }
    } finally {
      curNamespace = saved_context;
    }

    return _curStmtValue;
  }

  dynamic evaluateStmt(Stmt stmt) => stmt.accept(this);

  dynamic evaluateExpr(Expr expr) => expr.accept(this);

  @override
  dynamic visitNullExpr(NullExpr expr) => null;

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) => expr.value;

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) => _globals.getConstInt(expr.constIndex);

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) => _globals.getConstFloat(expr.constIndex);

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) => _globals.getConstString(expr.constIndex);

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
      var value = evaluateExpr(expr.map[key_expr]!);
      map[key] = value;
    }
    return map;
  }

  @override
  dynamic visitLiteralFunctionExpr(LiteralFunctionExpr expr) {
    return HT_Function(expr.funcStmt, curNamespace, this);
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
      namedArgs[name] = evaluateExpr(expr.namedArgs[name]!);
    }

    if (callee is HT_Function) {
      if (!callee.isExtern) {
        // 普通函数
        if (callee.funcStmt.funcType != FuncStmtType.constructor) {
          if (callee.declContext is HT_Object) {
            return callee.call(
                line: expr.line,
                column: expr.column,
                positionalArgs: positionalArgs,
                namedArgs: namedArgs,
                object: callee.declContext as HT_Object?);
          } else {
            return callee.call(
                line: expr.line, column: expr.column, positionalArgs: positionalArgs, namedArgs: namedArgs);
          }
        } else {
          final className = callee.funcStmt.className;
          final klass = _globals.fetch(className!, expr.line, expr.column, this);
          if (klass is HT_Class) {
            if (!klass.isExtern) {
              // 命名构造函数
              return klass.createInstance(this, expr.line, expr.column,
                  constructorName: callee.id, positionalArgs: positionalArgs, namedArgs: namedArgs);
            } else {
              // 外部命名构造函数
              final externClass = fetchExternalClass(className);
              final HT_ExternFunc constructor = externClass.fetch(callee.id);
              return constructor(positionalArgs, namedArgs);
            }
          } else {
            throw HTErr_Callable(callee.toString(), curFileName, expr.callee.line, expr.callee.column);
          }
        }
      } else {
        final externFunction = fetchExternalFunction(callee.id);
        var result =
            Function.apply(externFunction, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        return result;
      }
    } else if (callee is HT_Class) {
      if (!callee.isExtern) {
        // 默认构造函数
        return callee.createInstance(this, expr.line, expr.column,
            positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else {
        // 外部默认构造函数
        final externClass = fetchExternalClass(callee.id);
        final Function constructor = externClass.fetch(callee.id);
        return constructor();
      }
    } // 外部函数
    else if (callee is Function) {
      var result = Function.apply(callee, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
      return result;
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
      curNamespace.assignAt(expr.variable.lexeme, value, distance, expr.line, expr.column, this);
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
      return collection.externObject.elementAt(key);
    } else if (collection is List) {
      return collection[key];
    } else if (collection is HT_DartObject_Map) {
      return collection.externObject[key];
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
      object = HT_Dart_Number(object);
    } else if (object is bool) {
      object = HT_DartObject_Boolean(object);
    } else if (object is String) {
      object = HT_DartObject_String(object);
    } else if (object is List) {
      object = HT_DartObject_List(object);
    } else if (object is Map) {
      object = HT_DartObject_Map(object);
    }

    if ((object is HT_Value)) {
      return object.fetch(expr.key.lexeme, expr.line, expr.column, this, from: curNamespace.fullName);
    }
    //如果是Dart对象
    else if (object is HT_ExternObject) {
      return object.fetch(expr.key.lexeme);
    }

    throw HTErr_Get(object.toString(), expr.fileName, expr.line, expr.column);
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    dynamic object = evaluateExpr(expr.collection);

    if (object is num) {
      object = HT_Dart_Number(object);
    } else if (object is bool) {
      object = HT_DartObject_Boolean(object);
    } else if (object is String) {
      object = HT_DartObject_String(object);
    } else if (object is List) {
      object = HT_DartObject_List(object);
    } else if (object is Map) {
      object = HT_DartObject_Map(object);
    }

    var value = evaluateExpr(expr.value);
    if (object is HT_Value) {
      object.assign(expr.key.lexeme, value, expr.line, expr.column, this, from: curNamespace.fullName);
      return value;
    }
    //如果是Dart对象
    else if (object is HT_ExternObject) {
      return object.assign(expr.key.lexeme, value);
    }

    throw HTErr_Get(object.toString(), expr.fileName, expr.key.line, expr.key.column);
  }

  @override
  dynamic visitImportStmt(ImportStmt stmt) {}

  @override
  dynamic visitExprStmt(ExprStmt stmt) => evaluateExpr(stmt.expr);

  @override
  dynamic visitBlockStmt(BlockStmt stmt) => executeBlock(stmt.block, HT_Namespace(closure: curNamespace));

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {
    if (stmt.expr != null) {
      var returnValue = evaluateExpr(stmt.expr!);
      (returnValue != null) ? throw returnValue : throw HT_Value.NULL;
    }
    throw HT_Value.NULL;
  }

  @override
  dynamic visitIfStmt(IfStmt stmt) {
    var value = evaluateExpr(stmt.condition);
    if (value is bool) {
      if (value) {
        _curStmtValue = evaluateStmt(stmt.thenBranch!);
      } else if (stmt.elseBranch != null) {
        _curStmtValue = evaluateStmt(stmt.elseBranch!);
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
          _curStmtValue = evaluateStmt(stmt.loop!);
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
      value = evaluateExpr(stmt.initializer!);
    }

    curNamespace.define(
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
  dynamic visitParamDeclStmt(ParamDeclStmt stmt) {}

  @override
  dynamic visitFuncDeclStmt(FuncDeclStmt stmt) {
    HT_Function? func;
    if (stmt.funcType != FuncStmtType.constructor) {
      func = HT_Function(stmt, curNamespace, this, isExtern: stmt.isExtern);
      curNamespace.define(stmt.id, this,
          declType: func.typeid, line: stmt.keyword.line, column: stmt.keyword.column, value: func);
    }
    return func;
  }

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {
    HT_Class? superClass;
    if (stmt.id != HT_Lexicon.rootClass) {
      if (stmt.superClass == null) {
        superClass = _globals.fetch(HT_Lexicon.rootClass, stmt.keyword.line, stmt.keyword.column, this);
      } else {
        dynamic existSuperClass = _getValue(stmt.superClass!.id.lexeme, stmt.superClass!);
        if (existSuperClass is! HT_Class) {
          throw HTErr_Extends(superClass!.id, curFileName, stmt.keyword.line, stmt.keyword.column);
        }
        superClass = existSuperClass;
      }
    }

    final klass = HT_Class(stmt.id, superClass, this, isExtern: stmt.isExtern, closure: curNamespace);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    curNamespace.define(stmt.id, this,
        declType: HT_TypeId.CLASS, line: stmt.keyword.line, column: stmt.keyword.column, value: klass);

    //继承所有父类的成员变量和方法
    if (superClass != null) {
      for (final variable in superClass.variables.values) {
        if (variable.isStatic) {
          dynamic value;
          if (variable.initializer != null) {
            value = evaluateExpr(variable.initializer!);
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
          klass.declareVar(variable);
        }
      }
    }

    var save = curNamespace;
    curNamespace = klass;
    for (final variable in stmt.variables) {
      if (variable.isStatic) {
        dynamic value;
        if (variable.initializer != null) {
          value = evaluateExpr(variable.initializer!);
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
        klass.declareVar(variable);
      }
    }
    curNamespace = save;

    for (final method in stmt.methods) {
      // if (klass.contains(method.internalName)) {
      //   throw HTErr_Defined(method.name, method.keyword.line, method.keyword.column, curFileName);
      // }

      HT_Function func;
      if (method.isStatic || method.funcType == FuncStmtType.constructor) {
        func = HT_Function(method, klass, this, isExtern: method.isExtern);
        klass.define(method.internalName, this,
            declType: func.typeid,
            line: method.keyword.line,
            column: method.keyword.column,
            value: func,
            isExtern: method.isExtern);
      } else {
        if (!method.isExtern) {
          func = HT_Function(method, curNamespace, this);
          klass.define(method.internalName, this,
              declType: func.typeid,
              line: method.keyword.line,
              column: method.keyword.column,
              value: func,
              isExtern: method.isExtern);
        }
        // 外部实例成员不在这里注册
      }
    }

    return klass;
  }

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {}
}
