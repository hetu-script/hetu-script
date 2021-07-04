part of 'ast.dart';

/// Visitor interface for a abstract syntactic tree node
abstract class AbstractAstVisitor<T> {
  T visitEmptyExpr(EmptyExpr expr);

  T visitCommentExpr(CommentExpr expr);

  T visitNullExpr(NullExpr expr);

  T visitBooleanExpr(BooleanExpr expr);

  T visitConstIntExpr(ConstIntExpr expr);

  T visitConstFloatExpr(ConstFloatExpr expr);

  T visitConstStringExpr(ConstStringExpr expr);

  T visitStringInterpolationExpr(StringInterpolationExpr expr);

  T visitSymbolExpr(SymbolExpr expr);

  T visitListExpr(ListExpr expr);

  T visitMapExpr(MapExpr expr);

  T visitGroupExpr(GroupExpr expr);

  T visitTypeExpr(TypeExpr expr);

  T visitParamTypeExpr(ParamTypeExpr expr);

  T visitFunctionTypeExpr(FuncTypeExpr expr);

  T visitGenericTypeParamExpr(GenericTypeParamExpr expr);

  T visitUnaryPrefixExpr(UnaryPrefixExpr expr);

  T visitUnaryPostfixExpr(UnaryPostfixExpr expr);

  T visitBinaryExpr(BinaryExpr expr);

  T visitTernaryExpr(TernaryExpr expr);

  T visitMemberExpr(MemberExpr expr);

  T visitMemberAssignExpr(MemberAssignExpr expr);

  T visitSubExpr(SubExpr expr);

  T visitSubAssignExpr(SubAssignExpr expr);

  T visitCallExpr(CallExpr expr);

  T visitExprStmt(ExprStmt stmt);

  T visitBlockStmt(BlockStmt block);

  T visitReturnStmt(ReturnStmt stmt);

  T visitIfStmt(IfStmt ifStmt);

  T visitWhileStmt(WhileStmt whileStmt);

  T visitDoStmt(DoStmt doStmt);

  T visitForStmt(ForStmt forStmt);

  T visitForInStmt(ForInStmt forInStmt);

  T visitWhenStmt(WhenStmt stmt);

  T visitBreakStmt(BreakStmt stmt);

  T visitContinueStmt(ContinueStmt stmt);

  T visitLibraryDeclStmt(LibraryDecl stmt);

  T visitImportDeclStmt(ImportDecl stmt);

  T visitNamespaceDeclStmt(NamespaceDecl stmt);

  T visitTypeAliasDeclStmt(TypeAliasDecl stmt);

  T visitVarDeclStmt(VarDecl stmt);

  T visitParamDeclStmt(ParamDecl stmt);

  T visitReferConstructCallExpr(ReferConstructCallExpr stmt);

  T visitFuncDeclStmt(FuncDecl stmt);

  T visitClassDeclStmt(ClassDecl stmt);

  T visitEnumDeclStmt(EnumDecl stmt);
}
