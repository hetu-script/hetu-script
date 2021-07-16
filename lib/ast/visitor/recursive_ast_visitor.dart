import '../ast.dart';

/// An AST visitor that will recursively visit all of the sub nodes in an AST
/// structure. For example, using an instance of this class to visit a [Block]
/// will also cause all of the statements in the node to be visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited node to visit its children.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
abstract class RecursiveAstVisitor<T> implements AbstractAstVisitor<T> {
  @override
  T? visitEmptyExpr(EmptyExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitCommentExpr(CommentExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitNullExpr(NullExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitBooleanExpr(BooleanExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitConstIntExpr(ConstIntExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitConstFloatExpr(ConstFloatExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitConstStringExpr(ConstStringExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitStringInterpolationExpr(StringInterpolationExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitSymbolExpr(SymbolExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitListExpr(ListExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitMapExpr(MapExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitGroupExpr(GroupExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitTypeExpr(TypeExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitParamTypeExpr(ParamTypeExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitFunctionTypeExpr(FuncTypeExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitBinaryExpr(BinaryExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitTernaryExpr(TernaryExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitMemberExpr(MemberExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitMemberAssignExpr(MemberAssignExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitSubExpr(SubExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitSubAssignExpr(SubAssignExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitCallExpr(CallExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitExprStmt(ExprStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitBlockStmt(BlockStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitReturnStmt(ReturnStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitIfStmt(IfStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitWhileStmt(WhileStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitDoStmt(DoStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitForStmt(ForStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitForInStmt(ForInStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitWhenStmt(WhenStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitBreakStmt(BreakStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitContinueStmt(ContinueStmt node) {
    node.acceptAll(this);
  }

  @override
  T? visitLibraryDecl(LibraryDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitImportDecl(ImportDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitNamespaceDecl(NamespaceDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitTypeAliasDecl(TypeAliasDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitVarDecl(VarDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitParamDecl(ParamDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitReferConstructCallExpr(RedirectingConstructCallExpr node) {
    node.acceptAll(this);
  }

  @override
  T? visitFuncDecl(FuncDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitClassDecl(ClassDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitEnumDecl(EnumDecl node) {
    node.acceptAll(this);
  }

  @override
  T? visitStructDecl(StructDecl node) {
    node.acceptAll(this);
  }
}
