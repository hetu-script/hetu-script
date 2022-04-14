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
import '../lexer/lexicon.dart';
import '../lexer/lexicon_default_impl.dart';

/// Namespace that holds symbols for analyzing, the value is either the declaration AST or null.
typedef _AnalysisNamespace = HTDeclarationNamespace<ASTNode?>;

class AnalyzerImplConfig {
  bool allowVariableShadowing;

  bool allowImplicitVariableDeclaration;

  bool allowImplicitNullToZeroConversion;

  bool allowImplicitEmptyValueToFalseConversion;

  AnalyzerImplConfig({
    this.allowVariableShadowing = true,
    this.allowImplicitVariableDeclaration = false,
    this.allowImplicitNullToZeroConversion = false,
    this.allowImplicitEmptyValueToFalseConversion = false,
  });
}

class AnalyzerConfig implements AnalyzerImplConfig {
  bool computeConstantExpression;

  bool doStaticAnalysis;

  @override
  bool allowVariableShadowing;

  @override
  bool allowImplicitVariableDeclaration;

  @override
  bool allowImplicitNullToZeroConversion;

  @override
  bool allowImplicitEmptyValueToFalseConversion;

  AnalyzerConfig(
      {this.computeConstantExpression = false,
      this.doStaticAnalysis = false,
      this.allowVariableShadowing = true,
      this.allowImplicitVariableDeclaration = false,
      this.allowImplicitNullToZeroConversion = false,
      this.allowImplicitEmptyValueToFalseConversion = false});
}

/// A ast visitor that create declarative-only namespaces on all astnode,
/// for analysis purpose, the true analyzer is another class,
/// albeit its name, this is basically a resolver.
class HTAnalyzer extends RecursiveASTVisitor<void> {
  final errorProcessors = <ErrorProcessor>[];

  AnalyzerConfig config;

  ErrorHandlerConfig? get errorConfig => null;

  late final HTLexicon _lexicon;

  final _AnalysisNamespace _globalNamespace;

  late _AnalysisNamespace _currentNamespace;

  late HTSource _curSource;

  HTResourceType get sourceType => _curSource.type;

  // HTClassDeclaration? _curClass;
  // HTFunctionDeclaration? _curFunction;

  // late HTTypeChecker _curTypeChecker;

  HTResourceContext<HTSource> sourceContext;

  List<HTAnalysisError> _currentErrors = [];
  Map<String, HTSourceAnalysisResult> _currentAnalysisResults = {};

  HTAnalyzer(
      {AnalyzerConfig? config,
      HTResourceContext<HTSource>? sourceContext,
      HTLexicon? lexicon})
      : config = config ?? AnalyzerConfig(),
        sourceContext = sourceContext ?? HTOverlayContext(),
        _lexicon = lexicon ?? HTDefaultLexicon(),
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
      // the first scan, namespaces & declarations are created.
      resolve(source);
    }

    for (final source in compilation.sources.values) {
      // the second & third scan.
      _analyze(source);
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
      resolveAST(node);
    }
  }

  HTSourceAnalysisResult _analyze(ASTSource source) {
    final sourceErrors = <HTAnalysisError>[];
    // sourceErrors
    //     .addAll(source.errors!.map((err) => HTAnalysisError.fromError(err)));

    // the second scan, compute constant values
    if (config.computeConstantExpression) {
      final constantInterpreter = HTConstantInterpreter();
      source.accept(constantInterpreter);
      sourceErrors.addAll(constantInterpreter.errors);
    }

    // the third scan, do static analysis
    if (config.doStaticAnalysis) {
      final analyzer = HTAnalyzerImpl(lexicon: _lexicon);
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

  void resolveAST(ASTNode node) => node.accept(this);

  @override
  void visitCompilation(ASTCompilation node) {
    throw 'Use `analyzeCompilation()` instead of `visitCompilation()`.';
  }

  @override
  void visitSource(ASTSource node) {
    throw 'Use `resolve() & analyzer()` instead of `visitSource`.';
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitDeleteStmt(DeleteStmt node) {
    _currentNamespace.delete(node.symbol);
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
    node.subAccept(this);
    _currentNamespace.define(node.id.id, node);
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
    _currentNamespace.define(node.id.id, node,
        override: config.allowVariableShadowing);
  }

  @override
  void visitDestructuringDecl(DestructuringDecl node) {
    node.subAccept(this);
    for (final key in node.ids.keys) {
      _currentNamespace.define(key.id, null,
          override: config.allowVariableShadowing);
    }
  }

  @override
  void visitParamDecl(ParamDecl node) {
    node.subAccept(this);
    // _currentNamespace.define(node.id.id, node);
  }

  @override
  void visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFuncDecl(FuncDecl node) {
    for (final param in node.genericTypeParameters) {
      visitGenericTypeParamExpr(param);
    }
    node.returnType?.accept(this);
    node.redirectingCtorCallExpr?.accept(this);
    // final savedCurrrentNamespace = _currentNamespace;
    // _currentNamespace = HTDeclarationNamespace(
    //     id: node.internalName, closure: _currentNamespace);
    // for (final param in node.paramDecls) {
    //   visitParamDecl(param);
    // }
    // node.definition?.accept(this);
    // _currentNamespace = savedCurrrentNamespace;
  }

  @override
  void visitClassDecl(ClassDecl node) {
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
    // final savedCurNamespace = _curNamespace;
    // _curNamespace = HTNamespace(id: node.id.id, closure: _curNamespace);
    // for (final node in node.definition) {
    //   node.accept(this);
    // }
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
