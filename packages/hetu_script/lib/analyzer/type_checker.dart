import 'package:hetu_script/type/unresolved_type.dart';

// import '../type/nominal_type.dart';
import '../ast/ast.dart';
// import '../grammar/lexicon.dart';
// import '../shared/stringify.dart';
import '../type/type.dart';

/// A interpreter that compute [HTType] out of [AstNode]
class HTTypeChecker implements AbstractAstVisitor<HTType> {
  HTType evalAstNode(AstNode node) => node.accept(this);

  @override
  HTType visitCompilation(AstCompilation node) {
    throw 'Don\'t use this on AstCompilation.';
  }

  @override
  HTType visitCompilationUnit(AstSource node) {
    throw 'Don\'t use this on AstSource.';
  }

  @override
  HTType visitEmptyExpr(EmptyExpr node) {
    throw 'Not a value';
  }

  @override
  HTType visitNullExpr(NullExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitBooleanExpr(BooleanLiteralExpr node) {
    return HTUnresolvedType('bool');
  }

  @override
  HTType visitIntLiteralExpr(IntegerLiteralExpr node) {
    return HTUnresolvedType('int');
  }

  @override
  HTType visitFloatLiteralExpr(FloatLiteralExpr node) {
    return HTUnresolvedType('float');
  }

  @override
  HTType visitStringLiteralExpr(StringLiteralExpr node) {
    return HTUnresolvedType('str');
  }

  @override
  HTType visitStringInterpolationExpr(StringInterpolationExpr node) {
    return HTUnresolvedType('str');
  }

  @override
  HTType visitIdentifierExpr(IdentifierExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitSpreadExpr(SpreadExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitCommaExpr(CommaExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitListExpr(ListExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitInOfExpr(InOfExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitGroupExpr(GroupExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitTypeExpr(TypeExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitParamTypeExpr(ParamTypeExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitFunctionTypeExpr(FuncTypeExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitFieldTypeExpr(FieldTypeExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitStructuralTypeExpr(StructuralTypeExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    return HTType.nullType;
  }

  /// -e, !e，++e, --e
  @override
  HTType visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    return HTType.nullType;
  }

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||
  @override
  HTType visitBinaryExpr(BinaryExpr node) {
    return HTType.nullType;
  }

  /// e1 ? e2 : e3
  @override
  HTType visitTernaryExpr(TernaryExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitMemberExpr(MemberExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitMemberAssignExpr(MemberAssignExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitSubExpr(SubExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitSubAssignExpr(SubAssignExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitCallExpr(CallExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitAssertStmt(AssertStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitThrowStmt(ThrowStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitExprStmt(ExprStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitBlockStmt(BlockStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitReturnStmt(ReturnStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitIf(IfStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitWhileStmt(WhileStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitDoStmt(DoStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitForStmt(ForStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitForRangeStmt(ForRangeStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitWhen(WhenStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitBreakStmt(BreakStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitContinueStmt(ContinueStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitDeleteStmt(DeleteStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitDeleteMemberStmt(DeleteMemberStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitDeleteSubStmt(DeleteSubStmt node) {
    return HTType.nullType;
  }

  @override
  HTType visitImportExportDecl(ImportExportDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitNamespaceDecl(NamespaceDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitTypeAliasDecl(TypeAliasDecl node) {
    return HTType.nullType;
  }

  // @override
  // HTType visitConstDecl(ConstDecl node) {
  //
  // return HTType.nullType;
  // }

  @override
  HTType visitVarDecl(VarDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitDestructuringDecl(DestructuringDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitParamDecl(ParamDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitFuncDecl(FuncDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitClassDecl(ClassDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitEnumDecl(EnumDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitStructDecl(StructDecl node) {
    return HTType.nullType;
  }

  @override
  HTType visitStructObjExpr(StructObjExpr node) {
    return HTType.nullType;
  }

  @override
  HTType visitStructObjField(StructObjField node) {
    return HTType.nullType;
  }
}
