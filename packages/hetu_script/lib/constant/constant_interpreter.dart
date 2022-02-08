import '../ast/ast.dart';
import 'constant.dart';
import '../grammar/lexicon.dart';

class HTConstantValue {
  final dynamic value;
  final HTConstantType type;

  HTConstantValue(this.type, this.value);
}

/// A interpreter that computes the constant value before compilation.
/// If the AstNode provided is non-constant value, return null.
class HTConstantInterpreter implements AbstractAstVisitor<HTConstantValue?> {
  @override
  HTConstantValue? visitEmptyExpr(EmptyExpr node) => null;

  @override
  HTConstantValue? visitNullExpr(NullExpr node) => null;

  @override
  HTConstantValue? visitBooleanExpr(BooleanLiteralExpr node) =>
      HTConstantValue(HTConstantType.boolean, node.value);

  @override
  HTConstantValue? visitIntLiteralExpr(IntLiteralExpr node) =>
      HTConstantValue(HTConstantType.integer, node.value);

  @override
  HTConstantValue? visitFloatLiteralExpr(FloatLiteralExpr node) =>
      HTConstantValue(HTConstantType.float, node.value);

  @override
  HTConstantValue? visitStringLiteralExpr(StringLiteralExpr node) =>
      HTConstantValue(HTConstantType.string, node.value);

  @override
  HTConstantValue? visitStringInterpolationExpr(StringInterpolationExpr node) =>
      null;

  @override
  HTConstantValue? visitIdentifierExpr(IdentifierExpr node) => null;

  @override
  HTConstantValue? visitSpreadExpr(SpreadExpr node) => null;

  @override
  HTConstantValue? visitCommaExpr(CommaExpr node) => null;

  @override
  HTConstantValue? visitListExpr(ListExpr node) => null;

  @override
  HTConstantValue? visitInOfExpr(InOfExpr node) => null;

  @override
  HTConstantValue? visitGroupExpr(GroupExpr node) => null;

  @override
  HTConstantValue? visitTypeExpr(TypeExpr node) => null;

  @override
  HTConstantValue? visitParamTypeExpr(ParamTypeExpr node) => null;

  @override
  HTConstantValue? visitFunctionTypeExpr(FuncTypeExpr node) => null;

  @override
  HTConstantValue? visitFieldTypeExpr(FieldTypeExpr node) => null;

  @override
  HTConstantValue? visitStructuralTypeExpr(StructuralTypeExpr node) => null;

  @override
  HTConstantValue? visitGenericTypeParamExpr(GenericTypeParameterExpr node) =>
      null;

  /// -e, !e，++e, --e
  @override
  HTConstantValue? visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    if (node.value is BooleanLiteralExpr && node.op == HTLexicon.logicalNot) {
      return HTConstantValue(
          HTConstantType.boolean, !(node.value as BooleanLiteralExpr).value);
    } else if (node.value is BooleanLiteralExpr) {
    } else {
      return null;
    }
  }

  @override
  HTConstantValue? visitUnaryPostfixExpr(UnaryPostfixExpr node) => null;

  @override
  HTConstantValue? visitBinaryExpr(BinaryExpr node) => null;

  @override
  HTConstantValue? visitTernaryExpr(TernaryExpr node) => null;

  @override
  HTConstantValue? visitMemberExpr(MemberExpr node) => null;

  @override
  HTConstantValue? visitMemberAssignExpr(MemberAssignExpr node) => null;

  @override
  HTConstantValue? visitSubExpr(SubExpr node) => null;

  @override
  HTConstantValue? visitSubAssignExpr(SubAssignExpr node) => null;

  @override
  HTConstantValue? visitCallExpr(CallExpr node) => null;

  @override
  HTConstantValue? visitAssertStmt(AssertStmt node) => null;

  @override
  HTConstantValue? visitThrowStmt(ThrowStmt node) => null;

  @override
  HTConstantValue? visitExprStmt(ExprStmt node) => null;

  @override
  HTConstantValue? visitBlockStmt(BlockStmt node) => null;

  @override
  HTConstantValue? visitReturnStmt(ReturnStmt node) => null;

  @override
  HTConstantValue? visitIf(IfStmt node) => null;

  @override
  HTConstantValue? visitWhileStmt(WhileStmt node) => null;

  @override
  HTConstantValue? visitDoStmt(DoStmt node) => null;

  @override
  HTConstantValue? visitForStmt(ForStmt node) => null;

  @override
  HTConstantValue? visitForRangeStmt(ForRangeStmt node) => null;

  @override
  HTConstantValue? visitWhen(WhenStmt node) => null;

  @override
  HTConstantValue? visitBreakStmt(BreakStmt node) => null;

  @override
  HTConstantValue? visitContinueStmt(ContinueStmt node) => null;

  @override
  HTConstantValue? visitDeleteStmt(DeleteStmt node) => null;

  @override
  HTConstantValue? visitDeleteMemberStmt(DeleteMemberStmt node) => null;

  @override
  HTConstantValue? visitDeleteSubStmt(DeleteSubStmt node) => null;

  @override
  HTConstantValue? visitImportExportDecl(ImportExportDecl node) => null;

  @override
  HTConstantValue? visitNamespaceDecl(NamespaceDecl node) => null;

  @override
  HTConstantValue? visitTypeAliasDecl(TypeAliasDecl node) => null;

  @override
  HTConstantValue? visitConstDecl(ConstDecl node) => null;

  @override
  HTConstantValue? visitVarDecl(VarDecl node) => null;

  @override
  HTConstantValue? visitDestructuringDecl(DestructuringDecl node) => null;

  @override
  HTConstantValue? visitParamDecl(ParamDecl node) => null;

  @override
  HTConstantValue? visitReferConstructCallExpr(
          RedirectingConstructorCallExpr node) =>
      null;

  @override
  HTConstantValue? visitFuncDecl(FuncDecl node) => null;

  @override
  HTConstantValue? visitClassDecl(ClassDecl node) => null;

  @override
  HTConstantValue? visitEnumDecl(EnumDecl node) => null;

  @override
  HTConstantValue? visitStructDecl(StructDecl node) => null;

  @override
  HTConstantValue? visitStructObjExpr(StructObjExpr node) => null;

  @override
  HTConstantValue? visitStructObjField(StructObjField node) => null;
}
