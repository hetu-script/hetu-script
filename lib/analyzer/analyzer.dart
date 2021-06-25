import '../source/source.dart';
import '../source/source_provider.dart';
// import '../binding/external_function.dart';
import '../type/type.dart';
import '../declaration/namespace.dart';
// import '../core/function/abstract_function.dart';
// import '../object/object.dart';
import '../interpreter/abstract_interpreter.dart';
// import '../core/class/enum.dart';
// import '../core/class/class.dart';
import '../grammar/lexicon.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
// import 'ast_function.dart';
import '../scanner/parser.dart';
import '../ast/ast_compilation.dart';
import 'analysis_error.dart';

import 'analysis_result.dart';

import '../type/type.dart';

import '../declaration/library.dart';

class AnalyzerConfig extends InterpreterConfig {
  final List<ErrorProcessor> errorProcessors;

  const AnalyzerConfig(
      {SourceType sourceType = SourceType.module,
      bool reload = false,
      bool errorDetail = true,
      bool scriptStackTrace = true,
      int scriptStackTraceMaxline = 10,
      bool externalStackTrace = true,
      this.errorProcessors = const []})
      : super(
            sourceType: sourceType,
            reload: reload,
            errorDetail: errorDetail,
            scriptStackTrace: scriptStackTrace,
            scriptStackTraceThreshhold: scriptStackTraceMaxline,
            externalStackTrace: externalStackTrace);
}

class HTAnalyzer extends AbstractInterpreter
    implements AbstractAstVisitor<HTType> {
  @override
  late HTAstParser parser;

  final _sources = HTAstCompilation('');

  late HTAstModule _curCode;

  late AnalyzerConfig _curConfig;

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

  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  late HTLibrary _curLibrary;
  @override
  HTLibrary get curLibrary => _curLibrary;

  HTType? _curExprType;

  late String _savedModuleName;
  late HTNamespace _savedNamespace;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  HTAnalyzer(
      {HTErrorHandler? errorHandler,
      SourceProvider? sourceProvider,
      AnalyzerConfig config = const AnalyzerConfig()})
      : super(config,
            errorHandler: errorHandler, sourceProvider: sourceProvider) {
    _curNamespace = global;
  }

  @override
  Future<void> evalSource(HTSource source,
      {String? libraryName,
      HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    // _savedModuleName = _curModuleFullName;
    // _savedNamespace = _curNamespace;

    // parser = HTAstParser();

    // _curModuleFullName = moduleFullName ?? HTLexicon.anonymousScript;
    // _curNamespace = namespace ?? HTNamespace(this, id: _curModuleFullName);

    // try {
    //   final compilation = await parser.parseAll(content, sourceProvider,
    //       moduleFullName: _curModuleFullName, config: config ?? this.config);

    //   _sources.join(compilation);

    //   for (final module in compilation.modules) {
    //     _curCode = module;
    //     _curModuleFullName = module.fullName;
    //     for (final stmt in module.nodes) {
    //       visitAstNode(stmt);
    //     }
    //   }

    //   _curModuleFullName = _savedModuleName;
    //   _curNamespace = _savedNamespace;
    // } catch (error, stack) {
    //   if (errorHandled) {
    //     rethrow;
    //   } else {
    //     handleError(error, stack);
    //   }
    // }
  }

  /// 解析文件
  @override
  Future<void> evalFile(String key,
      {bool useLastModuleFullName = false,
      bool reload = false,
      String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {}

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
