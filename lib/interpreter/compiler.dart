import '../source/source_provider.dart';
import '../type_system/type.dart';
import '../core/namespace/namespace.dart';
import '../core/abstract_interpreter.dart';
import '../grammar/lexicon.dart';
import '../error/errors.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import '../ast/ast_source.dart';

/// The information of snippet need goto
mixin GotoInfo {
  /// The module this variable declared in.
  late final String moduleFullName;

  /// The instructor pointer of the definition's bytecode.
  late final int? definitionIp;

  /// The line of the definition's bytecode.
  late final int? definitionLine;

  /// The column of the definition's bytecode.
  late final int? definitionColumn;
}

class HTCompiler implements AbstractAstVisitor {
  final _compilation = HTAstCompilation();

  late final HTErrorHandler errorHandler;
  late final SourceProvider sourceProvider;

  HTCompiler({HTErrorHandler? errorHandler, SourceProvider? sourceProvider}) {
    this.errorHandler = errorHandler ?? DefaultErrorHandler();
    this.sourceProvider = sourceProvider ?? DefaultSourceProvider();
  }

  Future<void> compile(HTAstCompilation astCompilation,
      {bool errorHandled = false}) async {}

  @override
  dynamic visitCommentExpr(CommentExpr expr) {}

  @override
  dynamic visitBlockCommentStmt(BlockCommentStmt stmt) {}

  @override
  dynamic visitNullExpr(NullExpr expr) {}

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) {}

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) {}

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {}

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {}

  @override
  dynamic visitGroupExpr(GroupExpr expr) {}

  @override
  dynamic visitLiteralListExpr(LiteralListExpr expr) {}

  @override
  dynamic visitLiteralMapExpr(LiteralMapExpr expr) {}

  @override
  dynamic visitSymbolExpr(SymbolExpr expr) {}

  @override
  dynamic visitUnaryPrefixExpr(UnaryPrefixExpr expr) {}

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {}

  @override
  dynamic visitTernaryExpr(TernaryExpr expr) {}

  @override
  dynamic visitTypeExpr(TypeExpr expr) {}

  @override
  dynamic visitFunctionTypeExpr(FunctionTypeExpr expr) {}

  @override
  dynamic visitCallExpr(CallExpr expr) {}

  @override
  dynamic visitUnaryPostfixExpr(UnaryPostfixExpr expr) {}

  @override
  dynamic visitMemberExpr(MemberExpr expr) {}

  @override
  dynamic visitMemberAssignExpr(MemberAssignExpr expr) {}

  @override
  dynamic visitSubExpr(SubGetExpr expr) {}

  @override
  dynamic visitSubAssignExpr(SubAssignExpr expr) {}

  @override
  dynamic visitImportStmt(ImportStmt stmt) {}

  @override
  dynamic visitExprStmt(ExprStmt stmt) {}

  @override
  dynamic visitBlockStmt(BlockStmt block) {}

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {}

  @override
  dynamic visitIfStmt(IfStmt stmt) {}

  @override
  dynamic visitWhileStmt(WhileStmt stmt) {}

  @override
  dynamic visitDoStmt(DoStmt stmt) {}

  @override
  dynamic visitForInStmt(ForInStmt stmt) {}

  @override
  dynamic visitForStmt(ForStmt stmt) {}

  @override
  dynamic visitWhenStmt(WhenStmt stmt) {}

  @override
  dynamic visitBreakStmt(BreakStmt stmt) {}

  @override
  dynamic visitContinueStmt(ContinueStmt stmt) {}

  @override
  dynamic visitVarDeclStmt(VarDeclStmt stmt) {}

  @override
  dynamic visitParamDeclStmt(ParamDeclExpr stmt) {}

  @override
  dynamic visitReferConstructorExpr(ReferConstructorExpr stmt) {}

  @override
  dynamic visitFuncDeclStmt(FuncDeclExpr stmt) {}

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {}

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {}
}
