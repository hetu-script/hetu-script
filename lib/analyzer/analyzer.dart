import '../source/source_provider.dart';
// import '../binding/external_function.dart';
import '../type/type.dart';
import '../core/namespace/namespace.dart';
// import '../core/function/abstract_function.dart';
// import '../core/object.dart';
import '../core/abstract_interpreter.dart';
// import '../core/class/enum.dart';
// import '../core/class/class.dart';
import '../grammar/lexicon.dart';
// import '../source/source.dart';
import '../error/errors.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
// import 'ast_function.dart';
import '../ast/parser.dart';
import '../ast/ast_source.dart';

class HTBreak {}

class HTContinue {}

class HTAnalyzer extends AbstractInterpreter implements AbstractAstVisitor {
  @override
  late HTAstParser parser;

  final _sources = HTAstLibrary('');

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
  // String? _curObjectSymbol;
  // @override
  // String? get curLeftValue => _curObjectSymbol;

  /// 本地变量表，不同语句块和环境的变量可能会有重名。
  /// 这里用表达式而不是用变量名做key，用表达式的值所属环境相对位置作为value
  // final _distances = <AstNode, int>{};

  HTType? _curExprType;

  late String _savedModuleName;
  late HTNamespace _savedNamespace;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  HTAnalyzer(
      {bool debugMode = false,
      HTErrorHandler? errorHandler,
      SourceProvider? sourceProvider})
      : super(errorHandler: errorHandler, sourceProvider: sourceProvider) {
    _curNamespace = HTNamespace(this);
  }

