import '../source/source.dart';
import '../source/source_provider.dart';
import '../type/type.dart';
import '../declaration/namespace.dart';
import '../interpreter/abstract_interpreter.dart';
import '../error/error.dart';
import '../ast/ast.dart';
import '../scanner/parser.dart';
import '../declaration/library.dart';

class AnalyzerConfig extends InterpreterConfig {
  final List<ErrorProcessor> errorProcessors;

  const AnalyzerConfig(
      {SourceType sourceType = SourceType.module,
      this.errorProcessors = const []})
      : super(sourceType: sourceType);
}

class HTAnalyzer extends AbstractInterpreter
    implements AbstractAstVisitor<HTType> {
  AnalyzerConfig _curConfig;

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

  HTAnalyzer(
      {HTSourceProvider? sourceProvider,
      AnalyzerConfig config = const AnalyzerConfig()})
      : _curConfig = config,
        super(config: config, sourceProvider: sourceProvider) {
    _curNamespace = global;
  }

  @override
  Future<void> evalSource(HTSource source,
      {String? libraryName, // ignored in analyzer
      HTNamespace? namespace, // ignored in analyzer
      InterpreterConfig? config, // ignored in analyzer
      String? invokeFunc, // ignored in analyzer
      List<dynamic> positionalArgs = const [], // ignored in analyzer
      Map<String, dynamic> namedArgs = const {}, // ignored in analyzer
      List<HTType> typeArgs = const [], // ignored in analyzer
      bool errorHandled = false // ignored in analyzer
      }) async {
    if (source.content.isEmpty) {
      return null;
    }
    _curModuleFullName = source.fullName;
    final parser = HTAstParser(
        config: _curConfig,
        errorHandler: errorHandler,
        sourceProvider: sourceProvider);
    final compilation = parser.parseToCompilation(source);
  }

  @override
  dynamic invoke(String funcName,
      {String? classId,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    throw HTError.unsupported('invoke on analyzer');
  }

  HTType visitAstNode(AstNode ast) => ast.accept(this);

  @override
  HTType visitCommentExpr(CommentExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitNullExpr(NullExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitBooleanExpr(BooleanExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitConstIntExpr(ConstIntExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitConstFloatExpr(ConstFloatExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitConstStringExpr(ConstStringExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitStringInterpolationExpr(StringInterpolationExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitGroupExpr(GroupExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitListExpr(ListExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitMapExpr(MapExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitSymbolExpr(SymbolExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitBinaryExpr(BinaryExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitTernaryExpr(TernaryExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitTypeExpr(TypeExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitParamTypeExpr(ParamTypeExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitFunctionTypeExpr(FuncTypeExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitCallExpr(CallExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitMemberExpr(MemberExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitMemberAssignExpr(MemberAssignExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitSubExpr(SubExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitSubAssignExpr(SubAssignExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType visitLibraryStmt(LibraryStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitImportStmt(ImportStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitExprStmt(ExprStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitBlockStmt(BlockStmt block) {
    return HTType.ANY;
  }

  @override
  HTType visitReturnStmt(ReturnStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitIfStmt(IfStmt ifStmt) {
    return HTType.ANY;
  }

  @override
  HTType visitWhileStmt(WhileStmt whileStmt) {
    return HTType.ANY;
  }

  @override
  HTType visitDoStmt(DoStmt doStmt) {
    return HTType.ANY;
  }

  @override
  HTType visitForStmt(ForStmt forStmt) {
    return HTType.ANY;
  }

  @override
  HTType visitForInStmt(ForInStmt forInStmt) {
    return HTType.ANY;
  }

  @override
  HTType visitWhenStmt(WhenStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitBreakStmt(BreakStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitContinueStmt(ContinueStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitVarDeclStmt(VarDeclStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitParamDeclStmt(ParamDeclExpr stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitReferConstructorExpr(ReferConstructorExpr stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitFuncDeclStmt(FuncDeclExpr stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitClassDeclStmt(ClassDeclStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitEnumDeclStmt(EnumDeclStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType visitTypeAliasStmt(TypeAliasDeclStmt stmt) {
    return HTType.ANY;
  }
}
