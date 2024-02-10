// import '../type/nominal_type.dart';
import '../ast/ast.dart';
// import '../grammar/lexicon.dart';
// import '../shared/stringify.dart';
import '../type/type.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../type/nominal.dart';

/// A interpreter that compute [HTType] out of [ASTNode]
class HTTypeChecker implements AbstractASTVisitor<HTType> {
  final HTLexicon _lexicon;

  HTTypeChecker({HTLexicon? lexicon}) : _lexicon = lexicon ?? HTLexiconHetu();

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
  HTType visitComment(ASTComment node) {
    throw 'Not a value';
  }

  @override
  HTType visitEmptyLine(ASTEmptyLine node) {
    throw 'Not a value';
  }

  @override
  HTType visitEmptyExpr(ASTEmpty node) {
    throw 'Not a value';
  }

  @override
  HTType visitNullExpr(ASTLiteralNull node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitBooleanExpr(ASTLiteralBoolean node) {
    return HTNominalType(id: 'bool');
  }

  @override
  HTType visitIntLiteralExpr(ASTLiteralInteger node) {
    return HTNominalType(id: 'int');
  }

  @override
  HTType visitFloatLiteralExpr(ASTLiteralFloat node) {
    return HTNominalType(id: 'float');
  }

  @override
  HTType visitStringLiteralExpr(ASTLiteralString node) {
    return HTNominalType(id: 'str');
  }

  @override
  HTType visitStringInterpolationExpr(ASTStringInterpolation node) {
    return HTNominalType(id: 'str');
  }

  @override
  HTType visitIdentifierExpr(IdentifierExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitSpreadExpr(SpreadExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitCommaExpr(CommaExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitListExpr(ListExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitInOfExpr(InOfExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitGroupExpr(GroupExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitIntrinsicTypeExpr(IntrinsicTypeExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitNominalTypeExpr(NominalTypeExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitParamTypeExpr(ParamTypeExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitFunctionTypeExpr(FuncTypeExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitFieldTypeExpr(FieldTypeExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitStructuralTypeExpr(StructuralTypeExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitGenericTypeParamExpr(GenericTypeParameterExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  /// -e, !e，++e, --e
  @override
  HTType visitUnaryPrefixExpr(UnaryPrefixExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitUnaryPostfixExpr(UnaryPostfixExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  /// *, /, ~/, %, +, -, <, >, <=, >=, ==, !=, &&, ||
  @override
  HTType visitBinaryExpr(BinaryExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  /// e1 ? e2 : e3
  @override
  HTType visitTernaryExpr(TernaryExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitAssignExpr(AssignExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitMemberExpr(MemberExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitSubExpr(SubExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitCallExpr(CallExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitAssertStmt(AssertStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitThrowStmt(ThrowStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitExprStmt(ExprStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitBlockStmt(BlockStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitReturnStmt(ReturnStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitIf(IfExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitWhileStmt(WhileStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitDoStmt(DoStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitForStmt(ForExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitForRangeStmt(ForRangeExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitSwitch(SwitchStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitBreakStmt(BreakStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitContinueStmt(ContinueStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitDeleteStmt(DeleteStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitDeleteMemberStmt(DeleteMemberStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitDeleteSubStmt(DeleteSubStmt node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitImportExportDecl(ImportExportDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitNamespaceDecl(NamespaceDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitTypeAliasDecl(TypeAliasDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  // @override
  // HTType visitConstDecl(ConstDecl node) {
  //
  // return HTTypeAny(_lexicon.typeAny);
  // }

  @override
  HTType visitVarDecl(VarDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitDestructuringDecl(DestructuringDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitParamDecl(ParamDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitReferConstructCallExpr(RedirectingConstructorCallExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitFuncDecl(FuncDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitClassDecl(ClassDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitEnumDecl(EnumDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitStructDecl(StructDecl node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitStructObjExpr(StructObjExpr node) {
    return HTTypeAny(_lexicon.kAny);
  }

  @override
  HTType visitStructObjField(StructObjField node) {
    return HTTypeAny(_lexicon.kAny);
  }
}
