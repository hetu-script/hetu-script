import 'package:hetu_script/src/enum.dart';

import 'core.dart';
import 'read_file.dart';
import 'extern_class.dart';
import 'errors.dart';
import 'expression.dart';
import 'type.dart';
import 'namespace.dart';
import 'class.dart';
import 'function.dart';
import 'lexer.dart';
import 'parser.dart';
import 'lexicon.dart';
import 'resolver.dart';
import 'object.dart';
import 'interpreter.dart';
import 'context.dart';
import 'extern_object.dart';

mixin ASTInterpreterRef {
  late final HTInterpreter interpreter;
}

/// 负责对语句列表进行最终解释执行
class HTInterpreter extends Interpreter implements ASTNodeVisitor {
  static var _fileIndex = 0;

  int _curLine = 0;
  @override
  int get curLine => _curLine;
  int _curColumn = 0;
  @override
  int get curColumn => _curColumn;
  String _curFileName = '';
  @override
  String get curFileName => _curFileName;

  @override
  final String workingDirectory;

  final bool debugMode;
  final ReadFileMethod readFileMethod;

  final _evaledFiles = <String>[];

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _distances = <ASTNode, int>{};

  /// 全局命名空间
  late HTNamespace _globals;

  /// 当前语句所在的命名空间
  late HTNamespace curNamespace;

  dynamic _curStmtValue;

  HTInterpreter(
      {String sdkDirectory = 'hetu_lib/',
      this.workingDirectory = 'script/',
      this.debugMode = false,
      this.readFileMethod = defaultReadFileMethod}) {
    curNamespace = _globals = HTNamespace(this, id: HTLexicon.global);
  }

  Future<void> init(
      {Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalClass> externalClasses = const {}}) async {
    // load classes and functions in core library.
    for (final file in coreLibs.keys) {
      await eval(coreLibs[file]!, fileName: file);
    }

    for (var key in HTExternGlobal.functions.keys) {
      bindExternalFunction(key, HTExternGlobal.functions[key]!);
    }

    bindExternalClass(HTExternGlobal.number, HTExternClassNumber());
    bindExternalClass(HTExternGlobal.boolean, HTExternClassBool());
    bindExternalClass(HTExternGlobal.string, HTExternClassString());
    bindExternalClass(HTExternGlobal.math, HTExternClassMath());
    bindExternalClass(HTExternGlobal.system, HTExternClassSystem(this));
    bindExternalClass(HTExternGlobal.console, HTExternClassConsole());

    for (var key in externalFunctions.keys) {
      bindExternalFunction(key, externalFunctions[key]!);
    }

    for (var key in externalClasses.keys) {
      bindExternalClass(key, externalClasses[key]!);
    }
  }

