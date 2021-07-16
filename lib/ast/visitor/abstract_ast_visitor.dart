part of '../ast.dart';

/// An object that can be used to visit an AST structure.
///
/// There are other helper classes that implement this interface:
/// * RecursiveAstVisitor which will visit every sub node in a structure,
/// * GeneralizingAstVisitor which will visit a node AND its every sub node.
abstract class AbstractAstVisitor<T> {
  T? visitEmptyExpr(EmptyExpr node) {}

  T? visitCommentExpr(CommentExpr node) {}

  T? visitNullExpr(NullExpr node) {}

  T? visitBooleanExpr(BooleanExpr node) {}

  T? visitConstIntExpr(ConstIntExpr node) {}

  T? visitConstFloatExpr(ConstFloatExpr node) {}

  T? visitConstStringExpr(ConstStringExpr node) {}

  T? visitStringInterpolationExpr(StringInterpolationExpr node) {}

  T? visitSymbolExpr(SymbolExpr node) {}

  T? visitListExpr(ListExpr node) {}

  T? visitMapExpr(MapExpr node) {}

  T? visitGroupExpr(GroupExpr node) {}

  T? visitTypeExpr(TypeExpr node) {}

  T? visitParamTypeExpr(ParamTypeExpr node) {}

  T? visitFunctionTypeExpr(FuncTypeExpr node) {}

  T? visitGenericTypeParamExpr(GenericTypeParameterExpr node) {}

  T? visitUnaryPrefixExpr(UnaryPrefixExpr node) {}

  T? visitUnaryPostfixExpr(UnaryPostfixExpr node) {}

  T? visitBinaryExpr(BinaryExpr node) {}

  T? visitTernaryExpr(TernaryExpr node) {}

  T? visitMemberExpr(MemberExpr node) {}

  T? visitMemberAssignExpr(MemberAssignExpr node) {}

  T? visitSubExpr(SubExpr node) {}

  T? visitSubAssignExpr(SubAssignExpr node) {}

  T? visitCallExpr(CallExpr node) {}

  T? visitExprStmt(ExprStmt node) {}

  T? visitBlockStmt(BlockStmt node) {}

  T? visitReturnStmt(ReturnStmt node) {}

  T? visitIfStmt(IfStmt node) {}

  T? visitWhileStmt(WhileStmt node) {}

  T? visitDoStmt(DoStmt node) {}

  T? visitForStmt(ForStmt node) {}

  T? visitForInStmt(ForInStmt node) {}

  T? visitWhenStmt(WhenStmt node) {}

  T? visitBreakStmt(BreakStmt node) {}

  T? visitContinueStmt(ContinueStmt node) {}

  T? visitLibraryDecl(LibraryDecl node) {}

  T? visitImportDecl(ImportDecl node) {}

  T? visitNamespaceDecl(NamespaceDecl node) {}

  T? visitTypeAliasDecl(TypeAliasDecl node) {}

  T? visitVarDecl(VarDecl node) {}

  T? visitParamDecl(ParamDecl node) {}

  T? visitReferConstructCallExpr(RedirectingConstructCallExpr node) {}

  T? visitFuncDecl(FuncDecl node) {}

  T? visitClassDecl(ClassDecl node) {}

  T? visitEnumDecl(EnumDecl node) {}

  T? visitStructDecl(StructDecl node) {}
}
