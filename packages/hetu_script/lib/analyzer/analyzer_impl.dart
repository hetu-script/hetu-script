import '../ast/ast.dart';
import 'analysis_error.dart';
import 'type_checker.dart';

/// A Ast interpreter for static analysis.
class HTAnalyzerImpl implements AbstractASTVisitor<void> {
  final typeChecker = HTTypeChecker();

  /// Errors of a single file
  late List<HTAnalysisError> errors = [];

  void analyzeAST(ASTNode node) => node.accept(this);

  @override
  void visitCompilation(ASTCompilation node) {
    node.subAccept(this);
  }

  @override
  void visitCompilationUnit(ASTSource node) {
    node.subAccept(this);
  }

  @override
  void visitEmptyExpr(ASTEmptyLine node) {}

  @override
  void visitNullExpr(ASTLiteralNull node) {}

  @override
  void visitBooleanExpr(ASTLiteralBoolean node) {}

  @override
  void visitIntLiteralExpr(ASTLiteralInteger node) {}

  @override
  void visitFloatLiteralExpr(ASTLiteralFloat node) {}

  @override
  void visitStringLiteralExpr(ASTLiteralString node) {}

  @override
  void visitStringInterpolationExpr(ASTLiteralStringInterpolation node) {
    node.subAccept(this);
  }

  @override
  void visitIdentifierExpr(IdentifierExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSpreadExpr(SpreadExpr node) {
    node.subAccept(this);
  }

  @override
  void visitCommaExpr(CommaExpr node) {
    node.subAccept(this);
  }

  @override
  void visitListExpr(ListExpr node) {
    node.subAccept(this);
  }

  @override
  void visitInOfExpr(InOfExpr node) {
    node.subAccept(this);
  }

  @override
  void visitGroupExpr(GroupExpr node) {
    node.subAccept(this);
  }

  @override
  void visitTypeExpr(TypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitParamTypeExpr(ParamTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFunctionTypeExpr(FuncTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFieldTypeExpr(FieldTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitStructuralTypeExpr(StructuralTypeExpr node) {
    node.subAccept(this);
  }

  @override
  void visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    node.subAccept(this);
  }

  /// -e, !e，++e, --e
  @override
  void visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    node.subAccept(this);
  }

  @override
  void visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    node.subAccept(this);
  }

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||
  @override
  void visitBinaryExpr(BinaryExpr node) {
    node.subAccept(this);
  }

  /// e1 ? e2 : e3
  @override
  void visitTernaryExpr(TernaryExpr node) {
    node.subAccept(this);
  }

  @override
  void visitAssignExpr(AssignExpr node) {
    node.subAccept(this);
  }

  @override
  void visitMemberExpr(MemberExpr node) {
    node.subAccept(this);
  }

  @override
  void visitSubExpr(SubExpr node) {
    node.subAccept(this);
  }

  @override
  void visitCallExpr(CallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitAssertStmt(AssertStmt node) {
    node.subAccept(this);
  }

  @override
  void visitThrowStmt(ThrowStmt node) {
    node.subAccept(this);
  }

  @override
  void visitExprStmt(ExprStmt node) {
    node.subAccept(this);
  }

  @override
  void visitBlockStmt(BlockStmt node) {
    node.subAccept(this);
  }

  @override
  void visitReturnStmt(ReturnStmt node) {
    node.subAccept(this);
  }

  @override
  void visitIf(IfStmt node) {
    node.subAccept(this);
  }

  @override
  void visitWhileStmt(WhileStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDoStmt(DoStmt node) {
    node.subAccept(this);
  }

  @override
  void visitForStmt(ForStmt node) {
    node.subAccept(this);
  }

  @override
  void visitForRangeStmt(ForRangeStmt node) {
    node.subAccept(this);
  }

  @override
  void visitWhen(WhenStmt node) {
    node.subAccept(this);
  }

  @override
  void visitBreakStmt(BreakStmt node) {
    node.subAccept(this);
  }

  @override
  void visitContinueStmt(ContinueStmt node) {
    node.subAccept(this);
  }

  @override
  void visitDeleteStmt(DeleteStmt node) {
    node.subAccept(this);
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
  }

  // @override
  // void visitConstDecl(ConstDecl node) {
  //   node.subAccept(this);
  // }

  @override
  void visitVarDecl(VarDecl node) {
    node.subAccept(this);
  }

  @override
  void visitDestructuringDecl(DestructuringDecl node) {
    node.subAccept(this);
  }

  @override
  void visitParamDecl(ParamDecl node) {
    node.subAccept(this);
  }

  @override
  void visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    node.subAccept(this);
  }

  @override
  void visitFuncDecl(FuncDecl node) {
    node.subAccept(this);
  }

  @override
  void visitClassDecl(ClassDecl node) {
    node.subAccept(this);
  }

  @override
  void visitEnumDecl(EnumDecl node) {
    node.subAccept(this);
  }

  @override
  void visitStructDecl(StructDecl node) {
    node.subAccept(this);
  }

  @override
  void visitStructObjExpr(StructObjExpr node) {
    node.subAccept(this);
  }

  @override
  void visitStructObjField(StructObjField node) {
    node.subAccept(this);
  }
}
