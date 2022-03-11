import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../type/type.dart';
// import '../declaration/generic/generic_type_parameter.dart';
import '../declaration/namespace/declaration_namespace.dart';
import '../interpreter/abstract_interpreter.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import '../parser/parser.dart';
// import '../declaration/declaration.dart';
// import '../declaration/class/class_declaration.dart';
// import '../declaration/function/function_declaration.dart';
// import '../declaration/function/parameter_declaration.dart';
import '../declaration/variable/variable_declaration.dart';
import 'analysis_result.dart';
import 'analysis_error.dart';
// import 'type_checker.dart';
import '../grammar/semantic.dart';
// import '../ast/visitor/recursive_ast_visitor.dart';
import '../binding/external_class.dart';
import '../binding/external_function.dart';
import '../constant/constant_interpreter.dart';
import 'analyzer_impl.dart';
import '../localization/locales.dart';

abstract class AnalyzerConfig {
  factory AnalyzerConfig({bool computeConstantExpressionValue}) =
      AnalyzerConfigImpl;

  bool get checkTypeErrors;

  bool get computeConstantExpressionValue;
}

class AnalyzerConfigImpl implements AnalyzerConfig {
  @override
  final bool checkTypeErrors;
  @override
  final bool computeConstantExpressionValue;

  const AnalyzerConfigImpl(
      {this.checkTypeErrors = false,
      this.computeConstantExpressionValue = false});
}

