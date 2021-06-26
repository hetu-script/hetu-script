import 'package:hetu_script/declaration/declaration.dart';

import '../source/source.dart';
import '../source/source_provider.dart';
import '../type/type.dart';
import '../declaration/namespace.dart';
import '../interpreter/abstract_interpreter.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import '../scanner/parser.dart';
import '../declaration/library.dart';
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

class HTAnalyzer extends AbstractInterpreter<HTAnalysisResult>
    implements AbstractAstVisitor<void> {
  AnalyzerConfig _curConfig;

  @override
  ErrorHandlerConfig get errorConfig => curConfig;

  @override
  AnalyzerConfig get curConfig => _curConfig;

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

  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  late HTLibrary _curLibrary;
  @override
  HTLibrary get curLibrary => _curLibrary;

  final _curErrors = <HTAnalysisError>[];

  late HTAnalysisResult _curAnalysisResult;

  @override
  dynamic get failedResult => _curAnalysisResult;

  late HTTypeChecker _curTypeChecker;

  HTAnalyzer(
      {HTSourceProvider? sourceProvider,
      AnalyzerConfig config = const AnalyzerConfig()})
      : _curConfig = config,
        super(config: config, sourceProvider: sourceProvider) {
    _curNamespace = global;
    _curAnalysisResult = HTAnalysisResult(this, _curErrors);
  }

  @override
  void handleError(Object error, {Object? externalStackTrace}) {
    late final analysisError;
    if (error is HTError) {
      analysisError = HTAnalysisError.fromError(error);
    } else {
      var message = error.toString();
      analysisError = HTAnalysisError(ErrorCode.extern, ErrorType.externalError,
          message: message,
          moduleFullName: _curModuleFullName,
          line: _curLine,
          column: _curColumn);
    }
    _curErrors.add(analysisError);
  }

  void reset() {
    _curErrors.clear();
  }

  @override
  HTAnalysisResult? evalSource(HTSource source,
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
    _curModuleFullName = source.fullName;
    _curLibrary = HTLibrary(source.libraryName);
    final parser = HTAstParser(
        config: _curConfig, errorHandler: this, sourceProvider: sourceProvider);
    final compilation = parser.parseToCompilation(source);
    for (final module in compilation.modules.values) {
      _curLibrary.sources[module.source.fullName] = module.source;
      for (final node in module.nodes) {
        analyzeAst(node);
      }
    }
    _curTypeChecker = HTTypeChecker(_curLibrary);
    for (final decl in _curLibrary.declarations.values) {
      analyzeDeclaration(decl);
    }
    return _curAnalysisResult;
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
  void visitVarDeclStmt(VarDeclStmt stmt) {}

  @override
  void visitParamDeclStmt(ParamDeclExpr stmt) {}

  @override
  void visitReferConstructorExpr(ReferConstructorExpr stmt) {}

  @override
  void visitFuncDeclStmt(FuncDeclExpr stmt) {}

  @override
  void visitClassDeclStmt(ClassDeclStmt stmt) {}

  @override
  void visitEnumDeclStmt(EnumDeclStmt stmt) {}

  @override
  void visitTypeAliasStmt(TypeAliasDeclStmt stmt) {}
}
