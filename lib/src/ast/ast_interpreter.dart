import '../plugin/errorHandler.dart';
import '../plugin/moduleHandler.dart';
import '../extern_function.dart';
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
import '../extern_object.dart';
import '../enum.dart';
import 'ast_declaration.dart';
import '../declaration.dart';
import '../const_table.dart';

mixin AstInterpreterRef {
  late final HTAstInterpreter interpreter;
}

/// 负责对语句列表进行最终解释执行
class HTAstInterpreter extends Interpreter with ConstTable implements ASTNodeVisitor {
  var _curLine = 0;
  @override
  int get curLine => _curLine;
  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;
  late String _curModuleName;
  @override
  String get curModuleName => _curModuleName;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  final _distances = <ASTNode, int>{};

  dynamic _curStmtValue;

  String? _savedModuleName;

  HTAstInterpreter({bool debugMode = false, HTErrorHandler? errorHandler, HTModuleHandler? moduleHandler})
      : super(debugMode: debugMode, errorHandler: errorHandler, moduleHandler: moduleHandler);

  void saveSnapshot() {
    _savedModuleName = _curModuleName;
  }

  void resotreSnapshot() {
    _curModuleName = _savedModuleName!;
  }

  @override
  Future<dynamic> eval(
    String content, {
    String? moduleName,
    ParseStyle style = ParseStyle.module,
    bool debugMode = true,
    HTNamespace? namespace,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    _curModuleName = moduleName ?? HTLexicon.anonymousScript;
    curNamespace = namespace ?? global;

    var lexer = Lexer();
    var parser = HTAstParser(this);
    var resolver = HTAstResolver();
    try {
      var tokens = lexer.lex(content, _curModuleName);

      final statements = await parser.parse(tokens, _curModuleName, style);
      _distances.addAll(resolver.resolve(statements, _curModuleName));

      for (final stmt in statements) {
        _curStmtValue = visitASTNode(stmt);
      }

      if (invokeFunc != null) {
        if (style == ParseStyle.module) {
          return invoke(invokeFunc, positionalArgs: positionalArgs, namedArgs: namedArgs);
        }
      } else {
        return _curStmtValue;
      }
    } catch (e, stack) {
      var sb = StringBuffer();
      for (var funcName in HTFunction.callStack) {
        sb.writeln('  $funcName');
      }
      sb.writeln('\n$stack');
      var callStack = sb.toString();

      HTInterpreterError newErr;
      if (e is HTParserError) {
        newErr = HTInterpreterError(
            '${e.message}\nCall stack:\n$callStack', e.type, parser.curModuleName, parser.curLine, parser.curColumn);
      } else if (e is HTResolverError) {
        newErr = HTInterpreterError('${e.message}\nCall stack:\n$callStack', e.type, resolver.curFileName,
            resolver.curLine, resolver.curColumn);
      } else {
        newErr =
            HTInterpreterError('$e\nCall stack:\n$callStack', HTErrorType.other, _curModuleName, _curLine, _curColumn);
      }

      errorHandler.handle(newErr);
    }
  }

  dynamic _getValue(String name, ASTNode expr) {
    var distance = _distances[expr];
    if (distance != null) {
      return curNamespace.fetchAt(name, distance);
    }

    return global.memberGet(name);
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
        throw HTErrorUndefinedOperator(value.toString(), expr.op.lexeme);
      }
    } else if (expr.op.lexeme == HTLexicon.logicalNot) {
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
            throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
          }
        }
      } else {
        throw HTErrorUndefinedBinaryOperator(left.toString(), right.toString(), expr.op.lexeme);
      }
    } else {
      right = visitASTNode(expr.right);

      // 操作符重载??
      if (expr.op.type == HTLexicon.logicalOr) {
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
        if (callee.funcType != FunctionType.constructor) {
          return callee.call(positionalArgs, namedArgs);
        } else {
          final className = callee.className;
          final klass = global.memberGet(className!);
          if (klass is HTClass) {
            if (klass.classType != ClassType.extern) {
              // 命名构造函数
              return klass.createInstance(
                  constructorName: callee.id, positionalArgs: positionalArgs, namedArgs: namedArgs);
            } else {
              // 外部命名构造函数
              final externClass = fetchExternalClass(className);
              final constructor = externClass.memberGet(callee.id);
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
      if (callee.classType != ClassType.extern) {
        // 默认构造函数
        return callee.createInstance(positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else {
        // 外部默认构造函数
        final externClass = fetchExternalClass(callee.id);
        final constructor = externClass.memberGet(callee.id);
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
      return object.memberGet(expr.key.lexeme, from: curNamespace.fullName);
    }
    //如果是Dart对象
    else {
      var typeid = object.runtimeType.toString();
      if (typeid.contains('<')) {
        typeid = typeid.substring(0, typeid.indexOf('<'));
      }
      var externClass = fetchExternalClass(typeid);
      return externClass.instanceMemberGet(object, expr.key.lexeme);
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
      object.memberSet(expr.key.lexeme, value, from: curNamespace.fullName);
      return value;
    }
    //如果是Dart对象
    else {
      var typeid = object.runtimeType.toString();
      if (typeid.contains('<')) {
        typeid = typeid.substring(0, typeid.indexOf('<'));
      }
      var externClass = fetchExternalClass(typeid);
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
    // dynamic value;
    // if (stmt.initializer != null) {
    //   value = visitASTNode(stmt.initializer!);
    // }

    curNamespace.define(HTAstDecl(
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
    final func = HTAstFunction(stmt, this, context: curNamespace);
    if (stmt.id != null) {
      curNamespace
          .define(HTDeclaration(stmt.id!.lexeme, value: func, isExtern: stmt.isExtern, isStatic: stmt.isStatic));
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
        superClass = global.memberGet(HTLexicon.rootClass);
      } else {
        HTClass existSuperClass = _getValue(stmt.superClass!.id.lexeme, stmt.superClass!);
        superClass = existSuperClass;
      }
    }

    final klass = HTClass(stmt.id.lexeme, superClass, this, classType: stmt.classType, closure: curNamespace);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    curNamespace.define(HTDeclaration(stmt.id.lexeme, value: klass));

    var save = curNamespace;
    curNamespace = klass;

    for (final variable in stmt.variables) {
      if (stmt.classType != ClassType.extern && variable.isExtern) {
        throw HTErrorExternVar();
      }
      // dynamic value;
      // if (variable.initializer != null) {
      //   value = visitASTNode(variable.initializer!);
      // }

      final decl = HTAstDecl(variable.id.lexeme, this,
          declType: variable.declType,
          isDynamic: variable.isDynamic,
          isExtern: variable.isExtern,
          isImmutable: variable.isImmutable,
          isMember: true,
          isStatic: variable.isStatic);

      if (variable.isStatic) {
        klass.define(decl);
      } else {
        klass.defineInstance(decl);
      }
    }

    curNamespace = save;

    for (final method in stmt.methods) {
      HTFunction func;
      if (method.isStatic) {
        func = HTAstFunction(method, this, context: klass);
        klass.define(HTDeclaration(method.internalName, value: func, isExtern: method.isExtern), override: true);
      } else if (method.funcType == FunctionType.constructor) {
        func = HTAstFunction(method, this);
        klass.define(HTDeclaration(method.internalName, value: func, isExtern: method.isExtern), override: true);
      } else {
        func = HTAstFunction(method, this);
        klass.defineInstance(HTDeclaration(method.internalName, value: func, isExtern: method.isExtern));
      }
    }

    // 继承所有父类的成员变量和方法，忽略掉已经被覆盖的那些
    var curSuper = superClass;
    while (curSuper != null) {
      for (final decl in curSuper.instanceDecls.values) {
        if (decl.id.startsWith(HTLexicon.underscore)) {
          continue;
        }
        klass.defineInstance(decl.clone(), error: false);
      }

      curSuper = curSuper.superClass;
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

    curNamespace.define(HTDeclaration(stmt.id.lexeme, value: enumClass));
  }
}
