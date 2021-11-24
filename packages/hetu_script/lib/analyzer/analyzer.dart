import '../source/source.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../type/type.dart';
import '../declaration/generic/generic_type_parameter.dart';
import '../declaration/namespace/namespace.dart';
import '../interpreter/abstract_interpreter.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import '../parser/parser.dart';
// import '../declaration/declaration.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/function/function_declaration.dart';
import '../declaration/function/parameter_declaration.dart';
import '../declaration/variable/variable_declaration.dart';
import '../parser/parse_result_compilation.dart';
import 'analysis_result.dart';
import 'analysis_error.dart';
// import 'type_checker.dart';
import '../declaration/struct/struct_declaration.dart';
import '../grammar/semantic.dart';
// import '../ast/visitor/recursive_ast_visitor.dart';

class HTAnalyzer extends HTAbstractInterpreter<HTModuleAnalysisResult>
    implements AbstractAstVisitor<void> {
  @override
  final stackTrace = const <String>[];

  final errorProcessors = <ErrorProcessor>[];

  @override
  final config = InterpreterConfig();

  @override
  ErrorHandlerConfig get errorConfig => config;

  String? _curSymbol;
  String? get curSymbol => _curSymbol;

  var _curLine = 0;
  @override
  int get curLine => _curLine;

  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;

  @override
  final HTNamespace global;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  late HTSource _curSource;
  @override
  String get curModuleFullName => _curSource.name;

  SourceType? _curSourceType;

  @override
  SourceType get curSourceType => _curSourceType ?? _curSource.type;

  // HTClassDeclaration? _curClass;
  // HTFunctionDeclaration? _curFunction;

  /// Errors of a single file
  final _curErrors = <HTAnalysisError>[];

  /// Errors of an analyis context.
  final errors = <HTAnalysisError>[];

  // late HTTypeChecker _curTypeChecker;

  late HTModuleParseResultCompilation compilation;

  @override
  final HTResourceContext<HTSource> sourceContext;

  final analyzedDeclarations = <String, HTNamespace>{};

  HTAnalyzer({HTResourceContext<HTSource>? sourceContext})
      : global = HTNamespace(id: SemanticNames.global),
        sourceContext = sourceContext ?? HTOverlayContext() {
    _curNamespace = global;
  }

  /// Analyzer should never throw.
  @override
  void handleError(Object error, {Object? externalStackTrace}) {}

  @override
  HTModuleAnalysisResult evalSource(HTSource source,
      {String? libraryName,
      bool globallyImport = false,
      String? invokeFunc, // ignored in analyzer
      List<dynamic> positionalArgs = const [], // ignored in analyzer
      Map<String, dynamic> namedArgs = const {}, // ignored in analyzer
      List<HTType> typeArgs = const [], // ignored in analyzer
      bool errorHandled = false // ignored in analyzer
      }) {
    errors.clear();
    _curSource = source;
    final parser = HTParser(context: sourceContext);
    compilation = parser.parseToCompilation(source, libraryName: libraryName);
    final results = <String, HTModuleAnalysisResult>{};
    for (final module in compilation.modules.values) {
      _curErrors.clear();
      final analysisErrors =
          module.errors.map((err) => HTAnalysisError.fromError(err)).toList();
      _curErrors.addAll(analysisErrors);
      _curNamespace = HTNamespace(id: module.fullName, closure: global);
      for (final node in module.nodes) {
        analyzeAst(node);
      }
      final moduleAnalysisResult =
          HTModuleAnalysisResult(module, this, analysisErrors, _curNamespace);
      results[moduleAnalysisResult.fullName] = moduleAnalysisResult;
      errors.addAll(_curErrors);
    }
    final result = results[source.name]!;
    if ((source.type == SourceType.script) || globallyImport) {
      global.import(result.namespace);
    }
    // walk through ast again to set each symbol's declaration referrence.
    // final visitor = _OccurrencesVisitor();
    // for (final node in result.parseResult.nodes) {
    //   node.accept(visitor);
    // }
    return result;
  }

  void analyzeAst(AstNode node) {
    node.accept(this);
  }

  @override
  void visitEmptyExpr(EmptyExpr expr) {}

  @override
  void visitCommentExpr(CommentExpr expr) {}

  @override
  void visitNullExpr(NullExpr expr) {}

  @override
  void visitBooleanExpr(BooleanExpr expr) {}

  @override
  void visitConstIntExpr(ConstIntExpr expr) {}

  @override
  void visitConstFloatExpr(ConstFloatExpr expr) {}

  @override
  void visitConstStringExpr(ConstStringExpr expr) {}

  @override
  void visitStringInterpolationExpr(StringInterpolationExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitIdentifierExpr(IdentifierExpr expr) {
    expr.analysisNamespace = _curNamespace;
    // print(
    //     'visited symbol: ${expr.id}, line: ${expr.line}, col: ${expr.column}, file: $curModuleFullName');
  }

  @override
  void visitListExpr(ListExpr expr) {
    expr.subAccept(this);
  }

  // @override
  // void visitMapExpr(MapExpr expr) {
  //   expr.subAccept(this);
  // }

  @override
  void visitGroupExpr(GroupExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitTypeExpr(TypeExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitParamTypeExpr(ParamTypeExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitFunctionTypeExpr(FuncTypeExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitBinaryExpr(BinaryExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitTernaryExpr(TernaryExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitMemberExpr(MemberExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitMemberAssignExpr(MemberAssignExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitSubExpr(SubExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitSubAssignExpr(SubAssignExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitCallExpr(CallExpr expr) {
    expr.subAccept(this);
  }

  @override
  void visitExprStmt(ExprStmt stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitBlockStmt(BlockStmt block) {
    block.subAccept(this);
  }

  @override
  void visitReturnStmt(ReturnStmt stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitIfStmt(IfStmt ifStmt) {
    ifStmt.subAccept(this);
  }

  @override
  void visitWhileStmt(WhileStmt ifStmt) {
    ifStmt.subAccept(this);
  }

  @override
  void visitDoStmt(DoStmt ifStmt) {
    ifStmt.subAccept(this);
  }

  @override
  void visitForStmt(ForStmt ifStmt) {
    ifStmt.subAccept(this);
  }

  @override
  void visitForInStmt(ForInStmt ifStmt) {
    ifStmt.subAccept(this);
  }

  @override
  void visitWhenStmt(WhenStmt stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitBreakStmt(BreakStmt stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitContinueStmt(ContinueStmt stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitLibraryDecl(LibraryDecl stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitImportDecl(ImportDecl stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitNamespaceDecl(NamespaceDecl stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitTypeAliasDecl(TypeAliasDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    stmt.declaration = HTVariableDeclaration(stmt.id.id,
        classId: stmt.classId, closure: _curNamespace, source: _curSource);
    _curNamespace.define(stmt.id.id, stmt.declaration!);
    stmt.subAccept(this);
  }

  @override
  void visitVarDecl(VarDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    stmt.declaration = HTVariableDeclaration(stmt.id.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        declType: HTType.fromAst(stmt.declType),
        isExternal: stmt.isExternal,
        isStatic: stmt.isStatic,
        isConst: stmt.isConst,
        isMutable: stmt.isMutable);
    _curNamespace.define(stmt.id.id, stmt.declaration!);
    stmt.subAccept(this);
  }

  @override
  void visitParamDecl(ParamDecl stmt) {
    stmt.declaration = HTParameterDeclaration(stmt.id.id,
        closure: _curNamespace,
        source: _curSource,
        declType: HTType.fromAst(stmt.declType),
        isOptional: stmt.isOptional,
        isNamed: stmt.isNamed,
        isVariadic: stmt.isVariadic);
    _curNamespace.define(stmt.id.id, stmt.declaration!);
    stmt.subAccept(this);
  }

  @override
  void visitReferConstructCallExpr(RedirectingConstructorCallExpr stmt) {
    stmt.subAccept(this);
  }

  @override
  void visitFuncDecl(FuncDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    stmt.id?.accept(this);
    for (final param in stmt.genericTypeParameters) {
      visitGenericTypeParamExpr(param);
    }
    stmt.returnType?.accept(this);
    stmt.redirectingCtorCallExpr?.accept(this);
    final namespace =
        HTNamespace(id: stmt.internalName, closure: _curNamespace);
    final savedCurNamespace = _curNamespace;
    _curNamespace = namespace;
    for (final arg in stmt.paramDecls) {
      visitParamDecl(arg);
    }
    if (stmt.definition != null) {
      analyzeAst(stmt.definition!);
    }
    _curNamespace = savedCurNamespace;
    stmt.declaration = HTFunctionDeclaration(stmt.internalName,
        id: stmt.id?.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        isExternal: stmt.isExternal,
        isStatic: stmt.isStatic,
        isConst: stmt.isConst,
        category: stmt.category,
        externalTypeId: stmt.externalTypeId,
        paramDecls: stmt.paramDecls.asMap().map((key, param) => MapEntry(
            param.id.id,
            HTParameterDeclaration(param.id.id,
                closure: _curNamespace,
                declType: HTType.fromAst(param.declType),
                isOptional: param.isOptional,
                isNamed: param.isNamed,
                isVariadic: param.isVariadic))),
        returnType: HTType.fromAst(stmt.returnType),
        isVariadic: stmt.isVariadic,
        minArity: stmt.minArity,
        maxArity: stmt.maxArity,
        namespace: namespace);
    _curNamespace.define(stmt.internalName, stmt.declaration!);
  }

  @override
  void visitClassDecl(ClassDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    visitIdentifierExpr(stmt.id);
    for (final param in stmt.genericTypeParameters) {
      visitGenericTypeParamExpr(param);
    }
    stmt.superType?.accept(this);
    for (final implementsType in stmt.implementsTypes) {
      visitTypeExpr(implementsType);
    }
    for (final withType in stmt.withTypes) {
      visitTypeExpr(withType);
    }
    final decl = HTClassDeclaration(
        id: stmt.id.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        genericTypeParameters: stmt.genericTypeParameters
            .map((param) => HTGenericTypeParameter(param.id.id))
            .toList(),
        superType: HTType.fromAst(stmt.superType),
        implementsTypes:
            stmt.implementsTypes.map((param) => HTType.fromAst(param)),
        withTypes: stmt.withTypes.map((param) => HTType.fromAst(param)),
        isExternal: stmt.isExternal,
        isAbstract: stmt.isAbstract,
        isTopLevel: stmt.isTopLevel,
        isExported: stmt.isExported);
    final savedCurNamespace = _curNamespace;
    stmt.declaration = decl;
    _curNamespace = decl.namespace;
    visitBlockStmt(stmt.definition);
    _curNamespace = savedCurNamespace;
    _curNamespace.define(stmt.id.id, decl);
  }

  @override
  void visitEnumDecl(EnumDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    visitIdentifierExpr(stmt.id);
    stmt.declaration = HTClassDeclaration(
        id: stmt.id.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        isExternal: stmt.isExternal);
    _curNamespace.define(stmt.id.id, stmt.declaration!);
  }

  @override
  void visitStructDecl(StructDecl stmt) {
    _curLine = stmt.line;
    _curColumn = stmt.column;
    stmt.id.accept(this);
    final savedCurNamespace = _curNamespace;
    _curNamespace = HTNamespace(id: stmt.id.id, closure: _curNamespace);
    for (final decl in stmt.fields) {
      analyzeAst(decl);
    }
    stmt.declaration = HTStructDeclaration(_curNamespace,
        id: stmt.id.id,
        closure: savedCurNamespace,
        source: _curSource,
        prototypeId: stmt.prototypeId?.id,
        isTopLevel: stmt.isTopLevel,
        isExported: stmt.isExported);
    _curNamespace = savedCurNamespace;
    _curNamespace.define(stmt.id.id, stmt.declaration!);
  }

  @override
  void visitStructObj(StructObj obj) {
    _curLine = obj.line;
    _curColumn = obj.column;
    // TODO: analyze struct object
  }
}

// class _OccurrencesVisitor extends RecursiveAstVisitor<void> {
//   _OccurrencesVisitor();

//   @override
//   void visitIdentifierExpr(IdentifierExpr expr) {
// if (expr.isLocal && !expr.isKeyword) {
//   // TODO: deal with instance members
//   try {
//     expr.declaration =
//         expr.analysisNamespace!.memberGet(expr.id) as HTDeclaration;
//   } catch (e) {
//     if (e is HTError && e.code == ErrorCode.undefined) {
//       print(
//           'Unable to resolve [${expr.id}] in [${expr.analysisNamespace!.id}] , is this an instance member?');
//     } else {
//       rethrow;
//     }
//   }
// }
//   }
// }
