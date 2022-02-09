import '../ast/ast.dart';
import '../grammar/lexicon.dart';
import 'global_constant_table.dart';

/// A interpreter that computes the constant value before compilation.
/// If the AstNode provided is non-constant value, return null.
class HTConstantInterpreter implements AbstractAstVisitor<dynamic> {
  HTGlobalConstantTable compute(AstCompilationUnit parseResult) {
    final result = HTGlobalConstantTable();

    return result;
  }

  dynamic evalAstNode(AstNode node) => node.accept(this);

  @override
  dynamic visitCompilation(AstCompilation node) => null;

  @override
  dynamic visitCompilationUnit(AstCompilationUnit node) => null;

  @override
  dynamic visitEmptyExpr(EmptyExpr node) => null;

  @override
  dynamic visitNullExpr(NullExpr node) => null;

  @override
  dynamic visitBooleanExpr(BooleanLiteralExpr node) => node.value;

  @override
  dynamic visitIntLiteralExpr(IntegerLiteralExpr node) => node.value;

  @override
  dynamic visitFloatLiteralExpr(FloatLiteralExpr node) => node.value;

  @override
  dynamic visitStringLiteralExpr(StringLiteralExpr node) => node.value;

  @override
  dynamic visitStringInterpolationExpr(StringInterpolationExpr node) => null;

  @override
  dynamic visitIdentifierExpr(IdentifierExpr node) => null;

  @override
  dynamic visitSpreadExpr(SpreadExpr node) => null;

  @override
  dynamic visitCommaExpr(CommaExpr node) => null;

  @override
  dynamic visitListExpr(ListExpr node) => null;

  @override
  dynamic visitInOfExpr(InOfExpr node) => null;

  @override
  dynamic visitGroupExpr(GroupExpr node) => null;

  @override
  dynamic visitTypeExpr(TypeExpr node) => null;

  @override
  dynamic visitParamTypeExpr(ParamTypeExpr node) => null;

  @override
  dynamic visitFunctionTypeExpr(FuncTypeExpr node) => null;

  @override
  dynamic visitFieldTypeExpr(FieldTypeExpr node) => null;

  @override
  dynamic visitStructuralTypeExpr(StructuralTypeExpr node) => null;

  @override
  dynamic visitGenericTypeParamExpr(GenericTypeParameterExpr node) => null;

  /// -e, !e，++e, --e
  @override
  dynamic visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    if (node.op == HTLexicon.logicalNot && node.value is BooleanLiteralExpr) {
      return !(node.value as BooleanLiteralExpr).value;
    }
    return null;
  }

  @override
  dynamic visitUnaryPostfixExpr(UnaryPostfixExpr node) => null;

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||, e1 ?? e2,  =,
  @override
  dynamic visitBinaryExpr(BinaryExpr node) {
    final left = evalAstNode(node.left);
    final right = evalAstNode(node.right);
    switch (node.op) {
      case HTLexicon.multiply:
        if (left is num && right is num) {
          return left * right;
        }
        break;
    }
    return null;
  }

  /// e1 ? e2 : e3
  @override
  dynamic visitTernaryExpr(TernaryExpr node) => null;

  @override
  dynamic visitMemberExpr(MemberExpr node) => null;

  @override
  dynamic visitMemberAssignExpr(MemberAssignExpr node) => null;

  @override
  dynamic visitSubExpr(SubExpr node) => null;

  @override
  dynamic visitSubAssignExpr(SubAssignExpr node) => null;

  @override
  dynamic visitCallExpr(CallExpr node) => null;

  @override
  dynamic visitAssertStmt(AssertStmt node) => null;

  @override
  dynamic visitThrowStmt(ThrowStmt node) => null;

  @override
  dynamic visitExprStmt(ExprStmt node) => null;

  @override
  dynamic visitBlockStmt(BlockStmt node) => null;

  @override
  dynamic visitReturnStmt(ReturnStmt node) => null;

  @override
  dynamic visitIf(IfStmt node) => null;

  @override
  dynamic visitWhileStmt(WhileStmt node) => null;

  @override
  dynamic visitDoStmt(DoStmt node) => null;

  @override
  dynamic visitForStmt(ForStmt node) => null;

  @override
  dynamic visitForRangeStmt(ForRangeStmt node) => null;

  @override
  dynamic visitWhen(WhenStmt node) => null;

  @override
  dynamic visitBreakStmt(BreakStmt node) => null;

  @override
  dynamic visitContinueStmt(ContinueStmt node) => null;

  @override
  dynamic visitDeleteStmt(DeleteStmt node) => null;

  @override
  dynamic visitDeleteMemberStmt(DeleteMemberStmt node) => null;

  @override
  dynamic visitDeleteSubStmt(DeleteSubStmt node) => null;

  @override
  dynamic visitImportExportDecl(ImportExportDecl node) => null;

  @override
  dynamic visitNamespaceDecl(NamespaceDecl node) => null;

  @override
  dynamic visitTypeAliasDecl(TypeAliasDecl node) => null;

  // @override
  // dynamic visitConstDecl(ConstDecl node) => null;

  @override
  dynamic visitVarDecl(VarDecl node) => null;

  @override
  dynamic visitDestructuringDecl(DestructuringDecl node) => null;

  @override
  dynamic visitParamDecl(ParamDecl node) => null;

  @override
  dynamic visitReferConstructCallExpr(RedirectingConstructorCallExpr node) =>
      null;

  @override
  dynamic visitFuncDecl(FuncDecl node) => null;

  @override
  dynamic visitClassDecl(ClassDecl node) => null;

  @override
  dynamic visitEnumDecl(EnumDecl node) => null;

  @override
  dynamic visitStructDecl(StructDecl node) => null;

  @override
  dynamic visitStructObjExpr(StructObjExpr node) => null;

  @override
  dynamic visitStructObjField(StructObjField node) => null;
}
