part of 'ast.dart';

/// Visitor interface for a abstract syntactic tree node
abstract class AbstractAstVisitor {
  dynamic visitCommentExpr(CommentExpr expr);

  dynamic visitNullExpr(NullExpr expr);

  dynamic visitBooleanExpr(BooleanExpr expr);

  dynamic visitConstIntExpr(ConstIntExpr expr);

  dynamic visitConstFloatExpr(ConstFloatExpr expr);

  dynamic visitConstStringExpr(ConstStringExpr expr);

  dynamic visitLiteralListExpr(LiteralListExpr expr);

  dynamic visitLiteralMapExpr(LiteralMapExpr expr);

  dynamic visitGroupExpr(GroupExpr expr);

  dynamic visitSymbolExpr(SymbolExpr expr);

  dynamic visitTypeExpr(TypeExpr expr);

  dynamic visitParamTypeExpr(ParamTypeExpr expr);

  dynamic visitFunctionTypeExpr(FunctionTypeExpr expr);

  dynamic visitUnaryPrefixExpr(UnaryPrefixExpr expr);

  dynamic visitBinaryExpr(BinaryExpr expr);

  dynamic visitTernaryExpr(TernaryExpr expr);

  dynamic visitUnaryPostfixExpr(UnaryPostfixExpr expr);

  dynamic visitMemberExpr(MemberExpr expr);

  dynamic visitMemberAssignExpr(MemberAssignExpr expr);

  dynamic visitSubExpr(SubExpr expr);

  dynamic visitSubAssignExpr(SubAssignExpr expr);

  dynamic visitCallExpr(CallExpr expr);

  dynamic visitExprStmt(ExprStmt stmt);

  dynamic visitBlockStmt(BlockStmt block);

  dynamic visitLibraryStmt(LibraryStmt stmt);

  dynamic visitImportStmt(ImportStmt stmt);

  dynamic visitReturnStmt(ReturnStmt stmt);

  dynamic visitIfStmt(IfStmt ifStmt);

  dynamic visitWhileStmt(WhileStmt whileStmt);

  dynamic visitDoStmt(DoStmt doStmt);

  dynamic visitForStmt(ForStmt forStmt);

  dynamic visitForInStmt(ForInStmt forInStmt);

  dynamic visitWhenStmt(WhenStmt stmt);

  dynamic visitBreakStmt(BreakStmt stmt);

  dynamic visitContinueStmt(ContinueStmt stmt);

  dynamic visitVarDeclStmt(VarDeclStmt stmt);

  dynamic visitParamDeclStmt(ParamDeclExpr stmt);

  dynamic visitReferConstructorExpr(ReferConstructorExpr stmt);

  dynamic visitFuncDeclStmt(FuncDeclExpr stmt);

  dynamic visitClassDeclStmt(ClassDeclStmt stmt);

  dynamic visitEnumDeclStmt(EnumDeclStmt stmt);
}
