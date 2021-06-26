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

  T visitListExpr(ListExpr expr);

  T visitMapExpr(MapExpr expr);

  T visitGroupExpr(GroupExpr expr);

  T visitSymbolExpr(SymbolExpr expr);

  T visitTypeExpr(TypeExpr expr);

  T visitParamTypeExpr(ParamTypeExpr expr);

  T visitFunctionTypeExpr(FuncTypeExpr expr);

  T visitUnaryPrefixExpr(UnaryPrefixExpr expr);

  T visitBinaryExpr(BinaryExpr expr);

  T visitTernaryExpr(TernaryExpr expr);

  T visitUnaryPostfixExpr(UnaryPostfixExpr expr);

  T visitMemberExpr(MemberExpr expr);

  T visitMemberAssignExpr(MemberAssignExpr expr);

  T visitSubExpr(SubExpr expr);

  T visitSubAssignExpr(SubAssignExpr expr);

  T visitCallExpr(CallExpr expr);

  T visitExprStmt(ExprStmt stmt);

  T visitBlockStmt(BlockStmt block);

  T visitLibraryStmt(LibraryStmt stmt);

  T visitImportStmt(ImportStmt stmt);

  T visitReturnStmt(ReturnStmt stmt);

  T visitIfStmt(IfStmt ifStmt);

  T visitWhileStmt(WhileStmt whileStmt);

  T visitDoStmt(DoStmt doStmt);

  T visitForStmt(ForStmt forStmt);

  T visitForInStmt(ForInStmt forInStmt);

  T visitWhenStmt(WhenStmt stmt);

  T visitBreakStmt(BreakStmt stmt);

  T visitContinueStmt(ContinueStmt stmt);

  T visitVarDeclStmt(VarDeclStmt stmt);

  T visitParamDeclStmt(ParamDeclExpr stmt);

  T visitReferConstructorExpr(ReferConstructorExpr stmt);

  T visitFuncDeclStmt(FuncDeclExpr stmt);

  T visitClassDeclStmt(ClassDeclStmt stmt);

  T visitEnumDeclStmt(EnumDeclStmt stmt);

  T visitTypeAliasStmt(TypeAliasDeclStmt stmt);
}
