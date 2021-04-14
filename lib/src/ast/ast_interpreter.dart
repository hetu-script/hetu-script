import '../plugin/errorHandler.dart';
import '../plugin/moduleHandler.dart';
import '../binding/external_function.dart';
import '../errors.dart';
import 'ast.dart';
import '../type.dart';
import '../namespace.dart';
import '../class.dart';
import '../function.dart';
import 'ast_function.dart';
import '../lexer.dart';
import '../common.dart';
import 'ast_parser.dart';
import '../lexicon.dart';
import 'ast_resolver.dart';
import '../object.dart';
import '../interpreter.dart';
import '../enum.dart';
import 'ast_variable.dart';
import '../const_table.dart';

mixin AstInterpreterRef {
  late final HTAstInterpreter interpreter;
}

class HTBreak {}

class HTContinue {}

/// 负责对语句列表进行最终解释执行
class HTAstInterpreter extends Interpreter
    with ConstTable
    implements ASTNodeVisitor {
  var _curLine = 0;
  @override
  int get curLine => _curLine;
  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;
  late String _curModuleUniqueKey;
  @override
  String get curModuleUniqueKey => _curModuleUniqueKey;

  String? _curSymbol;
  @override
  String? get curSymbol => _curSymbol;
  String? _curObjectSymbol;
  @override
  String? get curObjectSymbol => _curObjectSymbol;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _distances = <ASTNode, int>{};

  dynamic _curStmtValue;

  late String _savedModuleName;
  late HTNamespace _savedNamespace;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  HTAstInterpreter(
      {bool debugMode = false,
      HTErrorHandler? errorHandler,
      HTModuleHandler? moduleHandler})
      : super(
            debugMode: debugMode,
            errorHandler: errorHandler,
            moduleHandler: moduleHandler);

  @override
  Future<dynamic> eval(String content,
      {String? moduleUniqueKey,
      CodeType codeType = CodeType.module,
      bool debugMode = true,
      HTNamespace? namespace,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    _savedModuleName = _curModuleUniqueKey;
    _savedNamespace = _curNamespace;

    _curModuleUniqueKey = moduleUniqueKey ?? HTLexicon.anonymousScript;
    _curNamespace = namespace ?? global;

    var lexer = Lexer();
    var parser = HTAstParser(this);
    var resolver = HTAstResolver();
    try {
      var tokens = lexer.lex(content, _curModuleUniqueKey);

      final statements =
          await parser.parse(tokens, _curModuleUniqueKey, codeType);
      _distances.addAll(resolver.resolve(statements, _curModuleUniqueKey));

      for (final stmt in statements) {
        _curStmtValue = visitASTNode(stmt);
      }

      _curModuleUniqueKey = _savedModuleName;
      _curNamespace = _savedNamespace;

      if (invokeFunc != null) {
        if (codeType == CodeType.module) {
          return invoke(invokeFunc,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        }
      } else {
        return _curStmtValue;
      }
    } catch (error, stack) {
      var sb = StringBuffer();
      for (var funcName in HTFunction.callStack) {
        sb.writeln('  $funcName');
      }
      sb.writeln('\n$stack');
      var callStack = sb.toString();

      if (error is HTError) {
        error.message = '${error.message}\nCall stack:\n$callStack';
        if (error.type == HTErrorType.parser) {
          error.moduleUniqueKey = parser.curModuleUniqueKey;
          error.line = parser.curLine;
          error.column = parser.curColumn;
        } else {
          error.moduleUniqueKey = _curModuleUniqueKey;
          error.line = _curLine;
          error.column = _curColumn;
        }
        errorHandler.handle(error);
      } else {
        final hetuError = HTError('$error\nCall stack:\n$callStack',
            HTErrorType.interpreter, _curModuleUniqueKey, _curLine, _curColumn);
        errorHandler.handle(hetuError);
      }
    }
  }

  /// 解析文件
  @override
  Future<dynamic> import(String key,
      {String? curModuleUniqueKey,
      String? moduleName,
      CodeType codeType = CodeType.module,
      bool debugMode = true,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) async {
    dynamic result;

    final module = await moduleHandler.import(
        key,
        curModuleUniqueKey != HTLexicon.anonymousScript
            ? curModuleUniqueKey
            : null);
    curModuleUniqueKey = module.uniqueKey;

    HTNamespace? namespace;
    if ((moduleName != null) && (moduleName != HTLexicon.global)) {
      namespace = HTNamespace(this, id: moduleName, closure: global);
      global.define(namespace);
    }

    result = eval(module.content,
        moduleUniqueKey: curModuleUniqueKey,
        namespace: namespace,
        codeType: codeType,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);

    return result;
  }

  @override
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {}

  @override
  void handleError(Object error, [StackTrace? stack]) {}

  dynamic _getValue(String name, ASTNode expr) {
    var distance = _distances[expr];
    if (distance != null) {
      return _curNamespace.fetchAt(name, distance);
    }

    return global.fetch(name);
  }

  dynamic executeBlock(List<ASTNode> statements, HTNamespace environment) {
    var saved_context = _curNamespace;

    try {
      _curNamespace = environment;
      for (final stmt in statements) {
        _curStmtValue = visitASTNode(stmt);
      }
    } finally {
      _curNamespace = saved_context;
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
    return getInt64(expr.constIndex);
  }

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return getFloat64(expr.constIndex);
  }

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return getUtf8String(expr.constIndex);
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
        throw HTError.undefinedOperator(value.toString(), expr.op.lexeme);
      }
    } else if (expr.op.lexeme == HTLexicon.logicalNot) {
      if (value is bool) {
        return !value;
      } else {
        throw HTError.undefinedOperator(value.toString(), expr.op.lexeme);
      }
    } else {
      throw HTError.undefinedOperator(value.toString(), expr.op.lexeme);
    }
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var left = visitASTNode(expr.left);
    var right;
    if (expr.op.type == HTLexicon.logicalAnd) {
      if (left is bool) {
        // 如果逻辑和操作的左操作数是假，则直接返回，不再判断后面的值
        if (!left) {
          return false;
        } else {
          right = visitASTNode(expr.right);
          if (right is bool) {
            return left && right;
          } else {
            throw HTError.condition();
          }
        }
      } else {
        throw HTError.condition();
      }
    } else {
      right = visitASTNode(expr.right);

      // 操作符重载??
      if (expr.op.type == HTLexicon.logicalOr) {
        if (left is bool) {
          if (right is bool) {
            return left || right;
          } else {
            throw HTError.condition();
          }
        } else {
          throw HTError.condition();
        }
      } else if (expr.op.type == HTLexicon.equal) {
        return left == right;
      } else if (expr.op.type == HTLexicon.notEqual) {
        return left != right;
      } else if (expr.op.type == HTLexicon.add ||
          expr.op.type == HTLexicon.subtract) {
        if (expr.op.lexeme == HTLexicon.add) {
          return left + right;
        } else if (expr.op.lexeme == HTLexicon.subtract) {
          return left - right;
        }
      } else if (expr.op.type == HTLexicon.IS) {
        if (right is HTType) {
          final encapsulation = encapsulate(left);
          return encapsulation.rtType.isA(right);
        } else {
          throw HTError.notType(right.toString());
        }
      } else if (expr.op.type == HTLexicon.multiply) {
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
    }
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    final callee = visitASTNode(expr.callee);
    final positionalArgs = [];
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      positionalArgs.add(visitASTNode(expr.positionalArgs[i]));
    }

    final namedArgs = <String, dynamic>{};
    for (var name in expr.namedArgs.keys) {
      namedArgs[name] = visitASTNode(expr.namedArgs[name]!);
    }

    final typeArgs = <HTType>[];

    if (callee is HTFunction) {
      // if (!callee.isExtern) {
      // 普通函数
      // if (callee.funcType != FunctionType.constructor) {
      return callee.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
      // } else {
      //   final className = callee.classId!;
      //   final klass = global.fetch(className);
      //   if (klass is HTClass) {
      //     if (!klass.isExtern) {
      //       // 命名构造函数
      //       return klass.createInstance(
      //           constructorName: callee.id,
      //           positionalArgs: positionalArgs,
      //           namedArgs: namedArgs,
      //           typeArgs: typeArgs);
      //     } else {
      //       // 外部命名构造函数
      //       final externClass = fetchExternalClass(klass.id);
      //       final constructor = externClass.memberGet(callee.id);
      //       if (constructor is HTExternalFunction) {
      //         return constructor(
      //             positionalArgs: positionalArgs,
      //             namedArgs: namedArgs,
      //             typeArgs: typeArgs);
      //       } else {
      //         return Function.apply(
      //             constructor,
      //             positionalArgs,
      //             namedArgs
      //                 .map((key, value) => MapEntry(Symbol(key), value)));
      //         // throw HTErrorExternFunc(constructor.toString());
      //       }
      //     }
      //   } else {
      //     throw HTError.callable(callee.toString());
      //   }
      // }
      // } else {
      //   final externFunc = fetchExternalFunction(callee.id);
      //   if (externFunc is HTExternalFunction) {
      //     return externFunc(
      //         positionalArgs: positionalArgs,
      //         namedArgs: namedArgs,
      //         typeArgs: typeArgs);
      //   } else {
      //     return Function.apply(externFunc, positionalArgs,
      //         namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
      //     // throw HTErrorExternFunc(constructor.toString());
      //   }
      // }
    } else if (callee is HTClass) {
      if (callee.isAbstract) {
        throw HTError.abstracted();
      }

      final constructor = callee.memberGet(HTLexicon.constructor) as HTFunction;
      // constructor's context is on this newly created instance
      // constructor.context = instance.namespace;
      constructor.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);

      // if (!callee.isExtern) {
      //   // 默认构造函数
      //   return callee.createInstance(
      //       positionalArgs: positionalArgs,
      //       namedArgs: namedArgs,
      //       typeArgs: typeArgs);
      // } else {
      //   // 外部默认构造函数
      //   final externClass = fetchExternalClass(callee.id);
      //   final constructor = externClass.memberGet(callee.id);
      //   if (constructor is HTExternalFunction) {
      //     return constructor(
      //         positionalArgs: positionalArgs,
      //         namedArgs: namedArgs,
      //         typeArgs: typeArgs);
      //   } else {
      //     return Function.apply(constructor, positionalArgs,
      //         namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
      //     // throw HTErrorExternFunc(constructor.toString());
      //   }
      // }
    } // 外部函数
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        return callee(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        return Function.apply(callee, positionalArgs,
            namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        // throw HTErrorExternFunc(callee.toString());
      }
    } else {
      throw HTError.callable(callee.toString());
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
      _curNamespace.assignAt(expr.variable.lexeme, value, distance);
    } else {
      global.memberSet(expr.variable.lexeme, value);
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

    throw HTError.subGet(collection.toString());
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

    throw HTError.subGet(collection.toString());
  }

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var object = visitASTNode(expr.collection);

    // if (object is num) {
    //   object = HTNumber(object);
    // } else if (object is bool) {
    //   object = HTBoolean(object);
    // } else if (object is String) {
    //   object = HTString(object);
    // } else if (object is List) {
    //   object = HTList(object);
    // } else if (object is Map) {
    //   object = HTMap(object);
    // }

    if ((object is HTObject)) {
      return object.memberGet(expr.key.lexeme, from: _curNamespace.fullName);
    }
    //如果是Dart对象
    else {
      var typeString = object.runtimeType.toString();
      final id = HTType.parseBaseType(typeString);
      var externClass = fetchExternalClass(id);
      return externClass.instanceMemberGet(object, expr.key.lexeme);
    }
  }

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    dynamic object = visitASTNode(expr.collection);

    // if (object is num) {
    //   object = HTNumber(object);
    // } else if (object is bool) {
    //   object = HTBoolean(object);
    // } else if (object is String) {
    //   object = HTString(object);
    // } else if (object is List) {
    //   object = HTList(object);
    // } else if (object is Map) {
    //   object = HTMap(object);
    // }

    var value = visitASTNode(expr.value);
    if (object is HTObject) {
      object.memberSet(expr.key.lexeme, value, from: _curNamespace.fullName);
      return value;
    }
    //如果是Dart对象
    else {
      var typeString = object.runtimeType.toString();
      final id = HTType.parseBaseType(typeString);
      var externClass = fetchExternalClass(id);
      externClass.instanceMemberSet(object, expr.key.lexeme, value);
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
    return executeBlock(stmt.block, HTNamespace(this, closure: _curNamespace));
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
      throw HTError.condition();
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
      throw HTError.condition();
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
    // dynamic value;
    // if (stmt.initializer != null) {
    //   value = visitASTNode(stmt.initializer!);
    // }

    _curNamespace.define(HTAstVariable(
      stmt.id.lexeme,
      this,
      declType: stmt.declType,
      initializer: stmt.initializer,
      isDynamic: stmt.isDynamic,
      isExtern: stmt.isExtern,
      isImmutable: stmt.isImmutable,
    ));

    // return value;
  }

  @override
  dynamic visitParamDeclStmt(ParamDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
  }

  @override
  dynamic visitFuncDeclStmt(FuncDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    final func = HTAstFunction(stmt, this, context: _curNamespace);
    if (stmt.id != null) {
      _curNamespace.define(func);
    }
    return func;
  }

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    HTClass? superClass;
    if (stmt.id.lexeme != HTLexicon.object) {
      if (stmt.superClass == null) {
        superClass = global.fetch(HTLexicon.object);
      } else {
        HTClass existSuperClass =
            _getValue(stmt.superClass!.id.lexeme, stmt.superClass!);
        superClass = existSuperClass;
      }
    }

    final klass =
        HTClass(stmt.id.lexeme, this, _curModuleUniqueKey, _curNamespace,
            superClass: superClass,
            superClassType: null, // TODO: 这里需要修改
            isExtern: stmt.isExtern,
            isAbstract: stmt.isAbstract);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    _curNamespace.define(klass);

    var save = _curNamespace;
    _curNamespace = klass.namespace;

    for (final variable in stmt.variables) {
      if (stmt.isExtern && variable.isExtern) {
        throw HTError.externVar();
      }
      // dynamic value;
      // if (variable.initializer != null) {
      //   value = visitASTNode(variable.initializer!);
      // }

      final decl = HTAstVariable(variable.id.lexeme, this,
          declType: variable.declType,
          isDynamic: variable.isDynamic,
          isExtern: variable.isExtern,
          isImmutable: variable.isImmutable,
          isMember: true,
          isStatic: variable.isStatic);

      if (variable.isStatic) {
        klass.namespace.define(decl);
      } else {
        klass.defineInstanceMember(decl);
      }
    }

    _curNamespace = save;

    for (final method in stmt.methods) {
      HTFunction func;
      if (method.isStatic) {
        func = HTAstFunction(method, this, context: klass.namespace);
        klass.namespace.define(func, override: true);
      } else if (method.funcType == FunctionType.constructor) {
        func = HTAstFunction(method, this);
        klass.namespace.define(func, override: true);
      } else {
        func = HTAstFunction(method, this);
        klass.defineInstanceMember(func);
      }
    }

    // klass.inherit(superClass);

    return klass;
  }

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < stmt.enumerations.length; i++) {
      final id = stmt.enumerations[i];
      defs[id] = HTEnumItem(i, id, HTType(stmt.id.lexeme));
    }

    final enumClass =
        HTEnum(stmt.id.lexeme, defs, this, isExtern: stmt.isExtern);

    _curNamespace.define(enumClass);
  }
}
