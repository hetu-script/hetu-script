import '../grammar/token.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';

part 'abstract_ast_visitor.dart';

abstract class AstNode {
  final HTSource? source;

  final String type;

  final int line;
  final int column;

  /// 取表达式右值，返回值本身
  dynamic accept(AbstractAstVisitor visitor);

  const AstNode(this.type, this.line, this.column, this.source);
}

class CommentExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCommentExpr(this);

  final String content;

  final bool isMultiline;

  const CommentExpr(this.content, this.isMultiline, int line, int column,
      {HTSource? source})
      : super(SemanticNames.comment, line, column, source);
}

class NullExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitNullExpr(this);

  const NullExpr(int line, int column, {HTSource? source})
      : super(SemanticNames.literalNull, line, column, source);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  const BooleanExpr(this.value, int line, int column, {HTSource? source})
      : super(SemanticNames.literalBoolean, line, column, source);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitConstIntExpr(this);

  final int value;

  const ConstIntExpr(this.value, int line, int column, {HTSource? source})
      : super(SemanticNames.literalInteger, line, column, source);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstFloatExpr(this);

  final double value;

  const ConstFloatExpr(this.value, int line, int column, {HTSource? source})
      : super(SemanticNames.literalFloat, line, column, source);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstStringExpr(this);

  final String value;

  final String quotationLeft;

  final String quotationRight;

  const ConstStringExpr(
      this.value, this.quotationLeft, this.quotationRight, int line, int column,
      {HTSource? source})
      : super(SemanticNames.literalString, line, column, source);

  ConstStringExpr.fromToken(TokenStringLiteral token, {HTSource? source})
      : this(token.literal, token.quotationLeft, token.quotationRight,
            token.line, token.column,
            source: source);
}

class StringInterpolationExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitStringInterpolationExpr(this);

  final String value;

  final String quotationLeft;

  final String quotationRight;

  final List<AstNode> interpolation;

  const StringInterpolationExpr(this.value, this.quotationLeft,
      this.quotationRight, this.interpolation, int line, int column,
      {HTSource? source})
      : super(SemanticNames.stringInterpolation, line, column, source);
}

class ListExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitListExpr(this);

  final List<AstNode> list;

  const ListExpr(this.list, int line, int column, {HTSource? source})
      : super(SemanticNames.literalVectorExpr, line, column, source);
}

class MapExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitMapExpr(this);

  final Map<AstNode, AstNode> map;

  const MapExpr(int line, int column, {HTSource? source, this.map = const {}})
      : super(SemanticNames.blockExpr, line, column, source);
}

class GroupExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitGroupExpr(this);

  final AstNode inner;

  const GroupExpr(this.inner, int line, int column, {HTSource? source})
      : super(SemanticNames.groupExpr, line, column, source);
}

class UnaryPrefixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPrefixExpr(this);

  final String op;

  final AstNode value;

  const UnaryPrefixExpr(this.op, this.value, int line, int column,
      {HTSource? source})
      : super(SemanticNames.unaryExpr, line, column, source);
}

class BinaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBinaryExpr(this);

  final AstNode left;

  final String op;

  final AstNode right;

  const BinaryExpr(this.left, this.op, this.right, int line, int column,
      {HTSource? source})
      : super(SemanticNames.binaryExpr, line, column, source);
}

class TernaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTernaryExpr(this);

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode elseBranch;

  const TernaryExpr(
      this.condition, this.thenBranch, this.elseBranch, int line, int column,
      {HTSource? source})
      : super(SemanticNames.binaryExpr, line, column, source);
}

class TypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTypeExpr(this);

  final String id;

  final List<TypeExpr> arguments;

  final bool isNullable;

  final bool isLocal;

  const TypeExpr(this.id, int line, int column,
      {HTSource? source,
      this.arguments = const [],
      this.isNullable = false,
      this.isLocal = false})
      : super(SemanticNames.typeExpr, line, column, source);
}

class ParamTypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitParamTypeExpr(this);

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  /// Wether this is a named parameter.
  final String? id;

  final TypeExpr declType;

  const ParamTypeExpr(this.declType, int line, int column,
      {HTSource? source,
      this.id,
      this.isOptional = false,
      this.isVariadic = false})
      : super(SemanticNames.paramTypeExpr, line, column, source);
}

class FuncTypeExpr extends TypeExpr {
  final TypeExpr returnType;

  // final List<TypeExpr> genericParameters;

  final List<ParamTypeExpr> paramTypes;

  final bool hasOptionalParam;

  final bool hasNamedParam;

  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitFunctionTypeExpr(this);

  const FuncTypeExpr(this.returnType, int line, int column,
      {HTSource? source,
      this.paramTypes = const [],
      // this.genericParameters = const[],
      this.hasOptionalParam = false,
      this.hasNamedParam = false})
      : super(SemanticNames.funcTypeExpr, line, column, source: source);
}

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSymbolExpr(this);

  final String id;

  final bool isLocal;

  final List<TypeExpr> typeArgs;

  const SymbolExpr(this.id, int line, int column,
      {HTSource? source, this.isLocal = true, this.typeArgs = const []})
      : super(SemanticNames.symbolExpr, line, column, source);
}

// class AssignExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitAssignExpr(this);

//   final String id;

//   final String op;

//   final AstNode value;

//   const AssignExpr(this.id, this.op, this.value, int line, int column, {HTSource? source})
//       : super(SemanticType.assignExpr, line, column, source);
// }

class MemberExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitMemberExpr(this);

  final AstNode object;

  final SymbolExpr key;

  const MemberExpr(this.object, this.key, int line, int column,
      {HTSource? source})
      : super(SemanticNames.memberGetExpr, line, column, source);
}

class MemberAssignExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitMemberAssignExpr(this);

  final AstNode object;

  final SymbolExpr key;

  final AstNode value;

  const MemberAssignExpr(
      this.object, this.key, this.value, int line, int column,
      {HTSource? source})
      : super(SemanticNames.memberSetExpr, line, column, source);
}

// class MemberCallExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) =>
//       visitor.visitMemberCallExpr(this);

//   final AstNode collection;

//   final String key;

//   const MemberCallExpr(this.collection, this.key, int line, int column, {HTSource? source})
//       : super(SemanticType.memberGetExpr, line, column, source);
// }

class SubExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubExpr(this);

  final AstNode array;

  final AstNode key;

  const SubExpr(this.array, this.key, int line, int column, {HTSource? source})
      : super(SemanticNames.subGetExpr, line, column, source);
}

class SubAssignExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitSubAssignExpr(this);

  final AstNode array;

  final AstNode key;

  final AstNode value;

  const SubAssignExpr(this.array, this.key, this.value, int line, int column,
      {HTSource? source})
      : super(SemanticNames.subSetExpr, line, column, source);
}

// class SubCallExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubCallExpr(this);

//   final AstNode collection;

//   final AstNode key;

//   const SubCallExpr(this.collection, this.key, int line, int column, {HTSource? source})
//       : super(SemanticType.subGetExpr, line, column, source);
// }

class CallExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCallExpr(this);

  final AstNode callee;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  const CallExpr(
      this.callee, this.positionalArgs, this.namedArgs, int line, int column,
      {HTSource? source})
      : super(SemanticNames.callExpr, line, column, source);
}

class UnaryPostfixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPostfixExpr(this);

  final AstNode value;

  final String op;

  const UnaryPostfixExpr(this.value, this.op, int line, int column,
      {HTSource? source})
      : super(SemanticNames.unaryExpr, line, column, source);
}

class LibraryStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitLibraryStmt(this);

  const LibraryStmt(int line, int column, {HTSource? source})
      : super(SemanticNames.libraryStmt, line, column, source);
}

class ImportStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitImportStmt(this);

  final String key;

  final String? alias;

  final List<String> showList;

  const ImportStmt(this.key, int line, int column,
      {HTSource? source, this.alias, this.showList = const []})
      : super(SemanticNames.importStmt, line, column, source);
}

class ExprStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode? expr;

  const ExprStmt(this.expr, int line, int column, {HTSource? source})
      : super(SemanticNames.exprStmt, line, column, source);
}

class BlockStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBlockStmt(this);

  final List<AstNode> statements;

  final bool hasOwnNamespace;

  final String? id;

  const BlockStmt(this.statements, int line, int column,
      {HTSource? source, this.hasOwnNamespace = true, this.id})
      : super(SemanticNames.blockStmt, line, column, source);
}

class ReturnStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final AstNode? value;

  const ReturnStmt(this.keyword, this.value, int line, int column,
      {HTSource? source})
      : super(SemanticNames.returnStmt, line, column, source);
}

class IfStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitIfStmt(this);

  final AstNode condition;

  final BlockStmt thenBranch;

  final BlockStmt? elseBranch;

  const IfStmt(
      this.condition, this.thenBranch, this.elseBranch, int line, int column,
      {HTSource? source})
      : super(SemanticNames.ifStmt, line, column, source);
}

class WhileStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhileStmt(this);

  final AstNode condition;

  final BlockStmt loop;

  const WhileStmt(this.condition, this.loop, int line, int column,
      {HTSource? source})
      : super(SemanticNames.whileStmt, line, column, source);
}

class DoStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitDoStmt(this);

  final BlockStmt loop;

  final AstNode? condition;

  const DoStmt(this.loop, this.condition, int line, int column,
      {HTSource? source})
      : super(SemanticNames.doStmt, line, column, source);
}

class ForStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForStmt(this);

  final VarDeclStmt? declaration;

  final AstNode? condition;

  final AstNode? increment;

  final bool hasBracket;

  final BlockStmt loop;

  const ForStmt(this.declaration, this.condition, this.increment, this.loop,
      int line, int column,
      {this.hasBracket = false, HTSource? source})
      : super(SemanticNames.forStmt, line, column, source);
}

class ForInStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForInStmt(this);

  final VarDeclStmt declaration;

  final AstNode collection;

  final bool hasBracket;

  final BlockStmt loop;

  const ForInStmt(
      this.declaration, this.collection, this.loop, int line, int column,
      {this.hasBracket = false, HTSource? source})
      : super(SemanticNames.forInStmt, line, column, source);
}

class WhenStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhenStmt(this);

  final AstNode? condition;

  final Map<AstNode, AstNode> cases;

  final BlockStmt? elseBranch;

  const WhenStmt(
      this.cases, this.elseBranch, this.condition, int line, int column,
      {HTSource? source})
      : super(SemanticNames.whenStmt, line, column, source);
}

class BreakStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  const BreakStmt(this.keyword, int line, int column, {HTSource? source})
      : super(SemanticNames.breakStmt, line, column, source);
}

class ContinueStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  const ContinueStmt(this.keyword, int line, int column, {HTSource? source})
      : super(SemanticNames.continueStmt, line, column, source);
}

class VarDeclStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitVarDeclStmt(this);

  final String id;

  final String? classId;

  final TypeExpr? declType;

  final AstNode? initializer;

  final bool typeInferrence;

  bool get isMember => classId != null;

  bool get isPrivate => id.startsWith(HTLexicon.privatePrefix);

  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isConst;

  final bool isExported;

  final bool isTopLevel;

  final bool lateInitialize;

  const VarDeclStmt(this.id, int line, int column,
      {HTSource? source,
      this.classId,
      this.declType,
      this.initializer,
      this.typeInferrence = false,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isMutable = false,
      this.isExported = false,
      this.isTopLevel = false,
      this.lateInitialize = false})
      : super(SemanticNames.variableDeclaration, line, column, source);
}

