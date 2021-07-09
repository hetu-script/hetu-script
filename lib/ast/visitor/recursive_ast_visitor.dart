import '../ast.dart';

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure. For example, using an instance of this class to visit a [Block]
/// will also cause all of the statements in the node to be visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited node to visit its children.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
abstract class RecursiveAstVisitor<T> implements AbstractAstVisitor<T> {
  @override
  T? visitEmptyExpr(EmptyExpr node) {}

  @override
  T? visitCommentExpr(CommentExpr node) {}

  @override
  T? visitNullExpr(NullExpr node) {}

  @override
  T? visitBooleanExpr(BooleanExpr node) {}

  @override
  T? visitConstIntExpr(ConstIntExpr node) {}

  @override
  T? visitConstFloatExpr(ConstFloatExpr node) {}

  @override
  T? visitConstStringExpr(ConstStringExpr node) {}

  @override
  T? visitStringInterpolationExpr(StringInterpolationExpr node) {}

  @override
  T? visitSymbolExpr(SymbolExpr node) {}

  @override
  T? visitListExpr(ListExpr node) {}

  @override
  T? visitMapExpr(MapExpr node) {}

  @override
  T? visitGroupExpr(GroupExpr node) {}

  @override
  T? visitTypeExpr(TypeExpr node) {}

  @override
  T? visitParamTypeExpr(ParamTypeExpr node) {}

  @override
  T? visitFunctionTypeExpr(FuncTypeExpr node) {}

  @override
  T? visitGenericTypeParamExpr(GenericTypeParameterExpr node) {}

  @override
  T? visitUnaryPrefixExpr(UnaryPrefixExpr node) {}

  @override
  T? visitUnaryPostfixExpr(UnaryPostfixExpr node) {}

  @override
  T? visitBinaryExpr(BinaryExpr node) {}

  @override
  T? visitTernaryExpr(TernaryExpr node) {}

  @override
  T? visitMemberExpr(MemberExpr node) {}

  @override
  T? visitMemberAssignExpr(MemberAssignExpr node) {}

  @override
  T? visitSubExpr(SubExpr node) {}

  @override
  T? visitSubAssignExpr(SubAssignExpr node) {}

  @override
  T? visitCallExpr(CallExpr node) {}

  @override
  T? visitExprStmt(ExprStmt node) {}

  @override
  T? visitBlockStmt(BlockStmt node) {}

  @override
  T? visitReturnStmt(ReturnStmt node) {}

  @override
  T? visitIfStmt(IfStmt node) {}

  @override
  T? visitWhileStmt(WhileStmt node) {}

  @override
  T? visitDoStmt(DoStmt node) {}

  @override
  T? visitForStmt(ForStmt node) {}

  @override
  T? visitForInStmt(ForInStmt node) {}

  @override
  T? visitWhenStmt(WhenStmt node) {}

  @override
  T? visitBreakStmt(BreakStmt node) {}

  @override
  T? visitContinueStmt(ContinueStmt node) {}

  @override
  T? visitLibraryDecl(LibraryDecl node) {}

  @override
  T? visitImportDecl(ImportDecl node) {}

  @override
  T? visitNamespaceDecl(NamespaceDecl node) {}

  @override
  T? visitTypeAliasDecl(TypeAliasDecl node) {}

  @override
  T? visitVarDecl(VarDecl node) {}

  @override
  T? visitParamDecl(ParamDecl node) {}

  @override
  T? visitReferConstructCallExpr(ReferConstructCallExpr node) {}

  @override
  T? visitFuncDecl(FuncDecl node) {}

  @override
  T? visitClassDecl(ClassDecl node) {}

  @override
  T? visitEnumDecl(EnumDecl node) {}

  @override
  T? visitStructDecl(StructDecl node) {}
}
