import '../ast.dart';

/// An AST visitor that will recursively visit all of the nodes in an AST
/// structure. For example, using an instance of this class to visit a [Block]
/// will also cause all of the statements in the block to be visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited node to visit its children.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
abstract class RecursiveAstVisitor<T> implements AbstractAstVisitor<T> {
  @override
  T? visitEmptyExpr(EmptyExpr expr) {}

  @override
  T? visitCommentExpr(CommentExpr expr) {}

  @override
  T? visitNullExpr(NullExpr expr) {}

  @override
  T? visitBooleanExpr(BooleanExpr expr) {}

  @override
  T? visitConstIntExpr(ConstIntExpr expr) {}

  @override
  T? visitConstFloatExpr(ConstFloatExpr expr) {}

  @override
  T? visitConstStringExpr(ConstStringExpr expr) {}

  @override
  T? visitStringInterpolationExpr(StringInterpolationExpr expr) {}

  @override
  T? visitSymbolExpr(SymbolExpr expr) {}

  @override
  T? visitListExpr(ListExpr expr) {}

  @override
  T? visitMapExpr(MapExpr expr) {}

  @override
  T? visitGroupExpr(GroupExpr expr) {}

  @override
  T? visitTypeExpr(TypeExpr expr) {}

  @override
  T? visitParamTypeExpr(ParamTypeExpr expr) {}

  @override
  T? visitFunctionTypeExpr(FuncTypeExpr expr) {}

  @override
  T? visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {}

  @override
  T? visitUnaryPrefixExpr(UnaryPrefixExpr expr) {}

  @override
  T? visitUnaryPostfixExpr(UnaryPostfixExpr expr) {}

  @override
  T? visitBinaryExpr(BinaryExpr expr) {}

  @override
  T? visitTernaryExpr(TernaryExpr expr) {}

  @override
  T? visitMemberExpr(MemberExpr expr) {}

  @override
  T? visitMemberAssignExpr(MemberAssignExpr expr) {}

  @override
  T? visitSubExpr(SubExpr expr) {}

  @override
  T? visitSubAssignExpr(SubAssignExpr expr) {}

  @override
  T? visitCallExpr(CallExpr expr) {}

  @override
  T? visitExprStmt(ExprStmt stmt) {}

  @override
  T? visitBlockStmt(BlockStmt block) {}

  @override
  T? visitReturnStmt(ReturnStmt stmt) {}

  @override
  T? visitIfStmt(IfStmt ifStmt) {}

  @override
  T? visitWhileStmt(WhileStmt whileStmt) {}

  @override
  T? visitDoStmt(DoStmt doStmt) {}

  @override
  T? visitForStmt(ForStmt forStmt) {}

  @override
  T? visitForInStmt(ForInStmt forInStmt) {}

  @override
  T? visitWhenStmt(WhenStmt stmt) {}

  @override
  T? visitBreakStmt(BreakStmt stmt) {}

  @override
  T? visitContinueStmt(ContinueStmt stmt) {}

  @override
  T? visitLibraryDecl(LibraryDecl decl) {}

  @override
  T? visitImportDecl(ImportDecl decl) {}

  @override
  T? visitNamespaceDecl(NamespaceDecl decl) {}

  @override
  T? visitTypeAliasDecl(TypeAliasDecl decl) {}

  @override
  T? visitVarDecl(VarDecl decl) {}

  @override
  T? visitParamDecl(ParamDecl decl) {}

  @override
  T? visitReferConstructCallExpr(ReferConstructCallExpr expr) {}

  @override
  T? visitFuncDecl(FuncDecl decl) {}

  @override
  T? visitClassDecl(ClassDecl decl) {}

  @override
  T? visitEnumDecl(EnumDecl decl) {}

  @override
  T? visitStructDecl(StructDecl decl) {}
}