  @override
  Future<dynamic> eval(
    String content, {
    String? fileName,
    String libName = HTLexicon.global,
    HTContext? context,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    _curFileName = fileName ?? HTLexicon.anonymousScript + (_fileIndex++).toString();

    curNamespace = context is HTNamespace ? context : _globals;
    var lexer = Lexer();
    var parser = Parser();
    var resolver = Resolver();
    try {
      var tokens = lexer.lex(content, _curFileName);

      final statements = await parser.parse(tokens, this, curNamespace, _curFileName, style);
      _distances.addAll(resolver.resolve(statements, _curFileName, libName: libName));

      for (final stmt in statements) {
        _curStmtValue = visitASTNode(stmt);
      }

      if (invokeFunc != null) {
        if (style == ParseStyle.library) {
          return invoke(invokeFunc, positionalArgs: positionalArgs, namedArgs: namedArgs);
        }
      } else {
        return _curStmtValue;
      }
    } catch (e) {
      var sb = StringBuffer();
      for (var funcName in HTFunction.callStack) {
        sb.writeln('  $funcName');
      }
      var callStack = sb.toString();

      if (e is HTParserError) {
        throw HTInterpreterError(
            '${e.message}\nCall stack:\n$callStack', e.type, parser.curFileName, parser.curLine, parser.curColumn);
      } else if (e is HTResolverError) {
        throw HTInterpreterError('${e.message}\nCall stack:\n$callStack', e.type, resolver.curFileName,
            resolver.curLine, resolver.curColumn);
      } else {
        throw HTInterpreterError('$e\nCall stack:\n$callStack', HTErrorType.other, _curFileName, _curLine, _curColumn);
      }
    }
  }

  /// 调用一个全局函数或者类、对象上的函数
  // TODO: 调用构造函数
  @override
  dynamic invoke(String functionName,
      {String? objectName, List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {
    if (objectName == null) {
      var func = _globals.fetch(functionName);
      if (func is HTFunction) {
        return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else if (func is Function) {
        if (func is HTExternalFunction) {
          try {
            return func(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          return Function.apply(func, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(func.toString());
        }
      } else {
        throw HTErrorCallable(functionName);
      }
    } else {
      // 命名空间内的静态函数
      HTObject object = _globals.fetch(objectName);
      var func = object.fetch(functionName);
      if (func is HTFunction) {
        return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else if (func is Function) {
        if (func is HTExternalFunction) {
          try {
            return func(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          return Function.apply(func, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(func.toString());
        }
      } else {
        throw HTErrorCallable(functionName);
      }
    }
  }

  /// 解析文件
  @override
  Future<dynamic> import(
    String fileName, {
    String? directory,
    String? libName,
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    final savedFileName = _curFileName;
    dynamic result;
    if (!_evaledFiles.contains(fileName)) {
      _evaledFiles.add(fileName);

      HTNamespace? library_namespace;
      if ((libName != null) && (libName != HTLexicon.global)) {
        library_namespace = HTNamespace(this, id: libName, closure: _globals);
        _globals.define(libName, declType: HTTypeId.namespace, value: library_namespace);
      }

      var content = await readFileMethod(fileName);
      result = eval(content,
          fileName: fileName,
          context: library_namespace,
          style: style,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs);
    }
    _curFileName = savedFileName;
    return result;
  }

  // @override
  // dynamic evalfSync(
  //   String fileName, {
  //   String? directory,
  //   String? libName,
  //   ParseStyle style = ParseStyle.library,
  //   String? invokeFunc,
  //   List<dynamic> positionalArgs = const [],
  //   Map<String, dynamic> namedArgs = const {},
  // }) {
  //   final savedFileName = _curFileName;
  //   dynamic result;
  //   if (!_evaledFiles.contains(fileName)) {
  //     _evaledFiles.add(fileName);

  //     HTNamespace? library_namespace;
  //     if ((libName != null) && (libName != HTLexicon.global)) {
  //       _globals.define(libName, declType: HTTypeId.namespace);
  //       library_namespace = HTNamespace(this, id: libName, closure: library_namespace);
  //     }

  //     var content = readFileSync(fileName);
  //     result = eval(content,
  //         fileName: fileName,
  //         context: library_namespace,
  //         style: style,
  //         invokeFunc: invokeFunc,
  //         positionalArgs: positionalArgs,
  //         namedArgs: namedArgs);
  //   }
  //   _curFileName = savedFileName;
  //   return result;
  // }

  @override
  HTTypeId typeof(dynamic object) {
    if ((object == null) || (object is NullThrownError)) {
      return HTTypeId.NULL;
    } // Class, Object, external class
    else if (object is HTType) {
      return object.typeid;
    } else if (object is num) {
      return HTTypeId.number;
    } else if (object is bool) {
      return HTTypeId.boolean;
    } else if (object is String) {
      return HTTypeId.string;
    } else if (object is List) {
      // var list_darttype = value.runtimeType.toString();
      // var item_darttype = list_darttype.substring(list_darttype.indexOf('<') + 1, list_darttype.indexOf('>'));
      // if ((item_darttype != 'dynamic') && (value.isNotEmpty)) {
      //   valType = HTTypeOf(value.first);
      // }
      var valType = HTTypeId.ANY;
      if (object.isNotEmpty) {
        valType = typeof(object.first);
        for (final item in object) {
          if (typeof(item) != valType) {
            valType = HTTypeId.ANY;
            break;
          }
        }
      }

      return HTTypeId(HTLexicon.list, arguments: [valType]);
    } else if (object is Map) {
      var keyType = HTTypeId.ANY;
      var valType = HTTypeId.ANY;
      if (object.keys.isNotEmpty) {
        keyType = typeof(object.keys.first);
        for (final key in object.keys) {
          if (typeof(key) != keyType) {
            keyType = HTTypeId.ANY;
            break;
          }
        }
      }
      if (object.values.isNotEmpty) {
        valType = typeof(object.values.first);
        for (final value in object.values) {
          if (typeof(value) != valType) {
            valType = HTTypeId.ANY;
            break;
          }
        }
      }
      return HTTypeId(HTLexicon.map, arguments: [keyType, valType]);
    } else {
      var typeid = object.runtimeType.toString();
      if (typeid.contains('<')) {
        typeid = typeid.substring(0, typeid.indexOf('<'));
      }
      if (containsExternalClass(typeid)) {
        final externClass = fetchExternalClass(typeid);
        return HTTypeId(externClass.id);
      }
      return HTTypeId.unknown;
    }
  }

  void defineGlobal(String key, {HTTypeId? declType, dynamic value, bool isImmutable = false, bool isDynamic = false}) {
    _globals.define(key, declType: declType, value: value, isImmutable: isImmutable, isDynamic: isDynamic);
  }

  dynamic fetchGlobal(String key) {
    return _globals.fetch(key);
  }

  dynamic _getValue(String name, ASTNode expr) {
    var distance = _distances[expr];
    if (distance != null) {
      return curNamespace.fetchAt(name, distance);
    }

    return _globals.fetch(name);
  }

  dynamic executeBlock(List<ASTNode> statements, HTNamespace environment) {
    var saved_context = curNamespace;

    try {
      curNamespace = environment;
      for (final stmt in statements) {
        _curStmtValue = visitASTNode(stmt);
      }
    } finally {
      curNamespace = saved_context;
    }

    return _curStmtValue;
  }

  dynamic visitASTNode(ASTNode ast) => ast.accept(this);

  @override
  dynamic visitNullExpr(NullExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return null;
  }

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return expr.value;
  }

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return _globals.getConstInt(expr.constIndex);
  }

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return _globals.getConstFloat(expr.constIndex);
  }

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return _globals.getConstString(expr.constIndex);
  }

  @override
  dynamic visitGroupExpr(GroupExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return visitASTNode(expr.inner);
  }

  @override
  dynamic visitLiteralVectorExpr(LiteralVectorExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var list = [];
    for (final item in expr.vector) {
      list.add(visitASTNode(item));
    }
    return list;
  }

  @override
  dynamic visitLiteralDictExpr(LiteralDictExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var map = {};
    for (final key_expr in expr.map.keys) {
      var key = visitASTNode(key_expr);
      var value = visitASTNode(expr.map[key_expr]!);
      map[key] = value;
    }
    return map;
  }

  @override
  dynamic visitSymbolExpr(SymbolExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return _getValue(expr.id.lexeme, expr);
  }

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var value = visitASTNode(expr.value);

    if (expr.op.lexeme == HTLexicon.subtract) {
      if (value is num) {
        return -value;
      } else {
        throw HTErrorUndefinedOperator(value.toString(), expr.op.lexeme);
      }
    } else if (expr.op.lexeme == HTLexicon.not) {
      if (value is bool) {
        return !value;
      } else {
        throw HTErrorUndefinedOperator(value.toString(), expr.op.lexeme);
      }
    } else {
      throw HTErrorUndefinedOperator(value.toString(), expr.op.lexeme);
    }
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var left = visitASTNode(expr.left);
    var right;
    if (expr.op.type == HTLexicon.and) {
      if (left is bool) {
        // 如果逻辑和操作的左操作数是假，则直接返回，不再判断后面的值
        if (!left) {
          return false;
        } else {
          right = visitASTNode(expr.right);
          if (right is bool) {
            return left && right;
          } else {
            throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
          }
        }
      } else {
        throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
      }
    } else {
      right = visitASTNode(expr.right);

      // 操作符重载??
      if (expr.op.type == HTLexicon.or) {
        if (left is bool) {
          if (right is bool) {
            return left || right;
          } else {
            throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
          }
        } else {
          throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
        }
      } else if (expr.op.type == HTLexicon.equal) {
        return left == right;
      } else if (expr.op.type == HTLexicon.notEqual) {
        return left != right;
      } else if (expr.op.type == HTLexicon.add || expr.op.type == HTLexicon.subtract) {
        if ((left is String) && (right is String)) {
          return left + right;
        } else if ((left is num) && (right is num)) {
          if (expr.op.lexeme == HTLexicon.add) {
            return left + right;
          } else if (expr.op.lexeme == HTLexicon.subtract) {
            return left - right;
          }
        } else {
          throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
        }
      } else if (expr.op.type == HTLexicon.IS) {
        if (right is HTClass) {
          return typeof(left).id == right.id;
        } else {
          throw HTErrorNotType(right.toString());
        }
      } else if ((expr.op.type == HTLexicon.multiply) ||
          (expr.op.type == HTLexicon.devide) ||
          (expr.op.type == HTLexicon.modulo) ||
          (expr.op.type == HTLexicon.greater) ||
          (expr.op.type == HTLexicon.greaterOrEqual) ||
          (expr.op.type == HTLexicon.lesser) ||
          (expr.op.type == HTLexicon.lesserOrEqual)) {
        if ((expr.op.type == HTLexicon.IS) && (right is HTClass)) {
        } else if (left is num) {
          if (right is num) {
            if (expr.op.type == HTLexicon.multiply) {
              return left * right;
            } else if (expr.op.type == HTLexicon.devide) {
              return left / right;
            } else if (expr.op.type == HTLexicon.modulo) {
              return left % right;
            } else if (expr.op.type == HTLexicon.greater) {
              return left > right;
            } else if (expr.op.type == HTLexicon.greaterOrEqual) {
              return left >= right;
            } else if (expr.op.type == HTLexicon.lesser) {
              return left < right;
            } else if (expr.op.type == HTLexicon.lesserOrEqual) {
              return left <= right;
            }
          } else {
            throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
          }
        } else {
          throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
        }
      } else {
        throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
      }
    }
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var callee = visitASTNode(expr.callee);
    var positionalArgs = [];
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      positionalArgs.add(visitASTNode(expr.positionalArgs[i]));
    }

    var namedArgs = <String, dynamic>{};
    for (var name in expr.namedArgs.keys) {
      namedArgs[name] = visitASTNode(expr.namedArgs[name]!);
    }

    if (callee is HTFunction) {
      if (!callee.isExtern) {
        // 普通函数
        if (callee.funcStmt.funcType != FunctionType.constructor) {
          if (callee.declContext is HTInstance) {
            return callee.call(
                positionalArgs: positionalArgs, namedArgs: namedArgs, instance: callee.declContext as HTInstance?);
          } else {
            return callee.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
          }
        } else {
          final className = callee.funcStmt.className;
          final klass = _globals.fetch(className!);
          if (klass is HTClass) {
            if (!klass.isExtern) {
              // 命名构造函数
              return klass.createInstance(this, expr.line, expr.column,
                  constructorName: callee.id, positionalArgs: positionalArgs, namedArgs: namedArgs);
            } else {
              // 外部命名构造函数
              final externClass = fetchExternalClass(className);
              final constructor = externClass.fetch(callee.id);
              if (constructor is HTExternalFunction) {
                try {
                  return constructor(positionalArgs, namedArgs);
                } on RangeError {
                  throw HTErrorExternParams();
                }
              } else {
                return Function.apply(
                    constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
                // throw HTErrorExternFunc(constructor.toString());
              }
            }
          } else {
            throw HTErrorCallable(callee.toString());
          }
        }
      } else {
        final externFunc = fetchExternalFunction(callee.id);
        if (externFunc is HTExternalFunction) {
          try {
            return externFunc(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          return Function.apply(
              externFunc, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
    } else if (callee is HTClass) {
      if (!callee.isExtern) {
        // 默认构造函数
        return callee.createInstance(this, expr.line, expr.column,
            positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else {
        // 外部默认构造函数
        final externClass = fetchExternalClass(callee.id);
        final constructor = externClass.fetch(callee.id);
        if (constructor is HTExternalFunction) {
          try {
            return constructor(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          return Function.apply(
              constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
    } // 外部函数
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        try {
          return callee(positionalArgs, namedArgs);
        } on RangeError {
          throw HTErrorExternParams();
        }
      } else {
        return Function.apply(callee, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        // throw HTErrorExternFunc(callee.toString());
      }
    } else {
      throw HTErrorCallable(callee.toString());
    }
  }

  @override
  dynamic visitAssignExpr(AssignExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var value = visitASTNode(expr.value);
    var distance = _distances[expr];
    if (distance != null) {
      // 尝试设置当前环境中的本地变量
      curNamespace.assignAt(expr.variable.lexeme, value, distance);
    } else {
      _globals.assign(expr.variable.lexeme, value);
    }

    // 返回右值
    return value;
  }

  @override
  dynamic visitThisExpr(ThisExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return _getValue(HTLexicon.THIS, expr);
  }

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var collection = visitASTNode(expr.collection);
    var key = visitASTNode(expr.key);
    if (collection is List || collection is Map) {
      return collection[key];
    }

    throw HTErrorSubGet(collection.toString());
  }

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var collection = visitASTNode(expr.collection);
    var key = visitASTNode(expr.key);
    var value = visitASTNode(expr.value);
    if ((collection is List) || (collection is Map)) {
      collection[key] = value;
      return value;
    }

    throw HTErrorSubGet(collection.toString());
  }

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var object = visitASTNode(expr.collection);

    if (object is num) {
      object = HTNumber(object);
    } else if (object is bool) {
      object = HTBoolean(object);
    } else if (object is String) {
      object = HTString(object);
    } else if (object is List) {
      object = HTList(object);
    } else if (object is Map) {
      object = HTMap(object);
    }

    if ((object is HTObject)) {
      return object.fetch(expr.key.lexeme, from: curNamespace.fullName);
    }
    //如果是Dart对象
    else {
      var typeid = object.runtimeType.toString();
      if (typeid.contains('<')) {
        typeid = typeid.substring(0, typeid.indexOf('<'));
      }
      var externClass = fetchExternalClass(typeid);
      return externClass.instanceFetch(object, expr.key.lexeme);
    }
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    dynamic object = visitASTNode(expr.collection);

    if (object is num) {
      object = HTNumber(object);
    } else if (object is bool) {
      object = HTBoolean(object);
    } else if (object is String) {
      object = HTString(object);
    } else if (object is List) {
      object = HTList(object);
    } else if (object is Map) {
      object = HTMap(object);
    }

    var value = visitASTNode(expr.value);
    if (object is HTObject) {
      object.assign(expr.key.lexeme, value, from: curNamespace.fullName);
      return value;
    }
    //如果是Dart对象
    else {
      var typeid = object.runtimeType.toString();
      if (typeid.contains('<')) {
        typeid = typeid.substring(0, typeid.indexOf('<'));
      }
      var externClass = fetchExternalClass(typeid);
      externClass.instanceAssign(object, expr.key.lexeme, value);
      return value;
    }
  }

  @override
  dynamic visitImportStmt(ImportStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
  }

  @override
  dynamic visitExprStmt(ExprStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    return visitASTNode(stmt.expr);
  }

  @override
  dynamic visitBlockStmt(BlockStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    return executeBlock(stmt.block, HTNamespace(this, closure: curNamespace));
  }

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    if (stmt.value != null) {
      var returnValue = visitASTNode(stmt.value!);
      (returnValue != null) ? throw returnValue : throw HTObject.NULL;
    }
    throw HTObject.NULL;
  }

  @override
  dynamic visitIfStmt(IfStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    var value = visitASTNode(stmt.condition);
    if (value is bool) {
      if (value) {
        _curStmtValue = visitASTNode(stmt.thenBranch!);
      } else if (stmt.elseBranch != null) {
        _curStmtValue = visitASTNode(stmt.elseBranch!);
      }
      return _curStmtValue;
    } else {
      throw HTErrorCondition();
    }
  }

  @override
  dynamic visitWhileStmt(WhileStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    var value = visitASTNode(stmt.condition);
    if (value is bool) {
      while ((value is bool) && (value)) {
        try {
          _curStmtValue = visitASTNode(stmt.loop!);
          value = visitASTNode(stmt.condition);
        } catch (error) {
          if (error is HTBreak) {
            return _curStmtValue;
          } else if (error is HTContinue) {
            continue;
          } else {
            rethrow;
          }
        }
      }
    } else {
      throw HTErrorCondition();
    }
  }

  @override
  dynamic visitBreakStmt(BreakStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    throw HTBreak();
  }

  @override
  dynamic visitContinueStmt(ContinueStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    throw HTContinue();
  }

  @override
  dynamic visitVarDeclStmt(VarDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    dynamic value;
    if (stmt.initializer != null) {
      value = visitASTNode(stmt.initializer!);
    }

    curNamespace.define(
      stmt.id.lexeme,
      value: value,
      declType: stmt.declType,
      isExtern: stmt.isExtern,
      isImmutable: stmt.isImmutable,
      isDynamic: stmt.isDynamic,
    );

    return value;
  }

  @override
  dynamic visitParamDeclStmt(ParamDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
  }

  @override
  dynamic visitFuncDeclStmt(FuncDeclaration stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    HTFunction? func;
    if (stmt.funcType != FunctionType.constructor) {
      func = HTFunction(stmt, curNamespace, this, isExtern: stmt.isExtern);
      if (stmt.id != null) {
        curNamespace.define(stmt.id!.lexeme, declType: func.typeid, value: func);
      }
    }
    return func;
  }

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    HTClass? superClass;
    if (stmt.id.lexeme != HTLexicon.rootClass) {
      if (stmt.superClass == null) {
        superClass = _globals.fetch(HTLexicon.rootClass);
      } else {
        dynamic existSuperClass = _getValue(stmt.superClass!.id.lexeme, stmt.superClass!);
        if (existSuperClass is! HTClass) {
          throw HTErrorExtends(superClass!.id);
        }
        superClass = existSuperClass;
      }
    }

    final klass = HTClass(stmt.id.lexeme, superClass, this, isExtern: stmt.isExtern, closure: curNamespace);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    curNamespace.define(stmt.id.lexeme, declType: HTTypeId.CLASS, value: klass);

    //继承所有父类的成员变量和方法
    if (superClass != null) {
      for (final variable in superClass.variables.values) {
        if (variable.isStatic) {
          dynamic value;
          if (variable.initializer != null) {
            value = visitASTNode(variable.initializer!);
          }
          // else if (variable.isExtern) {
          //   value = externs.fetch('${stmt.name}${HTLexicon.memberGet}${variable.name.lexeme}', variable.name.line,
          //       variable.name.column, this,
          //       from: externs.fullName);
          // }

          klass.define(variable.id.lexeme,
              declType: variable.declType,
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
          value = visitASTNode(variable.initializer!);
        }
        // else if (variable.isExtern) {
        //   value = externs.fetch('${stmt.name}${HTLexicon.memberGet}${variable.name.lexeme}', variable.name.line,
        //       variable.name.column, this,
        //       from: externs.fullName);
        // }

        klass.define(variable.id.lexeme,
            declType: variable.declType,
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
      //   throw HTErrorDefined(method.name, method.keyword.line, method.keyword.column, curFileName);
      // }

      HTFunction func;
      if (method.isStatic || method.funcType == FunctionType.constructor) {
        func = HTFunction(method, klass, this, isExtern: method.isExtern);
        klass.define(method.internalName, declType: func.typeid, value: func, isExtern: method.isExtern);
      } else {
        if (!method.isExtern) {
          func = HTFunction(method, curNamespace, this);
          klass.define(method.internalName, declType: func.typeid, value: func, isExtern: method.isExtern);
        }
        // 外部实例成员不在这里注册
      }
    }

    return klass;
  }

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < stmt.enumerations.length; i++) {
      final id = stmt.enumerations[i];
      defs[id] = HTEnumItem(i, id, HTTypeId(stmt.id.lexeme));
    }

    final enumClass = HTEnum(stmt.id.lexeme, defs, this, isExtern: stmt.isExtern);

    curNamespace.define(stmt.id.lexeme, declType: HTTypeId.ENUM, value: enumClass);
  }
}
