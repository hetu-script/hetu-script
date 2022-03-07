// ignore_for_file: body_might_complete_normally_nullable

part of '../ast.dart';

/// An object that can be used to visit an AST structure.
///
/// There are other helper classes that implement this interface:
/// * RecursiveAstVisitor which will visit every sub node in a structure,
/// * GeneralizingAstVisitor which will visit a node AND its every sub node.
abstract class AbstractAstVisitor<T> {
  T? visitCompilation(AstCompilation node) {}

  T? visitCompilationUnit(AstSource node) {}

  T? visitEmptyExpr(EmptyLine node) {}

  T? visitNullExpr(NullExpr node) {}

  T? visitBooleanExpr(BooleanLiteralExpr node) {}

  T? visitIntLiteralExpr(IntegerLiteralExpr node) {}

  T? visitFloatLiteralExpr(FloatLiteralExpr node) {}

  T? visitStringLiteralExpr(StringLiteralExpr node) {}

  T? visitStringInterpolationExpr(StringInterpolationExpr node) {}

  T? visitIdentifierExpr(IdentifierExpr node) {}

  T? visitSpreadExpr(SpreadExpr node) {}

  T? visitCommaExpr(CommaExpr node) {}

  T? visitListExpr(ListExpr node) {}

  T? visitInOfExpr(InOfExpr node) {}

  T? visitGroupExpr(GroupExpr node) {}

  T? visitTypeExpr(TypeExpr node) {}

  T? visitParamTypeExpr(ParamTypeExpr node) {}

  T? visitFunctionTypeExpr(FuncTypeExpr node) {}

  T? visitFieldTypeExpr(FieldTypeExpr node) {}

  T? visitStructuralTypeExpr(StructuralTypeExpr node) {}

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

  T? visitAssertStmt(AssertStmt node) {}

  T? visitThrowStmt(ThrowStmt node) {}

  T? visitExprStmt(ExprStmt node) {}

  T? visitBlockStmt(BlockStmt node) {}

  T? visitReturnStmt(ReturnStmt node) {}

  T? visitIf(IfStmt node) {}

  T? visitWhileStmt(WhileStmt node) {}

  T? visitDoStmt(DoStmt node) {}

  T? visitForStmt(ForStmt node) {}

  T? visitForRangeStmt(ForRangeStmt node) {}

  T? visitWhen(WhenStmt node) {}

  T? visitBreakStmt(BreakStmt node) {}

  T? visitContinueStmt(ContinueStmt node) {}

  T? visitDeleteStmt(DeleteStmt node) {}

  T? visitDeleteMemberStmt(DeleteMemberStmt node) {}

  T? visitDeleteSubStmt(DeleteSubStmt node) {}

  T? visitImportExportDecl(ImportExportDecl node) {}

  T? visitNamespaceDecl(NamespaceDecl node) {}

  T? visitTypeAliasDecl(TypeAliasDecl node) {}

  // T? visitConstDecl(ConstDecl node) {}

  T? visitVarDecl(VarDecl node) {}

  T? visitDestructuringDecl(DestructuringDecl node) {}

  T? visitParamDecl(ParamDecl node) {}

  T? visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {}

  T? visitFuncDecl(FuncDecl node) {}

  T? visitClassDecl(ClassDecl node) {}

  T? visitEnumDecl(EnumDecl node) {}

  T? visitStructDecl(StructDecl node) {}

  T? visitStructObjExpr(StructObjExpr node) {}

  T? visitStructObjField(StructObjField node) {}
}
