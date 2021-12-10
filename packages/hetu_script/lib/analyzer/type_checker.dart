import '../ast/ast.dart';
import '../type/type.dart';
import '../declaration/namespace/library.dart';

class HTTypeChecker implements AbstractAstVisitor<HTType?> {
  final HTLibrary library;

  HTTypeChecker(this.library);

  HTType? visitAstNode(AstNode node) => node.accept(this);

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
    return HTType.any;
  }

  @override
  HTType? visitConstIntExpr(ConstIntExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitConstFloatExpr(ConstFloatExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitConstStringExpr(ConstStringExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitStringInterpolationExpr(StringInterpolationExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitGroupExpr(GroupExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitSpreadExpr(SpreadExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitListExpr(ListExpr expr) {
    return HTType.any;
  }

  // @override
  // HTType? visitMapExpr(MapExpr expr) {
  //   return HTType.ANY;
  // }

  @override
  HTType? visitIdentifierExpr(IdentifierExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitBinaryExpr(BinaryExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitTernaryExpr(TernaryExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitTypeExpr(TypeExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitParamTypeExpr(ParamTypeExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitFunctionTypeExpr(FuncTypeExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitCallExpr(CallExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitMemberExpr(MemberExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitMemberAssignExpr(MemberAssignExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitSubExpr(SubExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitSubAssignExpr(SubAssignExpr expr) {
    return HTType.any;
  }

  @override
  HTType? visitLibraryDecl(LibraryDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitImportExportDecl(ImportExportDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitExprStmt(ExprStmt stmt) {
    return HTType.any;
  }

  @override
  HTType? visitBlockStmt(BlockStmt block) {
    return HTType.any;
  }

  @override
  HTType? visitReturnStmt(ReturnStmt stmt) {
    return HTType.any;
  }

  @override
  HTType? visitIfStmt(IfStmt ifStmt) {
    return HTType.any;
  }

  @override
  HTType? visitWhileStmt(WhileStmt whileStmt) {
    return HTType.any;
  }

  @override
  HTType? visitDoStmt(DoStmt doStmt) {
    return HTType.any;
  }

  @override
  HTType? visitForStmt(ForStmt forStmt) {
    return HTType.any;
  }

  @override
  HTType? visitForInStmt(ForInStmt forInStmt) {
    return HTType.any;
  }

  @override
  HTType? visitWhenStmt(WhenStmt stmt) {
    return HTType.any;
  }

  @override
  HTType? visitBreakStmt(BreakStmt stmt) {
    return HTType.any;
  }

  @override
  HTType? visitContinueStmt(ContinueStmt stmt) {
    return HTType.any;
  }

  @override
  HTType? visitVarDecl(VarDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitParamDecl(ParamDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitReferConstructCallExpr(RedirectingConstructorCallExpr stmt) {
    return HTType.any;
  }

  @override
  HTType? visitFuncDecl(FuncDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitNamespaceDecl(NamespaceDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitClassDecl(ClassDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitEnumDecl(EnumDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitTypeAliasDecl(TypeAliasDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitStructDecl(StructDecl stmt) {
    return HTType.any;
  }

  @override
  HTType? visitStructObjField(StructObjField field) {
    return HTType.any;
  }

  @override
  HTType? visitStructObjExpr(StructObjExpr obj) {
    return HTType.any;
  }
}
