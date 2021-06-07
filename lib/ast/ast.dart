import '../../core/token.dart';
// import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
// import '../source/source.dart' show SourceType;

part 'abstract_ast_visitor.dart';

abstract class AstNode {
  final String type;

  final int line;
  final int column;

  /// 取表达式右值，返回值本身
  dynamic accept(AbstractAstVisitor visitor);

  const AstNode(this.type, this.line, this.column);
}

class CommentExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCommentExpr(this);

  final String content;

  final bool isMultiline;

  const CommentExpr(this.content, this.isMultiline, int line, int column)
      : super(SemanticType.literalNull, line, column);
}

class NullExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitNullExpr(this);

  const NullExpr(int line, int column)
      : super(SemanticType.literalNull, line, column);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  const BooleanExpr(this.value, int line, int column)
      : super(SemanticType.literalBoolean, line, column);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitConstIntExpr(this);

  final int value;

  const ConstIntExpr(this.value, int line, int column)
      : super(SemanticType.literalInteger, line, column);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstFloatExpr(this);

  final double value;

  const ConstFloatExpr(this.value, int line, int column)
      : super(SemanticType.literalFloat, line, column);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstStringExpr(this);

  final String value;

  const ConstStringExpr(this.value, int line, int column)
      : super(SemanticType.literalString, line, column);
}

class LiteralListExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitLiteralListExpr(this);

  final List<AstNode> list;

  const LiteralListExpr(this.list, int line, int column)
      : super(SemanticType.literalVectorExpr, line, column);
}

class LiteralMapExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitLiteralMapExpr(this);

  final Map<AstNode, AstNode> map;

  const LiteralMapExpr(int line, int column, {this.map = const {}})
      : super(SemanticType.blockExpr, line, column);
}

class GroupExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitGroupExpr(this);

  final AstNode inner;

  const GroupExpr(this.inner, int line, int column)
      : super(SemanticType.groupExpr, line, column);
}

class UnaryPrefixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPrefixExpr(this);

  final String op;

  final AstNode value;

  const UnaryPrefixExpr(this.op, this.value, int line, int column)
      : super(SemanticType.unaryExpr, line, column);
}

class BinaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBinaryExpr(this);

  final AstNode left;

  final String op;

  final AstNode right;

  const BinaryExpr(this.left, this.op, this.right, int line, int column)
      : super(SemanticType.binaryExpr, line, column);
}

class TernaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTernaryExpr(this);

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode elseBranch;

  const TernaryExpr(
      this.condition, this.thenBranch, this.elseBranch, int line, int column)
      : super(SemanticType.binaryExpr, line, column);
}

class TypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTypeExpr(this);

  final String id;

  final List<TypeExpr> arguments;

  final bool isNullable;

  final bool isLocal;

  const TypeExpr(this.id, int line, int column,
      {this.arguments = const [],
      this.isNullable = false,
      this.isLocal = false})
      : super(SemanticType.typeExpr, line, column);
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
      {this.id, this.isOptional = false, this.isVariadic = false})
      : super(SemanticType.paramTypeExpr, line, column);
}

class FunctionTypeExpr extends AstNode {
  final TypeExpr returnType;

  // final List<TypeExpr> genericTypeParameters;

  final List<ParamTypeExpr> paramTypes;

  final bool hasOptionalParam;

  final bool hasNamedParam;

  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitFunctionTypeExpr(this);

  const FunctionTypeExpr(this.returnType, int line, int column,
      {this.paramTypes = const [],
      this.hasOptionalParam = false,
      this.hasNamedParam = false})
      : super(SemanticType.funcTypeExpr, line, column);
}

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSymbolExpr(this);

  final String id;

  final bool isLocal;

  final List<TypeExpr> typeArgs;

  const SymbolExpr(this.id, int line, int column,
      {this.isLocal = true, this.typeArgs = const []})
      : super(SemanticType.symbolExpr, line, column);
}

