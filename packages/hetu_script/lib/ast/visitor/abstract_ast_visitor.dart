// ignore_for_file: body_might_complete_normally_nullable

part of '../ast.dart';

/// An object that can be used to visit an AST structure.
///
/// There are other helper classes that implement this interface:
/// * RecursiveAstVisitor which will visit every sub node in a structure,
/// * GeneralizingAstVisitor which will visit a node AND its every sub node.
abstract class AbstractASTVisitor<T> {
  T? visitCompilation(ASTCompilation node) {}

  T? visitSource(ASTSource node) {}

  T? visitComment(ASTComment node) {}

  T? visitEmptyLine(ASTEmptyLine node) {}

  T? visitEmptyExpr(ASTEmpty node) {}

  T? visitNullExpr(ASTLiteralNull node) {}

  T? visitBooleanExpr(ASTLiteralBoolean node) {}

  T? visitIntLiteralExpr(ASTLiteralInteger node) {}

  T? visitFloatLiteralExpr(ASTLiteralFloat node) {}

  T? visitStringLiteralExpr(ASTLiteralString node) {}

  T? visitStringInterpolationExpr(ASTStringInterpolation node) {}

  T? visitIdentifierExpr(IdentifierExpr node) {}

  T? visitSpreadExpr(SpreadExpr node) {}

  T? visitCommaExpr(CommaExpr node) {}

  T? visitListExpr(ListExpr node) {}

  T? visitInOfExpr(InOfExpr node) {}

  T? visitGroupExpr(GroupExpr node) {}

  T? visitIntrinsicTypeExpr(IntrinsicTypeExpr node) {}

  T? visitNominalTypeExpr(NominalTypeExpr node) {}

  T? visitParamTypeExpr(ParamTypeExpr node) {}

  T? visitFunctionTypeExpr(FuncTypeExpr node) {}

  T? visitFieldTypeExpr(FieldTypeExpr node) {}

  T? visitStructuralTypeExpr(StructuralTypeExpr node) {}

  T? visitGenericTypeParamExpr(GenericTypeParameterExpr node) {}

  T? visitUnaryPrefixExpr(UnaryPrefixExpr node) {}

  T? visitUnaryPostfixExpr(UnaryPostfixExpr node) {}

  T? visitBinaryExpr(BinaryExpr node) {}

  T? visitTernaryExpr(TernaryExpr node) {}

  T? visitAssignExpr(AssignExpr node) {}

  T? visitMemberExpr(MemberExpr node) {}

  T? visitSubExpr(SubExpr node) {}

  T? visitCallExpr(CallExpr node) {}

  T? visitAssertStmt(AssertStmt node) {}

  T? visitThrowStmt(ThrowStmt node) {}

  T? visitExprStmt(ExprStmt node) {}

  T? visitBlockStmt(BlockStmt node) {}

  T? visitReturnStmt(ReturnStmt node) {}

  T? visitIf(IfExpr node) {}

  T? visitWhileStmt(WhileStmt node) {}

  T? visitDoStmt(DoStmt node) {}

  T? visitForStmt(ForExpr node) {}

  T? visitForRangeStmt(ForRangeExpr node) {}

  T? visitSwitch(SwitchStmt node) {}

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