/// A ast visitor that create declarative-only namespaces on all astnode,
/// for analysis purpose, the true analyzer is a underlying
class HTAnalyzer extends HTAbstractInterpreter<HTModuleAnalysisResult>
    implements AbstractAstVisitor<void> {
  final errorProcessors = <ErrorProcessor>[];

  AnalyzerConfig config;

  @override
  ErrorHandlerConfig? get errorConfig => null;

  final HTDeclarationNamespace globalNamespace;

  late HTDeclarationNamespace _currentNamespace;

  late HTSource _curSource;

  HTResourceType get sourceType => _curSource.type;

  // HTClassDeclaration? _curClass;
  // HTFunctionDeclaration? _curFunction;

  // late HTTypeChecker _curTypeChecker;

  @override
  HTResourceContext<HTSource> sourceContext;

  final analyzedDeclarations = <String, HTDeclarationNamespace>{};

  HTAnalyzer(
      {HTResourceContext<HTSource>? sourceContext, AnalyzerConfig? config})
      : config = config ?? AnalyzerConfig(),
        globalNamespace = HTDeclarationNamespace(id: Semantic.global),
        sourceContext = sourceContext ?? HTOverlayContext() {
    _currentNamespace = globalNamespace;
  }

  @override
  void init({
    HTLocale? locale,
    List<HTSource> preincludes = const [],
    Map<String, Function> externalFunctions = const {},
    Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
    List<HTExternalClass> externalClasses = const [],
  }) {
    super.init(
      locale: locale,
      externalFunctions: externalFunctions,
      externalFunctionTypedef: externalFunctionTypedef,
      externalClasses: externalClasses,
    );
    for (final file in preincludes) {
      evalSource(file, globallyImport: true);
    }
  }

  /// Analyzer should never throw,
  /// instead it will store all errors as a list in analysis result.
  @override
  void handleError(Object error, {Object? externalStackTrace}) {}

  @override
  HTModuleAnalysisResult evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      bool isStrictMode = false,
      String? invokeFunc, // ignored in analyzer
      List<dynamic> positionalArgs = const [], // ignored in analyzer
      Map<String, dynamic> namedArgs = const {}, // ignored in analyzer
      List<HTType> typeArgs = const [], // ignored in analyzer
      bool errorHandled = false // ignored in analyzer
      }) {
    _curSource = source;
    final List<HTAnalysisError> errors = [];
    final Map<String, HTSourceAnalysisResult> sourceAnalysisResults = {};
    final parser = HTParser(sourceContext: sourceContext);
    final compilation = parser.parseToModule(source);

    // Resolve namespaces
    for (final parseResult in compilation.sources.values) {
      if (source.type == HTResourceType.hetuLiteralCode) {
        _currentNamespace = globalNamespace;
      } else {
        _currentNamespace = HTDeclarationNamespace(
            id: parseResult.fullName, closure: globalNamespace);
      }
      HTDeclarationNamespace(
          id: parseResult.fullName, closure: globalNamespace);
      // the first scan, namespaces & declarations are created
      for (final node in parseResult.nodes) {
        node.accept(this);
      }
    }

    for (final parseResult in compilation.sources.values) {
      final sourceErrors = <HTAnalysisError>[];
      sourceErrors.addAll(
          parseResult.errors!.map((err) => HTAnalysisError.fromError(err)));

      // the second scan, compute constant values
      if (config.computeConstantExpressionValue) {
        final constantInterpreter = HTConstantInterpreter();
        parseResult.accept(constantInterpreter);
        sourceErrors.addAll(constantInterpreter.errors);
      }

      // the third scan, do static analysis
      if (config.checkTypeErrors) {
        final analyzer = HTAnalyzerImpl();
        parseResult.accept(analyzer);
        sourceErrors.addAll(analyzer.errors);
      }

      final sourceAnalysisResult = HTSourceAnalysisResult(
          parseResult: parseResult,
          analyzer: this,
          errors: sourceErrors,
          namespace: _currentNamespace);
      sourceAnalysisResults[sourceAnalysisResult.fullName] =
          sourceAnalysisResult;
      errors.addAll(sourceErrors);
    }

    if (globallyImport) {
      globalNamespace.import(sourceAnalysisResults.values.last.namespace);
    }
    // walk through ast again to resolve each symbol's declaration referrence.
    // final visitor = _OccurrencesVisitor();
    // for (final node in result.parseResult.nodes) {
    //   node.accept(visitor);
    // }
    return HTModuleAnalysisResult(
      sourceAnalysisResults: sourceAnalysisResults,
      errors: errors,
      compilation: compilation,
    );
  }

  void analyzeAst(AstNode node) => node.accept(this);

  @override
  void visitCompilation(AstCompilation node) {
    throw 'Use evalSource instead of this method.';
  }

  @override
  void visitCompilationUnit(AstSource node) {
    throw 'Use evalSource instead of this method.';
  }

  @override
  void visitEmptyExpr(EmptyLine node) {}

  @override
  void visitNullExpr(NullExpr node) {}

  @override
  void visitBooleanExpr(BooleanLiteralExpr node) {}

  @override
  void visitIntLiteralExpr(IntegerLiteralExpr node) {}

  @override
  void visitFloatLiteralExpr(FloatLiteralExpr node) {}

  @override
  void visitStringLiteralExpr(StringLiteralExpr node) {
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitStringInterpolationExpr(StringInterpolationExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitSpreadExpr(SpreadExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitCommaExpr(CommaExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitListExpr(ListExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitInOfExpr(InOfExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitGroupExpr(GroupExpr node) {
    node.inner.accept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitTypeExpr(TypeExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitParamTypeExpr(ParamTypeExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitFunctionTypeExpr(FuncTypeExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitFieldTypeExpr(FieldTypeExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitStructuralTypeExpr(StructuralTypeExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitBinaryExpr(BinaryExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitTernaryExpr(TernaryExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitMemberExpr(MemberExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitMemberAssignExpr(MemberAssignExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitSubExpr(SubExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitSubAssignExpr(SubAssignExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitCallExpr(CallExpr node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitAssertStmt(AssertStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitThrowStmt(ThrowStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitExprStmt(ExprStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitBlockStmt(BlockStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitReturnStmt(ReturnStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitIf(IfStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitWhileStmt(WhileStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitDoStmt(DoStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitForStmt(ForStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitForRangeStmt(ForRangeStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitWhen(WhenStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitBreakStmt(BreakStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitContinueStmt(ContinueStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitDeleteStmt(DeleteStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitDeleteMemberStmt(DeleteMemberStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitDeleteSubStmt(DeleteSubStmt node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitImportExportDecl(ImportExportDecl node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;

    if (node.isPreloadedModule) {}
  }

  @override
  void visitNamespaceDecl(NamespaceDecl node) {
    node.subAccept(this);
    node.analysisNamespace = _currentNamespace;
  }

  @override
  void visitTypeAliasDecl(TypeAliasDecl node) {
    node.declaration = HTVariableDeclaration(node.id.id,
        classId: node.classId, closure: _currentNamespace, source: _curSource);
    _currentNamespace.define(node.id.id, node.declaration!);
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
