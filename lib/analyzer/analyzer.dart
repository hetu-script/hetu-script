import '../source/source.dart';
import '../context/context.dart';
import '../type/type.dart';
import '../declaration/generic/generic_type_parameter.dart';
import '../declaration/namespace/namespace.dart';
import '../interpreter/abstract_interpreter.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import '../parser/parser.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/declaration.dart';
import '../declaration/function/function_declaration.dart';
import '../declaration/function/parameter_declaration.dart';
import '../declaration/variable/variable_declaration.dart';
import '../parser/parse_result_collection.dart';
import 'analysis_result.dart';
import 'analysis_error.dart';
import 'type_checker.dart';
import '../declaration/struct/struct_declaration.dart';
import '../grammar/semantic.dart';

class AnalyzerConfig extends InterpreterConfig {
  final List<ErrorProcessor> errorProcessors;

  const AnalyzerConfig(
      {SourceType sourceType = SourceType.module,
      this.errorProcessors = const []})
      : super();
}

class HTAnalyzer extends HTAbstractInterpreter<HTModuleAnalysisResult>
    implements AbstractAstVisitor<void> {
  @override
  final stackTrace = const <String>[];

  @override
  AnalyzerConfig config;

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
  String get curModuleFullName => _curSource.fullName;

  SourceType? _curSourceType;

  @override
  SourceType get curSourceType => _curSourceType ?? _curSource.type;

  HTClassDeclaration? _curClass;
  HTFunctionDeclaration? _curFunction;

  late HTModuleParseResultCompilation curCompilation;

  late List<HTAnalysisError> _curErrors;

  final errors = <HTAnalysisError>[];

  late HTTypeChecker _curTypeChecker;

  @override
  final HTContext context;

  final moduleAnalysisResults = <String, HTModuleAnalysisResult>{};

  final analyzedDeclarations = <String, HTNamespace>{};

  HTAnalyzer({HTContext? context, this.config = const AnalyzerConfig()})
      : global = HTNamespace(id: SemanticNames.global),
        context = context ?? HTContext() {
    _curNamespace = global;
  }

  @override
  void handleError(Object error, {Object? externalStackTrace}) {
    late final analysisError;
    if (error is HTError) {
      analysisError = HTAnalysisError.fromError(error);
    } else {
      var message = error.toString();
      analysisError = HTAnalysisError(
          ErrorCode.extern, ErrorType.externalError, message,
          moduleFullName: _curSource.fullName,
          line: _curLine,
          column: _curColumn);
    }
    _curErrors.add(analysisError);
    errors.add(analysisError);
  }

  @override
  HTModuleAnalysisResult? evalSource(HTSource source,
      {String? libraryName,
      bool globallyImport = false,
      SourceType? type, // ignored in analyzer
      String? invokeFunc, // ignored in analyzer
      List<dynamic> positionalArgs = const [], // ignored in analyzer
      Map<String, dynamic> namedArgs = const {}, // ignored in analyzer
      List<HTType> typeArgs = const [], // ignored in analyzer
      bool errorHandled = false // ignored in analyzer
      }) {
    if (source.content.isEmpty) {
      return null;
    }
    _curSource = source;
    _curErrors = <HTAnalysisError>[];
    final parser = HTParser(errorHandler: this, context: context);
    curCompilation =
        parser.parseToCompilation(source, libraryName: libraryName);
    final declarations = <String, HTNamespace>{};
    for (final module in curCompilation.modules.values) {
      if (moduleAnalysisResults.containsKey(module.fullName)) {
        continue;
      }
      final moduleAnalysisResult =
          HTModuleAnalysisResult(module.source, this, _curErrors);
      moduleAnalysisResults[module.fullName] = moduleAnalysisResult;
      _curNamespace = HTNamespace(id: module.fullName, closure: global);
      declarations[module.fullName] = _curNamespace;
      for (final node in module.nodes) {
        analyzeAst(node);
      }
      for (final decl in _curNamespace.declarations.values) {
        analyzeDeclaration(decl);
      }
    }
    analyzedDeclarations.addAll(declarations);
    final moduleAnalysisResult = moduleAnalysisResults[source.fullName]!;
    return moduleAnalysisResult;
  }

  void analyzeDeclaration(HTDeclaration decl) {}

  void analyzeAst(AstNode node) => node.accept(this);

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
  void visitStringInterpolationExpr(StringInterpolationExpr expr) {}

  @override
  void visitGroupExpr(GroupExpr expr) {}

  @override
  void visitListExpr(ListExpr expr) {}

  @override
  void visitMapExpr(MapExpr expr) {}

  @override
  void visitSymbolExpr(SymbolExpr expr) {}

  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr expr) {}

  @override
  void visitBinaryExpr(BinaryExpr expr) {}

  @override
  void visitTernaryExpr(TernaryExpr expr) {}

  @override
  void visitTypeExpr(TypeExpr expr) {}

  @override
  void visitParamTypeExpr(ParamTypeExpr expr) {}

  @override
  void visitFunctionTypeExpr(FuncTypeExpr expr) {}

  @override
  void visitGenericTypeParamExpr(GenericTypeParamExpr expr) {}

  @override
  void visitCallExpr(CallExpr expr) {}

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr expr) {}

  @override
  void visitMemberExpr(MemberExpr expr) {}

  @override
  void visitMemberAssignExpr(MemberAssignExpr expr) {}

  @override
  void visitSubExpr(SubExpr expr) {}

  @override
  void visitSubAssignExpr(SubAssignExpr expr) {}

  @override
  void visitExprStmt(ExprStmt stmt) {}

  @override
  void visitBlockStmt(BlockStmt block) {}

  @override
  void visitReturnStmt(ReturnStmt stmt) {}

  @override
  void visitIfStmt(IfStmt ifStmt) {}

  @override
  void visitWhileStmt(WhileStmt whileStmt) {}

  @override
  void visitDoStmt(DoStmt doStmt) {}

  @override
  void visitForStmt(ForStmt forStmt) {}

  @override
  void visitForInStmt(ForInStmt forInStmt) {}

  @override
  void visitWhenStmt(WhenStmt stmt) {}

  @override
  void visitBreakStmt(BreakStmt stmt) {}

  @override
  void visitContinueStmt(ContinueStmt stmt) {}

  @override
  void visitLibraryDecl(LibraryDecl stmt) {}

  @override
  void visitImportDecl(ImportDecl stmt) {}

  @override
  void visitNamespaceDecl(NamespaceDecl stmt) {
    // TODO: namespace analysis
  }

  @override
  void visitTypeAliasDecl(TypeAliasDecl stmt) {}

  @override
  void visitVarDecl(VarDecl stmt) {
    final decl = HTVariableDeclaration(stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        declType: HTType.fromAst(stmt.declType),
        isExternal: stmt.isExternal,
        isStatic: stmt.isStatic,
        isConst: stmt.isConst,
        isMutable: stmt.isMutable);

    _curNamespace.define(stmt.id, decl);
  }

  @override
  void visitParamDecl(ParamDecl stmt) {}

  @override
  void visitReferConstructCallExpr(ReferConstructCallExpr stmt) {}

  @override
  void visitFuncDecl(FuncDecl stmt) {
    final decl = HTFunctionDeclaration(stmt.internalName,
        id: stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        isExternal: stmt.isExternal,
        isStatic: stmt.isStatic,
        isConst: stmt.isConst,
        category: stmt.category,
        externalTypeId: stmt.externalTypeId,
        isVariadic: stmt.isVariadic,
        minArity: stmt.minArity,
        maxArity: stmt.maxArity,
        paramDecls: stmt.paramDecls.asMap().map((key, param) => MapEntry(
            param.id,
            HTParameterDeclaration(param.id,
                closure: _curNamespace,
                declType: HTType.fromAst(param.declType),
                isOptional: param.isOptional,
                isNamed: param.isNamed,
                isVariadic: param.isVariadic))),
        returnType: HTType.fromAst(stmt.returnType));

    _curNamespace.define(stmt.internalName, decl);
  }

  @override
  void visitClassDecl(ClassDecl stmt) {
    final decl = HTClassDeclaration(
        id: stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        genericTypeParameters: stmt.genericTypeParameters
            .map((param) => HTGenericTypeParameter(param.id))
            .toList(),
        superType: HTType.fromAst(stmt.superType),
        implementsTypes:
            stmt.implementsTypes.map((param) => HTType.fromAst(param)),
        withTypes: stmt.withTypes.map((param) => HTType.fromAst(param)),
        isExternal: stmt.isExternal,
        isAbstract: stmt.isAbstract);

    _curNamespace.define(stmt.id, decl);
  }

  @override
  void visitEnumDecl(EnumDecl stmt) {
    final decl = HTClassDeclaration(
        id: stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        isExternal: stmt.isExternal);

    _curNamespace.define(stmt.id, decl);
  }

  @override
  void visitStructDecl(StructDecl stmt) {
    final decl = HTStructDeclaration(stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        prototypeId: stmt.prototypeId,
        isTopLevel: stmt.isTopLevel,
        isExported: stmt.isExported);

    _curNamespace.define(stmt.id, decl);
  }
}