class ParamDeclExpr extends VarDeclStmt {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitParamDeclStmt(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  const ParamDeclExpr(String id, int line, int column,
      {HTSource? source,
      TypeExpr? declType,
      AstNode? initializer,
      bool isConst = false,
      bool isMutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false})
      : super(id, line, column,
            source: source,
            declType: declType,
            initializer: initializer,
            isConst: isConst,
            isMutable: isMutable);
}

class ReferConstructorExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitReferConstructorExpr(this);

  final bool isSuper;

  final String? key;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  const ReferConstructorExpr(this.isSuper, this.key, this.positionalArgs,
      this.namedArgs, int line, int column,
      {HTSource? source})
      : super(SemanticNames.referConstructorExpression, line, column, source);
}

class FuncDeclExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final String internalName;

  final String? id;

  final String? classId;

  final List<TypeExpr> genericParameters;

  final String? externalTypeId;

  final TypeExpr? returnType;

  final ReferConstructorExpr? referConstructor;

  final bool hasParamDecls;

  final List<ParamDeclExpr> params;

  final int minArity;

  final int maxArity;

  final AstNode? definition;

  bool get isMember => classId != null;

  bool get isPrivate => internalName.startsWith(HTLexicon.privatePrefix);

  bool get isAbstract => definition != null;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final bool isExported;

  final bool isTopLevel;

  final FunctionCategory category;

  bool get isLiteral => category == FunctionCategory.literal;

  const FuncDeclExpr(this.internalName, this.params, int line, int column,
      {this.id,
      HTSource? source,
      this.classId,
      this.genericParameters = const [],
      this.externalTypeId,
      this.returnType,
      this.referConstructor,
      this.hasParamDecls = true,
      this.minArity = 0,
      this.maxArity = 0,
      this.definition,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.isExported = false,
      this.isTopLevel = false,
      this.category = FunctionCategory.normal})
      : super(SemanticNames.functionDeclaration, line, column, source);
}

class ClassDeclStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitClassDeclStmt(this);

  final String id;

  final String? classId;

  final List<TypeExpr> genericParameters;

  final TypeExpr? superType;

  bool get isMember => classId != null;

  bool get isPrivate => id.startsWith(HTLexicon.privatePrefix);

  final bool isNested;

  final bool isExternal;

  final bool isAbstract;

  final bool isExported;

  final bool isTopLevel;

  final BlockStmt? definition;

  const ClassDeclStmt(this.id, int line, int column,
      {HTSource? source,
      this.classId,
      this.genericParameters = const [],
      this.superType,
      this.isNested = false,
      this.isExternal = false,
      this.isAbstract = false,
      this.isExported = true,
      this.isTopLevel = false,
      this.definition})
      : super(SemanticNames.classDeclaration, line, column, source);
}

class EnumDeclStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEnumDeclStmt(this);

  final String id;

  final String? classId;

  final List<String> enumerations;

  bool get isMember => classId != null;

  bool get isPrivate => id.startsWith(HTLexicon.privatePrefix);

  final bool isExternal;

  final bool isExported;

  final bool isTopLevel;

  const EnumDeclStmt(
    this.id,
    this.enumerations,
    int line,
    int column, {
    HTSource? source,
    this.classId,
    this.isExternal = false,
    this.isExported = true,
    this.isTopLevel = false,
  }) : super(SemanticNames.enumDeclaration, line, column, source);
}

class TypeAliasDeclStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitTypeAliasStmt(this);

  final String id;

  final String? classId;

  final List<TypeExpr> genericParameters;

  final TypeExpr value;

  bool get isMember => classId != null;

  bool get isPrivate => id.startsWith(HTLexicon.privatePrefix);

  final bool isExported;

  final bool isTopLevel;

  const TypeAliasDeclStmt(this.id, this.value, int line, int column,
      {HTSource? source,
      this.classId,
      this.genericParameters = const [],
      this.isExported = false,
      this.isTopLevel = false})
      : super(SemanticNames.typeAliasDeclaration, line, column, source);
}
