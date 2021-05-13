part of 'ast.dart';

/// Visitor interface for a abstract syntactic tree node
abstract class AbstractAstVisitor {
  dynamic visitNullExpr(NullExpr expr);

  dynamic visitBooleanExpr(BooleanExpr expr);

  dynamic visitConstIntExpr(ConstIntExpr expr);

  dynamic visitConstFloatExpr(ConstFloatExpr expr);

  dynamic visitConstStringExpr(ConstStringExpr expr);

  dynamic visitLiteralListExpr(LiteralListExpr expr);

  dynamic visitLiteralMapExpr(LiteralMapExpr expr);

  dynamic visitGroupExpr(GroupExpr expr);

  dynamic visitUnaryExpr(UnaryExpr expr);

  dynamic visitBinaryExpr(BinaryExpr expr);

  dynamic visitTernaryExpr(TernaryExpr expr);

  dynamic visitTypeExpr(TypeExpr expr);

  dynamic visitParamTypeExpr(ParamTypeExpr expr);

  dynamic visitFunctionTypeExpr(FunctionTypeExpr expr);

  dynamic visitSymbolExpr(SymbolExpr expr);

  // dynamic visitAssignExpr(AssignExpr expr);

  dynamic visitSubGetExpr(SubGetExpr expr);

  // dynamic visitSubSetExpr(SubSetExpr expr);

  dynamic visitMemberGetExpr(MemberGetExpr expr);

  // dynamic visitMemberSetExpr(MemberSetExpr expr);

  dynamic visitCallExpr(CallExpr expr);

  dynamic visitUnaryPostfixExpr(UnaryPostfixExpr expr);

  dynamic visitExprStmt(ExprStmt stmt);

  dynamic visitBlockStmt(BlockStmt stmt);

  dynamic visitReturnStmt(ReturnStmt stmt);

  dynamic visitIfStmt(IfStmt stmt);

  dynamic visitWhileStmt(WhileStmt stmt);

  dynamic visitDoStmt(DoStmt stmt);

  dynamic visitBreakStmt(BreakStmt stmt);

  dynamic visitContinueStmt(ContinueStmt stmt);

  dynamic visitVarDeclStmt(VarDecl stmt);

  dynamic visitParamDeclStmt(ParamDecl stmt);

  dynamic visitFuncDeclStmt(FuncDecl stmt);

  dynamic visitClassDeclStmt(ClassDecl stmt);

  dynamic visitEnumDeclStmt(EnumDecl stmt);
}