  @override
  Future<void> eval(String content,
      {String? moduleFullName,
      bool createNamespace = true,
      HTNamespace? namespace,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    _savedModuleName = _curModuleFullName;
    _savedNamespace = _curNamespace;

    parser = HTAstParser();

    _curModuleFullName = moduleFullName ?? HTLexicon.anonymousScript;
    _curNamespace = namespace ?? HTNamespace(this, id: _curModuleFullName);

    try {
      final compilation = await parser.parse(content,
          moduleFullName: _curModuleFullName,
          sourceProvider: sourceProvider,
          config: config);

      _sources.join(compilation);

      for (final source in compilation.modules) {
        _curCode = source;
        _curModuleFullName = source.fullName;
        for (final stmt in source.nodes) {
          visitAstNode(stmt);
        }
      }

      _curModuleFullName = _savedModuleName;
      _curNamespace = _savedNamespace;
    } catch (error, stack) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, stack);
      }
    }
  }

  /// 解析文件
  @override
  Future<void> import(String key,
      {String? curModuleFullName,
      String? moduleAliasName,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) async {
    final fullName = sourceProvider.resolveFullName(key);

    if (config.reload || !sourceProvider.hasModule(fullName)) {
      final module = await sourceProvider.getSource(key,
          curModuleFullName: curModuleFullName);

      final savedNamespace = _curNamespace;
      final moduleName = moduleAliasName ?? module.fullName;
      _curNamespace = HTNamespace(this, id: moduleName);

      await eval(module.content,
          moduleFullName: module.fullName,
          namespace: _curNamespace,
          config: config,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);

      _curNamespace = savedNamespace;
    }
  }

  @override
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    throw HTError.unsupported('invoke on analyzer');
  }

  // dynamic _getValue(String name, AstNode expr) {
  //   var distance = _distances[expr];
  //   if (distance != null) {
  //     return _curNamespace.fetchAt(name, distance);
  //   }

  //   return global.fetch(name);
  // }

  dynamic visitAstNode(AstNode ast) => ast.accept(this);

  @override
  dynamic visitCommentExpr(CommentExpr expr) {}

  @override
  dynamic visitNullExpr(NullExpr expr) {}

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) {}

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) {}

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {}

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {}

  @override
  dynamic visitLiteralListExpr(LiteralListExpr expr) {
    for (final item in expr.list) {
      visitAstNode(item);
    }
  }

  @override
  dynamic visitLiteralMapExpr(LiteralMapExpr expr) {
    for (final key_expr in expr.map.keys) {
      visitAstNode(key_expr);
      visitAstNode(expr.map[key_expr]!);
    }
  }

  @override
  dynamic visitGroupExpr(GroupExpr expr) {
    visitAstNode(expr.inner);
  }

  @override
  dynamic visitSymbolExpr(SymbolExpr expr) {
    return _curNamespace.memberGet(expr.id);
  }

  @override
  dynamic visitTypeExpr(TypeExpr expr) {}

  @override
  dynamic visitParamTypeExpr(ParamTypeExpr expr) {}

  @override
  dynamic visitFunctionTypeExpr(FuncTypeExpr expr) {}

  @override
  dynamic visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    visitAstNode(expr.value);
  }

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    visitAstNode(expr.left);
    visitAstNode(expr.right);
  }

  @override
  dynamic visitTernaryExpr(TernaryExpr expr) {
    visitAstNode(expr.condition);
    visitAstNode(expr.elseBranch);
    visitAstNode(expr.thenBranch);
  }

  @override
  dynamic visitUnaryPostfixExpr(UnaryPostfixExpr expr) {}

  @override
  dynamic visitMemberExpr(MemberExpr expr) {
    visitAstNode(expr.object);
    // visitAstNode(expr.key);
  }

  @override
  dynamic visitMemberAssignExpr(MemberAssignExpr expr) {}

  @override
  dynamic visitSubExpr(SubExpr expr) {
    visitAstNode(expr.array);
    visitAstNode(expr.key);
  }

  @override
  dynamic visitSubAssignExpr(SubAssignExpr expr) {}

  @override
  dynamic visitCallExpr(CallExpr expr) {
    visitAstNode(expr.callee);
    for (var i = 0; i < expr.positionalArgs.length; ++i) {
      visitAstNode(expr.positionalArgs[i]);
    }
    for (var name in expr.namedArgs.keys) {
      visitAstNode(expr.namedArgs[name]!);
    }
  }

  @override
  dynamic visitExprStmt(ExprStmt stmt) {
    if (stmt.expr != null) {
      visitAstNode(stmt.expr!);
    }
  }

  @override
  dynamic visitBlockStmt(BlockStmt block) {
    var saved_context = _curNamespace;
    _curNamespace = HTNamespace(this, closure: _curNamespace);
    for (final stmt in block.statements) {
      visitAstNode(stmt);
    }
    _curNamespace = saved_context;
  }

  @override
  dynamic visitLibraryStmt(LibraryStmt stmt) {}

  @override
  dynamic visitImportStmt(ImportStmt stmt) {}

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {
    if (stmt.value != null) {
      visitAstNode(stmt.value!);
    }
  }

  @override
  dynamic visitIfStmt(IfStmt stmt) {
    visitAstNode(stmt.condition);
    visitAstNode(stmt.thenBranch);
    if (stmt.elseBranch != null) {
      visitAstNode(stmt.elseBranch!);
    }
  }

  @override
  dynamic visitWhileStmt(WhileStmt stmt) {
    if (stmt.condition != null) {
      visitAstNode(stmt.condition!);
    }
    visitAstNode(stmt.loop);
  }

  @override
  dynamic visitDoStmt(DoStmt stmt) {
    visitAstNode(stmt.loop);
    if (stmt.condition != null) {
      visitAstNode(stmt.condition!);
    }
  }

  @override
  dynamic visitForInStmt(ForInStmt stmt) {
    visitAstNode(stmt.declaration);
    visitAstNode(stmt.collection);
    visitAstNode(stmt.loop);
  }

  @override
  dynamic visitForStmt(ForStmt stmt) {
    if (stmt.declaration != null) {
      visitAstNode(stmt.declaration!);
    }
    if (stmt.condition != null) {
      visitAstNode(stmt.condition!);
    }
    if (stmt.increment != null) {
      visitAstNode(stmt.increment!);
    }
    visitAstNode(stmt.loop);
  }

  @override
  dynamic visitWhenStmt(WhenStmt stmt) {
    if (stmt.condition != null) {
      visitAstNode(stmt.condition!);
    }
  }

  @override
  dynamic visitBreakStmt(BreakStmt stmt) {
    throw HTBreak();
  }

  @override
  dynamic visitContinueStmt(ContinueStmt stmt) {
    throw HTContinue();
  }

  @override
  dynamic visitVarDeclStmt(VarDeclStmt stmt) {
    // dynamic value;
    // if (stmt.initializer != null) {
    //   value = visitAstNode(stmt.initializer!);
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
  dynamic visitParamDeclStmt(ParamDeclExpr stmt) {}

  @override
  dynamic visitReferConstructorExpr(ReferConstructorExpr stmt) {}

  @override
  dynamic visitFuncDeclStmt(FuncDeclExpr stmt) {
    // final func = HTAstFunction(stmt, this, context: _curNamespace);
    // if (stmt.id != null) {
    //   _curNamespace.define(func);
    // }
    // return func;
  }

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {
    // HTClass? superClass;
    if (stmt.id != HTLexicon.object) {
      // if (stmt.superClass == null) {
      //   superClass = global.fetch(HTLexicon.object);
      // } else {
      //   HTClass existSuperClass =
      //       _getValue(stmt.superClass!.id.lexeme, stmt.superClass!);
      //   superClass = existSuperClass;
      // }
    }

    // final klass = HTClass(stmt.id, this, _curModuleFullName, _curNamespace,
    //     superClass: superClass,
    //     isExternal: stmt.isExternal,
    //     isAbstract: stmt.isAbstract);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    // _curNamespace.define(klass);

    var save = _curNamespace;
    // _curNamespace = klass.namespace;

    // for (final variable in stmt.variables) {
    //   if (stmt.isExternal && variable.isExternal) {
    //     throw HTError.externalVar();
    //   }
    // dynamic value;
    // if (variable.initializer != null) {
    //   value = visitAstNode(variable.initializer!);
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
    // }

    _curNamespace = save;

    // for (final method in stmt.methods) {
    //   HTFunction func;
    //   if (method.isStatic) {
    //     func = HTAstFunction(method, this, context: klass.namespace);
    //     klass.namespace.define(func, override: true);
    //   } else if (method.category == FunctionCategory.constructor) {
    //     func = HTAstFunction(method, this);
    //     klass.namespace.define(func, override: true);
    //   } else {
    //     func = HTAstFunction(method, this);
    //     klass.defineInstanceMember(func);
    //   }
    // }

    // klass.inherit(superClass);

    // return klass;
  }

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {
    // var defs = <String, HTEnumItem>{};
    for (var i = 0; i < stmt.enumerations.length; i++) {
      // final id = stmt.enumerations[i];
      // defs[id] = HTEnumItem(i, id, HTType(stmt.id.lexeme));
    }

    // final enumClass = HTEnum(stmt.id, defs, this, isExternal: stmt.isExternal);

    // _curNamespace.define(enumClass);
  }
}
