import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../declaration/namespace/declaration_namespace.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import 'analysis_result.dart';
import 'analysis_error.dart';
import '../grammar/constant.dart';
import '../ast/visitor/recursive_ast_visitor.dart';
import '../constant/constant_interpreter.dart';
import 'analyzer_impl.dart';

class AnalyzerConfig {
  bool checkTypeErrors;

  bool computeConstantExpressionValue;

  AnalyzerConfig(
      {this.checkTypeErrors = false,
      this.computeConstantExpressionValue = false});
}

/// A ast visitor that create declarative-only namespaces on all astnode,
/// for analysis purpose, the true analyzer is a underlying
class HTAnalyzer extends RecursiveASTVisitor<void> {
  final errorProcessors = <ErrorProcessor>[];

  AnalyzerConfig config;

  ErrorHandlerConfig? get errorConfig => null;

  final HTDeclarationNamespace<ASTNode> _globalNamespace;

  late HTDeclarationNamespace<ASTNode> _currentNamespace;

  late HTSource _curSource;

  HTResourceType get sourceType => _curSource.type;

  // HTClassDeclaration? _curClass;
  // HTFunctionDeclaration? _curFunction;

  // late HTTypeChecker _curTypeChecker;

  HTResourceContext<HTSource> sourceContext;

  List<HTAnalysisError> _currentErrors = [];
  Map<String, HTSourceAnalysisResult> _currentAnalysisResults = {};

  HTAnalyzer(
      {AnalyzerConfig? config, HTResourceContext<HTSource>? sourceContext})
      : config = config ?? AnalyzerConfig(),
        sourceContext = sourceContext ?? HTOverlayContext(),
        _globalNamespace = HTDeclarationNamespace(id: Semantic.global) {
    _currentNamespace = _globalNamespace;
  }

  HTModuleAnalysisResult analyzeCompilation(
    ASTCompilation compilation, {
    String? moduleName,
    bool globallyImport = false,
  }) {
    _currentErrors = [];
    _currentAnalysisResults = {};

    // Resolve namespaces
    for (final source in compilation.sources.values) {
      // the first scan, namespaces & declarations are created
      resolve(source);
    }

    for (final source in compilation.sources.values) {
      // the second scan, compute constant values
      // the third scan, do static analysis
      analyze(source);
    }

    if (globallyImport) {
      _globalNamespace.import(_currentAnalysisResults.values.last.namespace);
    }
    // walk through ast again to resolve each symbol's declaration referrence.
    // final visitor = _OccurrencesVisitor();
    // for (final node in result.parseResult.nodes) {
    //   node.accept(visitor);
    // }
    return HTModuleAnalysisResult(
      sourceAnalysisResults: _currentAnalysisResults,
      errors: _currentErrors,
      compilation: compilation,
    );
  }

  void resolve(ASTSource source) {
    if (source.resourceType == HTResourceType.hetuLiteralCode) {
      _currentNamespace = _globalNamespace;
    } else {
      _currentNamespace = HTDeclarationNamespace(
          id: source.fullName, closure: _globalNamespace);
    }
    for (final node in source.nodes) {
      analyzeAST(node);
    }
  }

  HTSourceAnalysisResult analyze(ASTSource source) {
    final sourceErrors = <HTAnalysisError>[];
    sourceErrors
        .addAll(source.errors!.map((err) => HTAnalysisError.fromError(err)));

    if (config.computeConstantExpressionValue) {
      final constantInterpreter = HTConstantInterpreter();
      source.accept(constantInterpreter);
      sourceErrors.addAll(constantInterpreter.errors);
    }

    if (config.checkTypeErrors) {
      final analyzer = HTAnalyzerImpl();
      source.accept(analyzer);
      sourceErrors.addAll(analyzer.errors);
    }

    final sourceAnalysisResult = HTSourceAnalysisResult(
        parseResult: source,
        analyzer: this,
        errors: sourceErrors,
        namespace: _currentNamespace);

    _currentAnalysisResults[sourceAnalysisResult.fullName] =
        sourceAnalysisResult;
    _currentErrors.addAll(sourceAnalysisResult.errors);

    return sourceAnalysisResult;
  }

