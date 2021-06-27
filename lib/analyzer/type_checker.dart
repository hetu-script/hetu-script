import '../ast/ast.dart';
import '../type/type.dart';
import '../declaration/library.dart';

class HTTypeChecker implements AbstractAstVisitor<HTType?> {
  final HTLibrary library;

  HTTypeChecker(this.library);

  HTType? analyzeAst(AstNode node) => node.accept(this);

  @override
  HTType? visitEmptyExpr(EmptyExpr expr) {}

  @override
  HTType? visitCommentExpr(CommentExpr expr) {}

  @override
  HTType? visitNullExpr(NullExpr expr) {
    return HTType.NULL;
  }

  @override
  HTType? visitBooleanExpr(BooleanExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitConstIntExpr(ConstIntExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitConstFloatExpr(ConstFloatExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitConstStringExpr(ConstStringExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitStringInterpolationExpr(StringInterpolationExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitGroupExpr(GroupExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitListExpr(ListExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitMapExpr(MapExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitSymbolExpr(SymbolExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitBinaryExpr(BinaryExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitTernaryExpr(TernaryExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitTypeExpr(TypeExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitParamTypeExpr(ParamTypeExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitFunctionTypeExpr(FuncTypeExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitCallExpr(CallExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitMemberExpr(MemberExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitMemberAssignExpr(MemberAssignExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitSubExpr(SubExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitSubAssignExpr(SubAssignExpr expr) {
    return HTType.ANY;
  }

  @override
  HTType? visitLibraryStmt(LibraryStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitImportStmt(ImportStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitExprStmt(ExprStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitBlockStmt(BlockStmt block) {
    return HTType.ANY;
  }

  @override
  HTType? visitReturnStmt(ReturnStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitIfStmt(IfStmt ifStmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitWhileStmt(WhileStmt whileStmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitDoStmt(DoStmt doStmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitForStmt(ForStmt forStmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitForInStmt(ForInStmt forInStmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitWhenStmt(WhenStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitBreakStmt(BreakStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitContinueStmt(ContinueStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitVarDeclStmt(VarDeclStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitParamDeclStmt(ParamDeclExpr stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitReferConstructCallExpr(ReferConstructCallExpr stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitFuncDeclStmt(FuncDeclExpr stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitClassDeclStmt(ClassDeclStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitEnumDeclStmt(EnumDeclStmt stmt) {
    return HTType.ANY;
  }

  @override
  HTType? visitTypeDeclStmt(TypeDeclStmt stmt) {
    return HTType.ANY;
  }
}
