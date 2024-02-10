import 'package:path/path.dart' as path;

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
import '../ast/visitor/recursive_ast_visitor.dart';
import '../constant/constant_interpreter.dart';
import 'analyzer_impl.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../common/internal_identifier.dart';

/// Namespace that holds symbols for analyzing, the value is either the declaration AST or null.
typedef AnalysisNamespace = HTDeclarationNamespace<ASTNode?>;

class AnalyzerConfig {
  bool computeConstantExpression;

  bool doStaticAnalysis;

  bool allowVariableShadowing;

  bool allowImplicitVariableDeclaration;

  bool allowImplicitNullToZeroConversion;

  bool allowImplicitEmptyValueToFalseConversion;

  bool printPerformanceStatistics;

  AnalyzerConfig({
    this.computeConstantExpression = false,
    this.doStaticAnalysis = false,
    this.allowVariableShadowing = true,
    this.allowImplicitVariableDeclaration = false,
    this.allowImplicitNullToZeroConversion = false,
    this.allowImplicitEmptyValueToFalseConversion = false,
    this.printPerformanceStatistics = false,
  });
}

/// A ast visitor that create declarative-only namespaces on all astnode,
/// for analysis purpose, the true analyzer is another class,
/// albeit its name, this is basically a resolver.
class HTAnalyzer extends RecursiveASTVisitor<void> {
  final errorProcessors = <ErrorProcessor>[];

  AnalyzerConfig config;

  ErrorHandlerConfig? get errorConfig => null;

  late final HTLexicon _lexicon;

  late final AnalysisNamespace globalNamespace;

  late AnalysisNamespace _currentNamespace;

  final Map<String, AnalysisNamespace> namespaces = {};

  late HTSource _currentSource;

  // late ASTCompilation _currentCompilation;

  // HTClassDeclaration? _curClass;
  // HTFunctionDeclaration? _curFunction;

  // late HTTypeChecker _curTypeChecker;

  HTResourceContext<HTSource> sourceContext;

  List<HTAnalysisError> _currentErrors = [];
  Map<String, HTSourceAnalysisResult> _currentAnalysisResults = {};

  HTAnalyzer({
    AnalyzerConfig? config,
    HTResourceContext<HTSource>? sourceContext,
    HTLexicon? lexicon,
  })  : config = config ?? AnalyzerConfig(),
        sourceContext = sourceContext ?? HTOverlayContext(),
        _lexicon = lexicon ?? HTLexiconHetu() {
    globalNamespace = HTDeclarationNamespace(
        lexicon: _lexicon, id: InternalIdentifier.global);
    _currentNamespace = globalNamespace;
  }

  HTModuleAnalysisResult analyzeCompilation(
    ASTCompilation compilation, {
    String? module,
    bool globallyImport = false,
    // bool printPerformanceStatistics = false,
  }) {
    final tik = DateTime.now().millisecondsSinceEpoch;
    // _currentCompilation = compilation;
    _currentErrors = [];
    _currentAnalysisResults = {};

    // Resolve namespaces
    for (final source in compilation.sources.values) {
      // the first scan, create namespaces & declarations.
      resolve(source);
    }

    for (final source in compilation.sources.values) {
      // the second scan, handle import.
      handleImport(source);
    }

    for (final source in compilation.sources.values) {
      // the third & forth scan.
      _analyze(source);
    }

    if (globallyImport) {
      globalNamespace.import(_currentAnalysisResults.values.last.namespace);
    }
    // walk through ast again to resolve each symbol's declaration referrence.
    // final visitor = _OccurrencesVisitor();
    // for (final node in result.parseResult.nodes) {
    //   node.accept(visitor);
    // }
    final result = HTModuleAnalysisResult(
      sourceAnalysisResults: _currentAnalysisResults,
      errors: _currentErrors,
      compilation: compilation,
    );
    if (config.printPerformanceStatistics) {
      final tok = DateTime.now().millisecondsSinceEpoch;
      print('analyzed [${compilation.entryFullname}]\t${tok - tik}ms');
    }
    return result;
  }

  void resolve(ASTSource source) {
    source.isResolved = true;
    if (source.resourceType == HTResourceType.hetuLiteralCode) {
      _currentNamespace = globalNamespace;
    } else {
      if (namespaces[source.fullName] != null) {
        _currentNamespace = namespaces[source.fullName]!;
      } else {
        namespaces[source.fullName] = _currentNamespace =
            HTDeclarationNamespace(
                lexicon: _lexicon,
                id: source.fullName,
                closure: globalNamespace);
      }
    }
    for (final node in source.nodes) {
      resolveAST(node);
    }
  }

  void handleImport(ASTSource source) {}

  HTSourceAnalysisResult _analyze(ASTSource source) {
    final sourceErrors = <HTAnalysisError>[];

    // the third scan, compute constant values
    if (config.computeConstantExpression) {
      final constantInterpreter = HTConstantInterpreter();
      source.accept(constantInterpreter);
      sourceErrors.addAll(constantInterpreter.errors);
    }

    // the forth scan, do static analysis
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
    if (!_currentSource.fullName
        .startsWith(InternalIdentifier.anonymousScript)) {
      // handle self import error.
      final currentDir = path.dirname(_currentSource.fullName);
      final fromPath = sourceContext.getAbsolutePath(
          key: node.fromPath!, dirName: currentDir);
      if (_currentSource.fullName == fromPath) {
        final err = HTAnalysisError.importSelf(
            filename: node.source!.fullName,
            line: node.line,
            column: node.column,
            offset: node.offset,
            length: node.length);
        _currentErrors.add(err);
      }
    }
    // TODO: duplicate import and
    if (!node.isExport) {
      // import statement
      // if (node.)
    } else {}
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
    _currentNamespace.define(node.id.id, node);
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
    node.redirectingConstructorCall?.accept(this);
    final savedCurrrentNamespace = _currentNamespace;
    _currentNamespace = HTDeclarationNamespace(
        lexicon: _lexicon, id: node.internalName, closure: _currentNamespace);
    for (final param in node.paramDecls) {
      visitParamDecl(param);
    }
    node.definition?.accept(this);
    _currentNamespace = savedCurrrentNamespace;
  }

  @override
  void visitClassDecl(ClassDecl node) {
    for (final param in node.genericTypeParameters) {
      visitGenericTypeParamExpr(param);
    }
    node.superType?.accept(this);
    for (final implementsType in node.implementsTypes) {
      visitNominalTypeExpr(implementsType);
    }
    for (final withType in node.withTypes) {
      visitNominalTypeExpr(withType);
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
