import '../source/source_provider.dart';
import '../binding/external_function.dart';
import '../type_system/type.dart';
import '../core/namespace/namespace.dart';
import '../core/function/abstract_function.dart';
import '../core/object.dart';
import '../core/abstract_interpreter.dart';
import '../core/class/enum.dart';
import '../core/class/class.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../error/errors.dart';
import '../error/error_handler.dart';
import 'ast/ast.dart';
import 'element/ast_function.dart';
import 'parser.dart';
import 'ast_source.dart';

mixin AnalyzerRef {
  late final HTAnalyzer interpreter;
}

class HTBreak {}

class HTContinue {}

/// 负责对语句列表进行最终解释执行
class HTAnalyzer extends HTInterpreter implements AbstractAstVisitor {
  late HTAstParser _curParser;
  final _sources = HTAstCompilation();

  late HTAstModule _curCode;

  var _curLine = 0;
  @override
  int get curLine => _curLine;
  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;
  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  String? _curSymbol;
  @override
  String? get curSymbol => _curSymbol;
  String? _curObjectSymbol;
  @override
  String? get curObjectSymbol => _curObjectSymbol;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  // final _distances = <AstNode, int>{};

  dynamic _curStmtValue;

  late String _savedModuleName;
  late HTNamespace _savedNamespace;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  HTAnalyzer(
      {bool debugMode = false,
      HTErrorHandler? errorHandler,
      SourceProvider? sourceProvider})
      : super(errorHandler: errorHandler, sourceProvider: sourceProvider);

