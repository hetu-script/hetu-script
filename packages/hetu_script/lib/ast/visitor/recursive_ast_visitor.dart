import '../ast.dart';

/// An AST visitor that will recursively visit all of the sub nodes in an AST
/// structure. For example, using an instance of this class to visit a [Block]
/// will also cause all of the statements in the node to be visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited node to visit its children.
/// Otherwise the children of the visited node might not be visited.
abstract class RecursiveAstVisitor<T> implements AbstractAstVisitor<T> {
  @override
  T? visitEmptyExpr(EmptyExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitCommentExpr(CommentExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitNullExpr(NullExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitBooleanExpr(BooleanExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitConstIntExpr(ConstIntExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitConstFloatExpr(ConstFloatExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitConstStringExpr(ConstStringExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitStringInterpolationExpr(StringInterpolationExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitIdentifierExpr(IdentifierExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitListExpr(ListExpr node) {
    node.subAccept(this);
  }

  // @override
  // T? visitMapExpr(MapExpr node) {
  //   node.subAccept(this);
  // }

  @override
  T? visitGroupExpr(GroupExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitTypeExpr(TypeExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitParamTypeExpr(ParamTypeExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitFunctionTypeExpr(FuncTypeExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitBinaryExpr(BinaryExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitTernaryExpr(TernaryExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitMemberExpr(MemberExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitMemberAssignExpr(MemberAssignExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitSubExpr(SubExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitSubAssignExpr(SubAssignExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitCallExpr(CallExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitExprStmt(ExprStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitBlockStmt(BlockStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitReturnStmt(ReturnStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitIfStmt(IfStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitWhileStmt(WhileStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitDoStmt(DoStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitForStmt(ForStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitForInStmt(ForInStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitWhenStmt(WhenStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitBreakStmt(BreakStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitContinueStmt(ContinueStmt node) {
    node.subAccept(this);
  }

  @override
  T? visitLibraryDecl(LibraryDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitImportDecl(ImportDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitNamespaceDecl(NamespaceDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitTypeAliasDecl(TypeAliasDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitVarDecl(VarDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitParamDecl(ParamDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    node.subAccept(this);
  }

  @override
  T? visitFuncDecl(FuncDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitClassDecl(ClassDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitEnumDecl(EnumDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitStructDecl(StructDecl node) {
    node.subAccept(this);
  }

  @override
  T? visitStructObjExpr(StructObjExpr node) {
    node.subAccept(this);
  }
}
