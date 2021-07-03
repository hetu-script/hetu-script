import '../source/source.dart';
import '../source/source_provider.dart';
import '../type/type.dart';
import '../type/unresolved_type.dart';
import '../type/generic_type_parameter.dart';
import '../declaration/namespace/namespace.dart';
import '../interpreter/abstract_interpreter.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import '../scanner/parser.dart';
import '../declaration/class/class_declaration.dart';
import '../declaration/declaration.dart';
import '../declaration/function/function_declaration.dart';
import '../declaration/function/parameter_declaration.dart';
import '../declaration/variable/variable_declaration.dart';
import 'analysis_result.dart';
import 'analysis_error.dart';
import 'type_checker.dart';

class AnalyzerConfig extends InterpreterConfig {
  final List<ErrorProcessor> errorProcessors;

  const AnalyzerConfig(
      {SourceType sourceType = SourceType.module,
      this.errorProcessors = const []})
      : super();
}

class HTAnalyzer extends HTAbstractInterpreter<HTModuleAnalysisResult>
    implements AbstractAstVisitor<void> {
  AnalyzerConfig _curConfig;

  @override
  ErrorHandlerConfig get errorConfig => _curConfig;

  @override
  AnalyzerConfig get config => _curConfig;

  String? _curSymbol;
  String? get curSymbol => _curSymbol;

  var _curLine = 0;
  @override
  int get curLine => _curLine;

  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  late HTModuleAnalysisResult _curSource;
  @override
  String get curModuleFullName => _curSource.fullName;

  late HTLibraryAnalysisResult _curLibrary;
  @override
  HTLibraryAnalysisResult get curLibrary => _curLibrary;

  final _cachedLibs = <String, HTLibraryAnalysisResult>{};

  HTClassDeclaration? _curClass;
  HTFunctionDeclaration? _curFunction;

  late List<HTAnalysisError> _curErrors;

  final errors = <HTAnalysisError>[];

  late HTTypeChecker _curTypeChecker;

  HTAnalyzer(
      {HTSourceProvider? sourceProvider,
      AnalyzerConfig config = const AnalyzerConfig()})
      : _curConfig = config,
        super(config: config, sourceProvider: sourceProvider) {
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

  void reset() {
    errors.clear();
  }

  void closeSource(String fullName) {}

  @override
  HTModuleAnalysisResult? evalSource(HTSource source,
      {String? libraryName,
      bool import = false,
      SourceType type = SourceType.module, // ignored in analyzer
      String? invokeFunc, // ignored in analyzer
      List<dynamic> positionalArgs = const [], // ignored in analyzer
      Map<String, dynamic> namedArgs = const {}, // ignored in analyzer
      List<HTType> typeArgs = const [], // ignored in analyzer
      bool errorHandled = false // ignored in analyzer
      }) {
    if (source.content.isEmpty) {
      return null;
    }
    _curErrors = <HTAnalysisError>[];
    final parser =
        HTAstParser(errorHandler: this, sourceProvider: sourceProvider);
    final compilation =
        parser.parseToCompilation(source, libraryName: libraryName);
    final modules = <String, HTModuleAnalysisResult>{};
    final declarations = <String, HTNamespace>{};
    for (final module in compilation.modules.values) {
      _curSource = HTModuleAnalysisResult(
          module.source.content, this, _curErrors,
          fullName: module.source.fullName);
      modules[module.source.fullName] = _curSource;
      if (module.type == SourceType.module) {
        _curNamespace = HTNamespace(id: module.fullName, closure: global);
      } else {
        _curNamespace = global;
      }
      declarations[module.fullName] = _curNamespace;
    }
    _curLibrary = HTLibraryAnalysisResult(compilation, modules,
        declarations: declarations);
    for (final module in compilation.modules.values) {
      for (final node in module.nodes) {
        analyzeAst(node);
      }
    }
    _curTypeChecker = HTTypeChecker(_curLibrary);
    for (final decl in _curLibrary.declarations.values) {
      analyzeDeclaration(decl);
    }
    _cachedLibs[_curLibrary.id] = _curLibrary;
    final result = _curLibrary.modules[source.fullName]!;
    return result;
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
  void visitLibraryStmt(LibraryStmt stmt) {}

  @override
  void visitImportStmt(ImportStmt stmt) {}

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
  void visitTypeAliasDeclStmt(TypeAliasDeclStmt stmt) {}

  @override
  void visitVarDeclStmt(VarDeclStmt stmt) {
    final decl = HTVariableDeclaration(stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        declType: HTUnresolvedType.fromAst(stmt.declType),
        isExternal: stmt.isExternal,
        isStatic: stmt.isStatic,
        isConst: stmt.isConst,
        isMutable: stmt.isMutable);

    _curNamespace.define(stmt.id, decl);
  }

  @override
  void visitParamDeclStmt(ParamDeclExpr stmt) {}

  @override
  void visitReferConstructCallExpr(ReferConstructCallExpr stmt) {}

  @override
  void visitFuncDeclStmt(FuncDeclExpr stmt) {
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
                declType: HTUnresolvedType.fromAst(param.declType),
                isOptional: param.isOptional,
                isNamed: param.isNamed,
                isVariadic: param.isVariadic))),
        returnType: HTUnresolvedType.fromAst(stmt.returnType));

    _curNamespace.define(stmt.internalName, decl);
  }

  @override
  void visitNamespaceDeclStmt(NamespaceDeclStmt stmt) {
    // TODO: namespace analysis
  }

  @override
  void visitClassDeclStmt(ClassDeclStmt stmt) {
    final decl = HTClassDeclaration(
        id: stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        genericTypeParameters: stmt.genericParameters
            .map((param) => HTGenericTypeParameter(param.id))
            .toList(),
        superType: HTUnresolvedType.fromAst(stmt.superType),
        implementsTypes: stmt.implementsTypes
            .map((param) => HTUnresolvedType.fromAst(param)),
        withTypes:
            stmt.withTypes.map((param) => HTUnresolvedType.fromAst(param)),
        isExternal: stmt.isExternal,
        isAbstract: stmt.isAbstract);

    _curNamespace.define(stmt.id, decl);
  }

  @override
  void visitEnumDeclStmt(EnumDeclStmt stmt) {
    final decl = HTClassDeclaration(
        id: stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        isExternal: stmt.isExternal);

    _curNamespace.define(stmt.id, decl);
  }
}