  void analyzeAST(ASTNode node) => node.accept(this);

  @override
  void visitCompilation(ASTCompilation node) {
    throw 'Use `analyzeCompilation()` instead of `visitCompilation()`.';
  }

  @override
  void visitSource(ASTSource astSource) {
    throw 'Use `resolve() & analyzer()` instead of `visitSource`.';
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitDeleteStmt(DeleteStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteMemberStmt(DeleteMemberStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteSubStmt(DeleteSubStmt node) {
    node.subAccept(this);
  }

  @override
  void visitImportExportDecl(ImportExportDecl node) {
    node.subAccept(this);
  }

  @override
  void visitNamespaceDecl(NamespaceDecl node) {
    node.subAccept(this);
  }

  @override
  void visitTypeAliasDecl(TypeAliasDecl node) {
    // node.declaration = HTVariableDeclaration(node.id.id,
    //     classId: node.classId, closure: _currentNamespace, source: _curSource);
    // _currentNamespace.define(node.id.id, node.declaration!);
    node.subAccept(this);
  }

  // @override
  // void visitConstDecl(ConstDecl node) {
  //   _curLine = node.line;
  //   _curColumn = node.column;

  //   node.subAccept(this);
  // }

  @override
  void visitVarDecl(VarDecl node) {
    node.subAccept(this);
    // if (node.isConst && node.initializer)
    // node.declaration = HTVariableDeclaration(node.id.id,
    //     classId: node.classId,
    //     closure: _curNamespace,
    //     source: _curSource,
    //     declType: HTType.fromAst(node.declType),
    //     isExternal: node.isExternal,
    //     isStatic: node.isStatic,
    //     isConst: node.isConst,
    //     isMutable: node.isMutable);
    // _curNamespace.define(node.id.id, node.declaration!);
  }

  @override
  void visitDestructuringDecl(DestructuringDecl node) {
    node.subAccept(this);
  }

  @override
  void visitParamDecl(ParamDecl node) {
    // node.declaration = HTParameterDeclaration(node.id.id,
    //     closure: _curNamespace,
    //     source: _curSource,
    //     declType: HTType.fromAst(node.declType),
    //     isOptional: node.isOptional,
    //     isNamed: node.isNamed,
    //     isVariadic: node.isVariadic);
    // _curNamespace.define(node.id.id, node.declaration!);
    node.subAccept(this);
  }

  @override
  void visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFuncDecl(FuncDecl node) {
    node.id?.accept(this);
    for (final param in node.genericTypeParameters) {
      visitGenericTypeParamExpr(param);
    }
    node.returnType?.accept(this);
    node.redirectingCtorCallExpr?.accept(this);
    // final namespace =
    //     HTNamespace(id: node.internalName, closure: _curNamespace);
    // final savedCurNamespace = _curNamespace;
    // _curNamespace = namespace;
    // for (final arg in node.paramDecls) {
    //   visitParamDecl(arg);
    // }
    // if (node.definition != null) {
    //   analyzeAst(node.definition!);
    // }
    // _curNamespace = savedCurNamespace;
    // node.declaration = HTFunctionDeclaration(node.internalName,
    //     id: node.id?.id,
    //     classId: node.classId,
    //     closure: _curNamespace,
    //     source: _curSource,
    //     isExternal: node.isExternal,
    //     isStatic: node.isStatic,
    //     isConst: node.isConst,
    //     category: node.category,
    //     externalTypeId: node.externalTypeId,
    //     paramDecls: node.paramDecls.asMap().map((key, param) => MapEntry(
    //         param.id.id,
    //         HTParameterDeclaration(param.id.id,
    //             closure: _curNamespace,
    //             declType: HTType.fromAst(param.declType),
    //             isOptional: param.isOptional,
    //             isNamed: param.isNamed,
    //             isVariadic: param.isVariadic))),
    //     returnType: HTType.fromAst(node.returnType),
    //     isVariadic: node.isVariadic,
    //     minArity: node.minArity,
    //     maxArity: node.maxArity,
    //     namespace: namespace);
    // _curNamespace.define(node.internalName, node.declaration!);
  }

  @override
  void visitClassDecl(ClassDecl node) {
    visitIdentifierExpr(node.id);
    for (final param in node.genericTypeParameters) {
      visitGenericTypeParamExpr(param);
    }
    node.superType?.accept(this);
    for (final implementsType in node.implementsTypes) {
      visitTypeExpr(implementsType);
    }
    for (final withType in node.withTypes) {
      visitTypeExpr(withType);
    }
    // final decl = HTClassDeclaration(
    //     id: node.id.id,
    //     classId: node.classId,
    //     closure: _curNamespace,
    //     source: _curSource,
    //     genericTypeParameters: node.genericTypeParameters
    //         .map((param) => HTGenericTypeParameter(param.id.id))
    //         .toList(),
    //     superType: HTType.fromAst(node.superType),
    //     implementsTypes:
    //         node.implementsTypes.map((param) => HTType.fromAst(param)),
    //     withTypes: node.withTypes.map((param) => HTType.fromAst(param)),
    //     isExternal: node.isExternal,
    //     isAbstract: node.isAbstract,
    //     isTopLevel: node.isTopLevel,
    //     isExported: node.isExported);
    // final savedCurNamespace = _curNamespace;
    // node.declaration = decl;
    // _curNamespace = decl.namespace;
    // visitBlockStmt(node.definition);
    // _curNamespace = savedCurNamespace;
    // _curNamespace.define(node.id.id, decl);
  }

  @override
  void visitEnumDecl(EnumDecl node) {
    visitIdentifierExpr(node.id);
    // node.declaration = HTClassDeclaration(
    //     id: node.id.id,
    //     classId: node.classId,
    //     closure: _curNamespace,
    //     source: _curSource,
    //     isExternal: node.isExternal);
    // _curNamespace.define(node.id.id, node.declaration!);
  }

  @override
  void visitStructDecl(StructDecl node) {
    node.id.accept(this);
    // final savedCurNamespace = _curNamespace;
    // _curNamespace = HTNamespace(id: node.id.id, closure: _curNamespace);
    for (final node in node.definition) {
      node.accept(this);
    }
    // node.declaration = HTStructDeclaration(_curNamespace,
    //     id: node.id.id,
    //     closure: savedCurNamespace,
    //     source: _curSource,
    //     prototypeId: node.prototypeId?.id,
    //     isTopLevel: node.isTopLevel,
    //     isExported: node.isExported);
    // _curNamespace = savedCurNamespace;
    // _curNamespace.define(node.id.id, node.declaration!);
  }

  @override
  void visitStructObjField(StructObjField node) {}

  @override
  void visitStructObjExpr(StructObjExpr node) {}
}

// class _OccurrencesVisitor extends RecursiveAstVisitor<void> {
//   _OccurrencesVisitor();

//   @override
//   void visitIdentifierExpr(IdentifierExpr node) {
//     if (node.isLocal && !node.isKeyword) {
//       // TODO: deal with instance members
//       try {
//         node.declaration =
//             node.analysisNamespace!.memberGet(node.id) as HTDeclaration;
//       } catch (e) {
//         if (e is HTError && e.code == ErrorCode.undefined) {
//           print(
//               'Unable to resolve [${node.id}] in [${node.analysisNamespace!.id}] , is this an instance member?');
//         } else {
//           rethrow;
//         }
//       }
//     }
//   }
// }
