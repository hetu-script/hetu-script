import '../../core/token.dart';
import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';

part 'abstract_ast_visitor.dart';

abstract class AstNode {
  final String type;

  final int line;
  final int column;

  final AstNode? previous;
  late final AstNode? next;

  /// 取表达式右值，返回值本身
  dynamic accept(AbstractAstVisitor visitor);

  AstNode(this.type, this.line, this.column, {this.previous});
}

class CommentExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCommentExpr(this);

  final String content;

  CommentExpr(this.content, int line, int column)
      : super(SemanticType.literalNull, line, column);
}

class BlockCommentStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitBlockCommentStmt(this);

  final String content;

  BlockCommentStmt(this.content, int line, int column)
      : super(SemanticType.literalNull, line, column);
}

class NullExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr(int line, int column)
      : super(SemanticType.literalNull, line, column);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  BooleanExpr(this.value, int line, int column)
      : super(SemanticType.literalBoolean, line, column);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitConstIntExpr(this);

  final int constIndex;

  ConstIntExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalInteger, line, column);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstFloatExpr(this);

  final int constIndex;

  ConstFloatExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalFloat, line, column);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstStringExpr(this);

  final int constIndex;

  ConstStringExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalString, line, column);
}

class LiteralListExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitLiteralListExpr(this);

  final List<AstNode> list;

  LiteralListExpr(int line, int column, {this.list = const []})
      : super(SemanticType.literalVectorExpr, line, column);
}

class LiteralMapExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitLiteralMapExpr(this);

  final Map<AstNode, AstNode> map;

  LiteralMapExpr(int line, int column, {this.map = const {}})
      : super(SemanticType.blockExpr, line, column);
}

class GroupExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitGroupExpr(this);

  final AstNode inner;

  GroupExpr(this.inner)
      : super(SemanticType.groupExpr, inner.line, inner.column);
}

class UnaryPrefixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPrefixExpr(this);

  final Token op;

  final AstNode value;

  UnaryPrefixExpr(this.op, this.value)
      : super(SemanticType.unaryExpr, op.line, op.column);
}

class BinaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBinaryExpr(this);

  final AstNode left;

  final String op;

  final AstNode right;

  BinaryExpr(this.left, this.op, this.right)
      : super(SemanticType.binaryExpr, left.line, left.column);
}

class TernaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTernaryExpr(this);

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode elseBranch;

  TernaryExpr(this.condition, this.thenBranch, this.elseBranch)
      : super(SemanticType.binaryExpr, condition.line, condition.column);
}

class TypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTypeExpr(this);

  final String id;

  final List<TypeExpr> arguments;

  final bool isNullable;

  TypeExpr(this.id, int line, int column,
      {this.arguments = const [], this.isNullable = false})
      : super(SemanticType.typeExpr, line, column);
}

class ParamType {
  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  /// Wether this is a named parameter.
  final String? id;

  final TypeExpr? paramType;

  ParamType(
      {this.isOptional = false,
      this.isVariadic = false,
      this.id,
      this.paramType});
}

class FunctionTypeExpr extends TypeExpr {
  final List<TypeExpr> genericTypeParameters;
  final List<ParamType> paramTypes;
  final TypeExpr returnType;

  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitFunctionTypeExpr(this);

  FunctionTypeExpr(this.returnType, int line, int column,
      {this.genericTypeParameters = const [], this.paramTypes = const []})
      : super(HTLexicon.function, line, column);
}

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSymbolExpr(this);

  final String id;

  SymbolExpr(this.id, int line, int column)
      : super(SemanticType.symbolExpr, line, column);
}

class MemberGetExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitMemberGetExpr(this);

  /// 集合
  final AstNode collection;

  /// 属性
  final String key;

  MemberGetExpr(this.collection, this.key)
      : super(SemanticType.memberGetExpr, collection.line, collection.column);
}

class SubGetExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final AstNode collection;

  /// 索引
  final AstNode key;

  SubGetExpr(this.collection, this.key)
      : super(SemanticType.subGetExpr, collection.line, collection.column);
}

class CallExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCallExpr(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode callee;

  /// 函数声明的参数是parameter，调用时传入的变量叫argument
  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  CallExpr(this.callee, this.positionalArgs, this.namedArgs)
      : super(SemanticType.callExpr, callee.line, callee.column);
}

class UnaryPostfixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPostfixExpr(this);

  final AstNode value;

  final Token op;

  UnaryPostfixExpr(this.value, this.op)
      : super(SemanticType.unaryExpr, op.line, op.column);
}

class ImportStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitImportStmt(this);

  final String key;

  final String? alias;

  final List<String>? showList;

  ImportStmt(this.key, this.alias, this.showList, line, column)
      : super(SemanticType.importStmt, line, column);
}

class ExprStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode? expr;

  ExprStmt(this.expr, int line, int column)
      : super(SemanticType.exprStmt, line, column);
}

class BlockStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBlockStmt(this);

  final Iterable<AstNode> statements;

  BlockStmt(this.statements, int line, int column)
      : super(SemanticType.blockStmt, line, column);
}

class ReturnStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final AstNode? value;

  ReturnStmt(this.keyword, this.value)
      : super(SemanticType.returnStmt, keyword.line, keyword.column);
}

class IfStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitIfStmt(this);

  final AstNode condition;

  final BlockStmt thenBranch;

  final AstNode? elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch)
      : super(SemanticType.ifStmt, condition.line, condition.column);
}

class WhileStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhileStmt(this);

  final BlockStmt loop;

  final AstNode? condition;

  WhileStmt(this.condition, this.loop)
      : super(SemanticType.whileStmt, loop.line, loop.column);
}

class DoStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitDoStmt(this);

  final BlockStmt loop;

  final AstNode? condition;

  DoStmt(this.loop, this.condition)
      : super(SemanticType.doStmt, loop.line, loop.column);
}

class ForStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForStmt(this);

  final BlockStmt loop;

  final AstNode? declaration;

  final AstNode? condition;

  final AstNode? increment;

  ForStmt(this.loop, this.declaration, this.condition, this.increment)
      : super(SemanticType.forStmt, loop.line, loop.column);
}

class ForInStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForInStmt(this);

  final AstNode declaration;

  final AstNode collection;

  final BlockStmt loop;

  ForInStmt(this.declaration, this.collection, this.loop)
      : super(SemanticType.forInStmt, loop.line, loop.column);
}

class WhenStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhenStmt(this);

  final Map<AstNode, AstNode> options;

  final BlockStmt? elseBranch;

  final AstNode? condition;

  WhenStmt(this.options, this.elseBranch, this.condition, int line, int column)
      : super(SemanticType.whenStmt, line, column);
}

class BreakStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  BreakStmt(this.keyword)
      : super(SemanticType.breakStmt, keyword.line, keyword.column);
}

class ContinueStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  ContinueStmt(this.keyword)
      : super(SemanticType.continueStmt, keyword.line, keyword.column);
}

class VarDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitVarDeclStmt(this);

  final String id;

  final TypeExpr? declType;

  final AstNode? initializer;

  final bool typeInferrence;

  // 仅用于整个class都为external的情况
  final bool isExternal;

  final bool isImmutable;

  final bool isStatic;

  final bool lateInitialize;

  VarDecl(this.id, int line, int column,
      {this.declType,
      this.initializer,
      this.typeInferrence = false,
      this.isExternal = false,
      this.isImmutable = false,
      this.isStatic = false,
      this.lateInitialize = false})
      : super(SemanticType.varDecl, line, column);
}

class ParamDecl extends VarDecl {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitParamDeclStmt(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  ParamDecl(String id, int line, int column,
      {TypeExpr? declType,
      AstNode? initializer,
      bool isImmutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false})
      : super(id, line, column,
            declType: declType,
            initializer: initializer,
            isImmutable: isImmutable);
}

class ReferConstructorExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitReferConstructorExpr(this);

  final bool isSuper;

  final String? name;

  ReferConstructorExpr(this.isSuper, int line, int column, {this.name})
      : super(SemanticType.referCtorExpr, line, column);
}

class FuncDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final String id;

  final String declId;

  final Iterable<TypeExpr> typeParameters;

  final String? externalTypedef;

  final TypeExpr? returnType;

  final CallExpr? referCtor;

  final String? classId;

  final List<ParamDecl> params;

  final int minArity;

  final int maxArity;

  final BlockStmt? definition;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final FunctionCategory category;

  bool get isLiteral => category == FunctionCategory.literal;

  FuncDecl(this.id, this.declId, this.params, int line, int column,
      {this.classId,
      this.typeParameters = const [],
      this.externalTypedef,
      this.returnType,
      this.referCtor,
      this.minArity = 0,
      this.maxArity = 0,
      this.definition,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.category = FunctionCategory.normal})
      : super(SemanticType.funcDecl, line, column);
}

class ClassDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitClassDeclStmt(this);

  final String id;

  final Iterable<TypeExpr> typeParameters;

  final TypeExpr? superClassType;

  final bool isExternal;

  final bool isAbstract;

  final BlockStmt definition;

  ClassDecl(this.id, this.definition, int line, int column,
      {this.typeParameters = const [],
      this.superClassType,
      this.isExternal = false,
      this.isAbstract = false})
      : super(SemanticType.classDecl, line, column);
}

class EnumDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEnumDeclStmt(this);

  final String id;

  final List<String> enumerations;

  final bool isExternal;

  EnumDecl(this.id, this.enumerations, int line, int column,
      {this.isExternal = false})
      : super(SemanticType.enumDecl, line, column);
}
