import '../type/unresolved.dart';
// import '../type/nominal_type.dart';
import '../ast/ast.dart';
// import '../grammar/lexicon.dart';
// import '../shared/stringify.dart';
import '../type/type.dart';
import '../lexer/lexicon.dart';
import '../lexer/lexicon_default_impl.dart';

/// A interpreter that compute [HTType] out of [ASTNode]
class HTTypeChecker implements AbstractASTVisitor<HTType> {
  final HTLexicon _lexicon;

  HTTypeChecker({HTLexicon? lexicon})
      : _lexicon = lexicon ?? HTDefaultLexicon();

  HTType evalAstNode(ASTNode node) => node.accept(this);

  @override
  HTType visitCompilation(ASTCompilation node) {
    throw 'Don\'t use this on AstCompilation.';
  }

  @override
  HTType visitSource(ASTSource node) {
    throw 'Don\'t use this on AstSource.';
  }

  @override
  HTType visitEmptyExpr(ASTEmptyLine node) {
    throw 'Not a value';
  }

  @override
  HTType visitNullExpr(ASTLiteralNull node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitBooleanExpr(ASTLiteralBoolean node) {
    return HTUnresolvedType('bool');
  }

  @override
  HTType visitIntLiteralExpr(ASTLiteralInteger node) {
    return HTUnresolvedType('int');
  }

  @override
  HTType visitFloatLiteralExpr(ASTLiteralFloat node) {
    return HTUnresolvedType('float');
  }

  @override
  HTType visitStringLiteralExpr(ASTLiteralString node) {
    return HTUnresolvedType('str');
  }

  @override
  HTType visitStringInterpolationExpr(ASTStringInterpolation node) {
    return HTUnresolvedType('str');
  }

  @override
  HTType visitIdentifierExpr(IdentifierExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitSpreadExpr(SpreadExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitCommaExpr(CommaExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitListExpr(ListExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitInOfExpr(InOfExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitGroupExpr(GroupExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitTypeExpr(TypeExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitParamTypeExpr(ParamTypeExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitFunctionTypeExpr(FuncTypeExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitFieldTypeExpr(FieldTypeExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitStructuralTypeExpr(StructuralTypeExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  /// -e, !e，++e, --e
  @override
  HTType visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||
  @override
  HTType visitBinaryExpr(BinaryExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  /// e1 ? e2 : e3
  @override
  HTType visitTernaryExpr(TernaryExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitAssignExpr(AssignExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitMemberExpr(MemberExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitSubExpr(SubExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitCallExpr(CallExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitAssertStmt(AssertStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitThrowStmt(ThrowStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitExprStmt(ExprStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitBlockStmt(BlockStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitReturnStmt(ReturnStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitIf(IfStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitWhileStmt(WhileStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitDoStmt(DoStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitForStmt(ForStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitForRangeStmt(ForRangeStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitWhen(WhenStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitBreakStmt(BreakStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitContinueStmt(ContinueStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitDeleteStmt(DeleteStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitDeleteMemberStmt(DeleteMemberStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitDeleteSubStmt(DeleteSubStmt node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitImportExportDecl(ImportExportDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitNamespaceDecl(NamespaceDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitTypeAliasDecl(TypeAliasDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  // @override
  // HTType visitConstDecl(ConstDecl node) {
  //
  // return HTIntrinsicType.any(_lexicon.typeAny);
  // }

  @override
  HTType visitVarDecl(VarDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitDestructuringDecl(DestructuringDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitParamDecl(ParamDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitFuncDecl(FuncDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitClassDecl(ClassDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitEnumDecl(EnumDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitStructDecl(StructDecl node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitStructObjExpr(StructObjExpr node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }

  @override
  HTType visitStructObjField(StructObjField node) {
    return HTIntrinsicType.any(_lexicon.typeAny);
  }
}