  @override
  Future<dynamic> eval(String content,
      {String? moduleFullName,
      HTNamespace? namespace,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    _savedModuleName = _curModuleFullName;
    _savedNamespace = _curNamespace;

    _curParser = HTAstParser(this);

    _curModuleFullName = moduleFullName ?? HTLexicon.anonymousScript;
    _curNamespace = namespace ?? global;

    try {
      final compilation = await _curParser.parse(
          content, sourceProvider, _curModuleFullName, config);

      _sources.addAll(compilation);

      for (final source in compilation.sources) {
        _curCode = source;
        _curModuleFullName = source.fullName;
        for (final stmt in source.nodes) {
          _curStmtValue = visitASTNode(stmt);
        }
      }

      _curModuleFullName = _savedModuleName;
      _curNamespace = _savedNamespace;

      if (invokeFunc != null) {
        if (config.sourceType == SourceType.module) {
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
        if (error.type == ErrorType.compileError) {
          error.moduleFullName = _curParser.curModuleFullName;
          error.line = _curParser.curLine;
          error.column = _curParser.curColumn;
        } else {
          error.moduleFullName = _curModuleFullName;
          error.line = _curLine;
          error.column = _curColumn;
        }
        errorHandler.handle(error);
      } else {
        final hetuError = HTError(ErrorCode.extern, ErrorType.externalError,
            message: '$error\nCall stack:\n$callStack',
            moduleFullName: _curModuleFullName,
            line: _curLine,
            column: _curColumn);
        errorHandler.handle(hetuError);
      }
    }
  }

  /// 解析文件
  @override
  Future<dynamic> import(String key,
      {String? curModuleFullName,
      String? moduleName,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) async {
    dynamic result;

    final module = await sourceProvider.getSource(key,
        curModuleFullName: curModuleFullName != HTLexicon.anonymousScript
            ? curModuleFullName
            : null);
    curModuleFullName = module.fullName;

    HTNamespace? namespace;
    if ((moduleName != null) && (moduleName != HTLexicon.global)) {
      namespace = HTNamespace(this, id: moduleName, closure: global);
      global.define(namespace);
    }

    result = eval(module.content,
        moduleFullName: curModuleFullName,
        namespace: namespace,
        config: config,
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

  // dynamic _getValue(String name, AstNode expr) {
  //   var distance = _distances[expr];
  //   if (distance != null) {
  //     return _curNamespace.fetchAt(name, distance);
  //   }

  //   return global.fetch(name);
  // }

  dynamic executeBlock(Iterable<AstNode> statements, HTNamespace environment) {
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

  dynamic visitASTNode(AstNode ast) => ast.accept(this);

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
    return _curCode.constTable.getInt64(expr.constIndex);
  }

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return _curCode.constTable.getFloat64(expr.constIndex);
  }

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return _curCode.constTable.getUtf8String(expr.constIndex);
  }

  @override
  dynamic visitGroupExpr(GroupExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    return visitASTNode(expr.inner);
  }

  @override
  dynamic visitLiteralListExpr(LiteralListExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var list = [];
    for (final item in expr.vector) {
      list.add(visitASTNode(item));
    }
    return list;
  }

  @override
  dynamic visitLiteralMapExpr(LiteralMapExpr expr) {
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
    return _curNamespace.fetch(expr.id.lexeme);
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
    if (expr.op == HTLexicon.logicalAnd) {
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
      if (expr.op == HTLexicon.logicalOr) {
        if (left is bool) {
          if (right is bool) {
            return left || right;
          } else {
            throw HTError.condition();
          }
        } else {
          throw HTError.condition();
        }
      } else if (expr.op == HTLexicon.equal) {
        return left == right;
      } else if (expr.op == HTLexicon.notEqual) {
        return left != right;
      } else if (expr.op == HTLexicon.add || expr.op == HTLexicon.subtract) {
        if (expr.op == HTLexicon.add) {
          return left + right;
        } else if (expr.op == HTLexicon.subtract) {
          return left - right;
        }
      } else if (expr.op == HTLexicon.IS) {
        if (right is HTType) {
          final encapsulation = encapsulate(left);
          return encapsulation.valueType.isA(right);
        } else {
          throw HTError.notType(right.toString());
        }
      } else if (expr.op == HTLexicon.multiply) {
        return left * right;
      } else if (expr.op == HTLexicon.devide) {
        return left / right;
      } else if (expr.op == HTLexicon.modulo) {
        return left % right;
      } else if (expr.op == HTLexicon.greater) {
        return left > right;
      } else if (expr.op == HTLexicon.greaterOrEqual) {
        return left >= right;
      } else if (expr.op == HTLexicon.lesser) {
        return left < right;
      } else if (expr.op == HTLexicon.lesserOrEqual) {
        return left <= right;
      }
    }
  }

  @override
  dynamic visitTernaryExpr(TernaryExpr expr) {}

  @override
  dynamic visitTypeExpr(TypeExpr expr) {}

  @override
  dynamic visitParamTypeExpr(ParamTypeExpr expr) {}

  @override
  dynamic visitFunctionTypeExpr(TypeExpr expr) {}

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
      // if (!callee.isExternal) {
      // 普通函数
      // if (callee.category != FunctionType.constructor) {
      return callee.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
      // } else {
      //   final className = callee.classId!;
      //   final klass = global.fetch(className);
      //   if (klass is HTClass) {
      //     if (!klass.isExternal) {
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
      //                 .map<Symbol, dynamic>((key, value) => MapEntry(Symbol(key), value)));
      //         // throw HTErrorExternFunc(constructor.toString());
      //       }
      //     }
      //   } else {
      //     throw HTError.callable(callee.toString());
      //   }
      // }
      // } else {
      //   final externalFuncDef = fetchExternalFunction(callee.id);
      //   if (externalFuncDef is HTExternalFunction) {
      //     return externalFuncDef(
      //         positionalArgs: positionalArgs,
      //         namedArgs: namedArgs,
      //         typeArgs: typeArgs);
      //   } else {
      //     return Function.apply(externalFuncDef, positionalArgs,
      //         namedArgs.map<Symbol, dynamic>((key, value) => MapEntry(Symbol(key), value)));
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

      // if (!callee.isExternal) {
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
      //         namedArgs.map<Symbol, dynamic>((key, value) => MapEntry(Symbol(key), value)));
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
        return Function.apply(
            callee,
            positionalArgs,
            namedArgs.map<Symbol, dynamic>(
                (key, value) => MapEntry(Symbol(key), value)));
        // throw HTErrorExternFunc(callee.toString());
      }
    } else {
      throw HTError.notCallable(callee.toString());
    }
  }

  @override
  dynamic visitUnaryPostfixExpr(UnaryPostfixExpr expr) {}

  // @override
  // dynamic visitAssignExpr(AssignExpr expr) {
  // var value = visitASTNode(expr.value);
  // var distance = _distances[expr];
  // if (distance != null) {
  //   // 尝试设置当前环境中的本地变量
  //   _curNamespace.assignAt(expr.variable.lexeme, value, distance);
  // } else {
  //   global.memberSet(expr.variable.lexeme, value);
  // }

  // // 返回右值
  // return value;
  // }

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {
    _curLine = expr.line;
    _curColumn = expr.column;
    var collection = visitASTNode(expr.collection);
    var key = visitASTNode(expr.key);
    if (collection is List || collection is Map) {
      return collection[key];
    }

    throw HTError.notList(collection.toString());
  }