// class AssignExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitAssignExpr(this);

//   final String id;

//   final String op;

//   final AstNode value;

//   const AssignExpr(this.id, this.op, this.value, int line, int column)
//       : super(SemanticType.assignExpr, line, column);
// }

class MemberExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitMemberExpr(this);

  final AstNode object;

  final SymbolExpr key;

  const MemberExpr(this.object, this.key, int line, int column)
      : super(SemanticType.memberGetExpr, line, column);
}

class MemberAssignExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitMemberAssignExpr(this);

  final AstNode object;

  final SymbolExpr key;

  final AstNode value;

  const MemberAssignExpr(
      this.object, this.key, this.value, int line, int column)
      : super(SemanticType.memberSetExpr, line, column);
}

// class MemberCallExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) =>
//       visitor.visitMemberCallExpr(this);

//   final AstNode collection;

//   final String key;

//   const MemberCallExpr(this.collection, this.key, int line, int column)
//       : super(SemanticType.memberGetExpr, line, column);
// }

class SubExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubExpr(this);

  final AstNode array;

  final AstNode key;

  const SubExpr(this.array, this.key, int line, int column)
      : super(SemanticType.subGetExpr, line, column);
}

class SubAssignExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitSubAssignExpr(this);

  final AstNode array;

  final AstNode key;

  final AstNode value;

  const SubAssignExpr(this.array, this.key, this.value, int line, int column)
      : super(SemanticType.subSetExpr, line, column);
}

// class SubCallExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubCallExpr(this);

//   final AstNode collection;

//   final AstNode key;

//   const SubCallExpr(this.collection, this.key, int line, int column)
//       : super(SemanticType.subGetExpr, line, column);
// }

class CallExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCallExpr(this);

  final AstNode callee;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  const CallExpr(
      this.callee, this.positionalArgs, this.namedArgs, int line, int column)
      : super(SemanticType.callExpr, line, column);
}

class UnaryPostfixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPostfixExpr(this);

  final AstNode value;

  final String op;

  const UnaryPostfixExpr(this.value, this.op, int line, int column)
      : super(SemanticType.unaryExpr, line, column);
}

class LibraryStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitLibraryStmt(this);

  const LibraryStmt(int line, int column)
      : super(SemanticType.libraryStmt, line, column);
}

class ImportStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitImportStmt(this);

  final String key;

  final String? alias;

  final List<String>? showList;

  const ImportStmt(this.key, int line, int column, {this.alias, this.showList})
      : super(SemanticType.importStmt, line, column);
}

class ExprStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode? expr;

  const ExprStmt(this.expr, int line, int column)
      : super(SemanticType.exprStmt, line, column);
}

class BlockStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBlockStmt(this);

  final List<AstNode> statements;

  final bool createNamespace;

  final String? id;

  const BlockStmt(this.statements, int line, int column,
      {this.createNamespace = true, this.id})
      : super(SemanticType.blockStmt, line, column);
}

class ReturnStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final AstNode? value;

  const ReturnStmt(this.keyword, this.value, int line, int column)
      : super(SemanticType.returnStmt, line, column);
}

class IfStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitIfStmt(this);

  final AstNode condition;

  final BlockStmt thenBranch;

  final BlockStmt? elseBranch;

  const IfStmt(
      this.condition, this.thenBranch, this.elseBranch, int line, int column)
      : super(SemanticType.ifStmt, line, column);
}

class WhileStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhileStmt(this);

  final AstNode? condition;

  final BlockStmt loop;

  const WhileStmt(this.condition, this.loop, int line, int column)
      : super(SemanticType.whileStmt, line, column);
}

class DoStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitDoStmt(this);

  final BlockStmt loop;

  final AstNode? condition;

  const DoStmt(this.loop, this.condition, int line, int column)
      : super(SemanticType.doStmt, line, column);
}

class ForStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForStmt(this);

  final VarDeclStmt? declaration;

  final AstNode? condition;

  final AstNode? increment;

  final BlockStmt loop;

  const ForStmt(this.declaration, this.condition, this.increment, this.loop,
      int line, int column)
      : super(SemanticType.forStmt, line, column);
}

class ForInStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForInStmt(this);

  final VarDeclStmt declaration;

  final AstNode collection;

  final BlockStmt loop;

  const ForInStmt(
      this.declaration, this.collection, this.loop, int line, int column)
      : super(SemanticType.forInStmt, line, column);
}

class WhenStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhenStmt(this);

  final AstNode? condition;

  final Map<AstNode, AstNode> cases;

  final BlockStmt? elseBranch;

  const WhenStmt(
      this.cases, this.elseBranch, this.condition, int line, int column)
      : super(SemanticType.whenStmt, line, column);
}

class BreakStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  const BreakStmt(this.keyword, int line, int column)
      : super(SemanticType.breakStmt, line, column);
}

class ContinueStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  const ContinueStmt(this.keyword, int line, int column)
      : super(SemanticType.continueStmt, line, column);
}

class VarDeclStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitVarDeclStmt(this);

  final String id;

  final TypeExpr? declType;

  final AstNode? initializer;

  final bool typeInferrence;

  // 仅用于整个class都为external的情况
  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isConst;

  final bool isExported;

  final bool lateInitialize;

  const VarDeclStmt(this.id, int line, int column,
      {this.declType,
      this.initializer,
      this.typeInferrence = false,
      this.isExternal = false,
      this.isStatic = false,
      this.isMutable = false,
      this.isConst = false,
      this.isExported = false,
      this.lateInitialize = false})
      : super(SemanticType.variableDeclaration, line, column);
}

class ParamDeclExpr extends VarDeclStmt {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitParamDeclStmt(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  const ParamDeclExpr(String id, int line, int column,
      {TypeExpr? declType,
      AstNode? initializer,
      bool isMutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false})
      : super(id, line, column,
            declType: declType, initializer: initializer, isMutable: isMutable);
}

class ReferConstructorExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitReferConstructorExpr(this);

  final String callee;

  final String? key;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  const ReferConstructorExpr(this.callee, this.key, this.positionalArgs,
      this.namedArgs, int line, int column)
      : super(SemanticType.referConstructorExpression, line, column);
}

class FuncDeclExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final String id;

  final String declId;

  final Iterable<TypeExpr> typeParameters;

  final String? externalTypeId;

  final TypeExpr? returnType;

  final ReferConstructorExpr? referConstructor;

  final String? classId;

  final bool hasParamDecls;

  final List<ParamDeclExpr> params;

  final int minArity;

  final int maxArity;

  final BlockStmt? definition;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final bool isExported;

  final FunctionCategory category;

  bool get isLiteral => category == FunctionCategory.literal;

  const FuncDeclExpr(this.id, this.declId, this.params, int line, int column,
      {this.classId,
      this.typeParameters = const [],
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
      this.category = FunctionCategory.normal})
      : super(SemanticType.functionDeclaration, line, column);
}

class ClassDeclStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitClassDeclStmt(this);

  final String id;

  final Iterable<TypeExpr> typeParameters;

  final TypeExpr? superType;

  final bool isExternal;

  final bool isAbstract;

  final bool isExported;

  final BlockStmt? definition;

  const ClassDeclStmt(this.id, int line, int column,
      {this.typeParameters = const [],
      this.superType,
      this.isExternal = false,
      this.isAbstract = false,
      this.isExported = true,
      this.definition})
      : super(SemanticType.classDeclaration, line, column);
}

class EnumDeclStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEnumDeclStmt(this);

  final String id;

  final List<String> enumerations;

  final bool isExternal;

  final bool isExported;

  const EnumDeclStmt(this.id, this.enumerations, int line, int column,
      {this.isExternal = false, this.isExported = true})
      : super(SemanticType.enumDecl, line, column);
}
