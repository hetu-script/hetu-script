import '../source/source.dart';
import '../source/source_provider.dart';
import '../type/type.dart';
import '../declaration/namespace.dart';
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
      : super(sourceType: sourceType);
}

class HTAnalyzer extends AbstractInterpreter<HTModuleAnalysisResult>
    implements AbstractAstVisitor<void> {
  AnalyzerConfig _curConfig;

  @override
  ErrorHandlerConfig get errorConfig => curConfig;

  @override
  AnalyzerConfig get curConfig => _curConfig;

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

  @override
  HTModuleAnalysisResult? evalSource(HTSource source,
      {String? libraryName, // ignored in analyzer
      HTNamespace? namespace, // ignored in analyzer
      InterpreterConfig? config, // ignored in analyzer
      String? invokeFunc, // ignored in analyzer
      List<dynamic> positionalArgs = const [], // ignored in analyzer
      Map<String, dynamic> namedArgs = const {}, // ignored in analyzer
      List<HTType> typeArgs = const [], // ignored in analyzer
      bool errorHandled = false // ignored in analyzer
      }) {
    if (source.content.isEmpty) {
      return null;
    }
    final hasOwnNamespace = namespace != global;
    _curErrors = <HTAnalysisError>[];
    final parser = HTAstParser(
        config: _curConfig, errorHandler: this, sourceProvider: sourceProvider);
    final compilation = parser.parseToCompilation(source,
        hasOwnNamespace: hasOwnNamespace, errorHandled: true);
    _curLibrary = HTLibraryAnalysisResult(source.libraryName);
    for (final module in compilation.modules.values) {
      _curSource = HTModuleAnalysisResult(
          module.source.fullName, module.source.content, this, _curErrors);
      _curLibrary.modules[module.source.fullName] = _curSource;
      if (module.hasOwnNamespace) {
        _curNamespace = HTNamespace(id: module.fullName, closure: global);
      } else {
        _curNamespace = global;
      }
      _curLibrary.declarations[module.fullName] = _curNamespace;
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
  void visitTypeDeclStmt(TypeDeclStmt stmt) {}

  @override
  void visitVarDeclStmt(VarDeclStmt stmt) {
    final decl = HTVariableDeclaration(
        id: stmt.id,
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
                declType: HTType.fromAst(param.declType),
                isOptional: param.isOptional,
                isNamed: param.isNamed,
                isVariadic: param.isVariadic))),
        returnType: HTType.fromAst(stmt.returnType));

    _curNamespace.define(stmt.internalName, decl);
  }

  @override
  void visitClassDeclStmt(ClassDeclStmt stmt) {
    final decl = HTClassDeclaration(
        id: stmt.id,
        classId: stmt.classId,
        closure: _curNamespace,
        source: _curSource,
        genericParameters:
            stmt.genericParameters.map((param) => HTType.fromAst(param)),
        superType: HTType.fromAst(stmt.superType),
        implementsTypes:
            stmt.implementsTypes.map((param) => HTType.fromAst(param)),
        withTypes: stmt.withTypes.map((param) => HTType.fromAst(param)),
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