  // @override
  // dynamic visitSubSetExpr(SubSetExpr expr) {
  //   _curLine = expr.line;
  //   _curColumn = expr.column;
  //   var collection = visitASTNode(expr.collection);
  //   var key = visitASTNode(expr.key);
  //   var value = visitASTNode(expr.value);
  //   if ((collection is List) || (collection is Map)) {
  //     collection[key] = value;
  //     return value;
  //   }

  //   throw HTError.notList(collection.toString());
  // }

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

  // @override
  // dynamic visitMemberSetExpr(MemberSetExpr expr) {
  //   _curLine = expr.line;
  //   _curColumn = expr.column;
  //   dynamic object = visitASTNode(expr.collection);

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

  //   var value = visitASTNode(expr.value);
  //   if (object is HTObject) {
  //     object.memberSet(expr.key.lexeme, value, from: _curNamespace.fullName);
  //     return value;
  //   }
  //   //如果是Dart对象
  //   else {
  //     var typeString = object.runtimeType.toString();
  //     final id = HTType.parseBaseType(typeString);
  //     var externClass = fetchExternalClass(id);
  //     externClass.instanceMemberSet(object, expr.key.lexeme, value);
  //     return value;
  //   }
  // }

  // @override
  // dynamic visitImportStmt(ImportStmt stmt) {
  //   _curLine = stmt.line;
  //   _curColumn = stmt.column;
  // }

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
    return executeBlock(
        stmt.statements, HTNamespace(this, closure: _curNamespace));
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
  dynamic visitDoStmt(DoStmt stmt) {}

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
  dynamic visitVarDeclStmt(VarDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    // dynamic value;
    // if (stmt.initializer != null) {
    //   value = visitASTNode(stmt.initializer!);
    // }

    // _curNamespace.define(HTAstVariable(
    //   stmt.id,
    //   this,
    //   declType: stmt.declType,
    //   initializer: stmt.initializer,
    //   isDynamic: stmt.isDynamic,
    //   isExternal: stmt.isExternal,
    //   isImmutable: stmt.isImmutable,
    // ));

    // return value;
  }

  @override
  dynamic visitParamDeclStmt(ParamDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
  }

  @override
  dynamic visitFuncDeclStmt(FuncDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    final func = HTAstFunction(stmt, this, context: _curNamespace);
    if (stmt.id != null) {
      _curNamespace.define(func);
    }
    return func;
  }

  @override
  dynamic visitClassDeclStmt(ClassDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    HTClass? superClass;
    if (stmt.id.lexeme != HTLexicon.object) {
      // if (stmt.superClass == null) {
      //   superClass = global.fetch(HTLexicon.object);
      // } else {
      //   HTClass existSuperClass =
      //       _getValue(stmt.superClass!.id.lexeme, stmt.superClass!);
      //   superClass = existSuperClass;
      // }
    }

    final klass = HTClass(
        stmt.id.lexeme, this, _curModuleFullName, _curNamespace,
        superClass: superClass,
        isExternal: stmt.isExternal,
        isAbstract: stmt.isAbstract);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    _curNamespace.define(klass);

    var save = _curNamespace;
    _curNamespace = klass.namespace;

    for (final variable in stmt.variables) {
      if (stmt.isExternal && variable.isExternal) {
        throw HTError.externalVar();
      }
      // dynamic value;
      // if (variable.initializer != null) {
      //   value = visitASTNode(variable.initializer!);
      // }

      // final decl = HTAstVariable(variable.id, this,
      //     declType: variable.declType,
      //     isDynamic: variable.isDynamic,
      //     isExternal: variable.isExternal,
      //     isImmutable: variable.isImmutable,
      //     isMember: true,
      //     isStatic: variable.isStatic);

      // if (variable.isStatic) {
      //   klass.namespace.define(decl);
      // } else {
      //   klass.defineInstanceMember(decl);
      // }
    }

    _curNamespace = save;

    for (final method in stmt.methods) {
      HTFunction func;
      if (method.isStatic) {
        func = HTAstFunction(method, this, context: klass.namespace);
        klass.namespace.define(func, override: true);
      } else if (method.category == FunctionCategory.constructor) {
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
  dynamic visitEnumDeclStmt(EnumDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < stmt.enumerations.length; i++) {
      // final id = stmt.enumerations[i];
      // defs[id] = HTEnumItem(i, id, HTType(stmt.id.lexeme));
    }

    final enumClass =
        HTEnum(stmt.id.lexeme, defs, this, isExternal: stmt.isExternal);

    _curNamespace.define(enumClass);
  }
}
