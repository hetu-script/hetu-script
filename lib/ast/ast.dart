import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';

part 'visitor/abstract_ast_visitor.dart';

abstract class AstNode {
  final String type;

  final HTSource? source;

  final int line;

  final int column;

  final int offset;

  final int length;

  int get end => offset + length;

  dynamic accept(AbstractAstVisitor visitor);

  /// Visit all the sub nodes
  void acceptAll(AbstractAstVisitor visitor) {}

  const AstNode(this.type,
      {this.source,
      this.line = 0,
      this.column = 0,
      this.offset = 0,
      this.length = 0});
}

// Has no meaning, a helper for parser to recover from errors.
class EmptyExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEmptyExpr(this);

  const EmptyExpr(
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.empty,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class CommentExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCommentExpr(this);

  final String content;

  final bool isMultiline;

  const CommentExpr(this.content,
      {this.isMultiline = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.comment,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class NullExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitNullExpr(this);

  const NullExpr(
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.nullLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  const BooleanExpr(this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.booleanLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitConstIntExpr(this);

  final int value;

  const ConstIntExpr(this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.integerLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstFloatExpr(this);

  final double value;

  const ConstFloatExpr(this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.floatLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstStringExpr(this);

  final String value;

  final String quotationLeft;

  final String quotationRight;

  const ConstStringExpr(this.value, this.quotationLeft, this.quotationRight,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.stringLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class StringInterpolationExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitStringInterpolationExpr(this);

  @override
  dynamic acceptAll(AbstractAstVisitor visitor) => null;

  final String value;

  final String quotationLeft;

  final String quotationRight;

  final List<AstNode> interpolation;

  const StringInterpolationExpr(
      this.value, this.quotationLeft, this.quotationRight, this.interpolation,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.stringInterpolation,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSymbolExpr(this);

  final String id;

  final bool isLocal;

  const SymbolExpr(this.id,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.isLocal = true})
      : super(SemanticNames.symbolExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ListExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitListExpr(this);

  @override
  void acceptAll(AbstractAstVisitor visitor) {
    for (final item in list) {
      item.accept(visitor);
    }
  }

  final List<AstNode> list;

  const ListExpr(this.list,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.listLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class MapExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitMapExpr(this);

  @override
  void acceptAll(AbstractAstVisitor visitor) {
    for (final key in map.keys) {
      key.accept(visitor);
      final value = map[key]!;
      value.accept(visitor);
    }
  }

  final Map<AstNode, AstNode> map;

  const MapExpr(this.map,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.mapLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class GroupExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitGroupExpr(this);

  @override
  void acceptAll(AbstractAstVisitor visitor) {
    inner.accept(visitor);
  }

  final AstNode inner;

  const GroupExpr(this.inner,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.groupExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class TypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTypeExpr(this);

  @override
  void acceptAll(AbstractAstVisitor visitor) {
    id.accept(visitor);
    for (final item in arguments) {
      item.accept(visitor);
    }
  }

  final SymbolExpr id;

  final List<TypeExpr> arguments;

  final bool isNullable;

  final bool isLocal;

  const TypeExpr(this.id,
      {this.arguments = const [],
      this.isNullable = false,
      this.isLocal = true,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.typeExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ParamTypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitParamTypeExpr(this);

  @override
  void acceptAll(AbstractAstVisitor visitor) {
    id?.accept(visitor);
    declType.accept(visitor);
  }

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  bool get isNamed => id != null;

  /// Wether this is a named parameter.
  final SymbolExpr? id;

  final TypeExpr declType;

  const ParamTypeExpr(this.declType,
      {this.id,
      required this.isOptional,
      required this.isVariadic,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.paramTypeExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class FuncTypeExpr extends TypeExpr {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitFunctionTypeExpr(this);

  @override
  void acceptAll(AbstractAstVisitor visitor) {
    keyword.accept(visitor);
    for (final item in genericTypeParameters) {
      item.accept(visitor);
    }
    for (final item in paramTypes) {
      item.accept(visitor);
    }
    returnType.accept(visitor);
  }

  final SymbolExpr keyword;

  final List<GenericTypeParamExpr> genericTypeParameters;

  final List<ParamTypeExpr> paramTypes;

  final TypeExpr? returnType;

  final bool hasOptionalParam;

  final bool hasNamedParam;

  const FuncTypeExpr(this.keyword,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      bool isLocal = true,
      this.genericTypeParameters = const [],
      this.paramTypes = const [],
      this.returnType,
      required this.hasOptionalParam,
      required this.hasNamedParam})
      : super(keyword,
            isLocal: isLocal,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class GenericTypeParamExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitGenericTypeParamExpr(this);

  @override
  void acceptAll(AbstractAstVisitor visitor) {
    id.accept(visitor);
    superType?.accept(visitor);
  }

  final SymbolExpr id;

  final TypeExpr? superType;

  const GenericTypeParamExpr(this.id,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.superType})
      : super(SemanticNames.genericTypeParamExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class UnaryPrefixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPrefixExpr(this);

  final String op;

  final AstNode value;

  const UnaryPrefixExpr(this.op, this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.unaryExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class UnaryPostfixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPostfixExpr(this);

  final AstNode value;

  final String op;

  const UnaryPostfixExpr(this.value, this.op,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.unaryExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class BinaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBinaryExpr(this);

  final AstNode left;

  final String op;

  final AstNode right;

  const BinaryExpr(this.left, this.op, this.right,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.binaryExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class TernaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitTernaryExpr(this);

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode elseBranch;

  const TernaryExpr(this.condition, this.thenBranch, this.elseBranch,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.binaryExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

// class AssignExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitAssignExpr(this);

//   final String id;

//   final String op;

//   final AstNode value;

//   const AssignExpr(this.id, this.op, this.value, int line, int column, int offset, int length, {HTSource? source})
//       : super(SemanticType.assignExpr, source: source, line: line, column: column, offset: offset, length: length);
// }

class MemberExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitMemberExpr(this);

  final AstNode object;

  final SymbolExpr key;

  const MemberExpr(this.object, this.key,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.memberGetExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class MemberAssignExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitMemberAssignExpr(this);

  final AstNode object;

  final SymbolExpr key;

  final AstNode value;

  const MemberAssignExpr(this.object, this.key, this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.memberSetExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

// class MemberCallExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) =>
//       visitor.visitMemberCallExpr(this);

//   final AstNode collection;

//   final String key;

//   const MemberCallExpr(this.collection, this.key, int line, int column, int offset, int length, {HTSource? source})
//       : super(SemanticType.memberGetExpr, source: source, line: line, column: column, offset: offset, length: length);
// }

class SubExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubExpr(this);

  final AstNode array;

  final AstNode key;

  const SubExpr(this.array, this.key,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.subGetExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class SubAssignExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitSubAssignExpr(this);

  final AstNode array;

  final AstNode key;

  final AstNode value;

  const SubAssignExpr(this.array, this.key, this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.subSetExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

// class SubCallExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubCallExpr(this);

//   final AstNode collection;

//   final AstNode key;

//   const SubCallExpr(this.collection, this.key, int line, int column, int offset, int length, {HTSource? source})
//       : super(SemanticType.subGetExpr, source: source, line: line, column: column, offset: offset, length: length);
// }

class CallExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCallExpr(this);

  final AstNode callee;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  const CallExpr(this.callee, this.positionalArgs, this.namedArgs,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.callExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ExprStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode expr;

  const ExprStmt(this.expr,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.exprStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class BlockStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBlockStmt(this);

  final List<AstNode> statements;

  final bool hasOwnNamespace;

  final String? id;

  const BlockStmt(this.statements,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.hasOwnNamespace = true,
      this.id})
      : super(SemanticNames.blockStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ReturnStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final AstNode? value;

  const ReturnStmt(this.keyword, this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.returnStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class IfStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitIfStmt(this);

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode? elseBranch;

  const IfStmt(this.condition, this.thenBranch, this.elseBranch,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.ifStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class WhileStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhileStmt(this);

  final AstNode condition;

  final BlockStmt loop;

  const WhileStmt(this.condition, this.loop,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.whileStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class DoStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitDoStmt(this);

  final BlockStmt loop;

  final AstNode? condition;

  const DoStmt(this.loop, this.condition,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.doStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ForStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForStmt(this);

  final VarDecl? declaration;

  final AstNode? condition;

  final AstNode? increment;

  final bool hasBracket;

  final BlockStmt loop;

  const ForStmt(this.declaration, this.condition, this.increment, this.loop,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.hasBracket = false})
      : super(SemanticNames.forStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ForInStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForInStmt(this);

  final VarDecl declaration;

  final AstNode collection;

  final bool hasBracket;

  final BlockStmt loop;

  const ForInStmt(this.declaration, this.collection, this.loop,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.hasBracket = false})
      : super(SemanticNames.forInStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class WhenStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhenStmt(this);

  final AstNode? condition;

  final Map<AstNode, AstNode> cases;

  final AstNode? elseBranch;

  const WhenStmt(this.cases, this.elseBranch, this.condition,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.whenStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class BreakStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  const BreakStmt(this.keyword,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.breakStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ContinueStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  const ContinueStmt(this.keyword,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.continueStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class LibraryDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitLibraryDecl(this);

  final String id;

  const LibraryDecl(this.id,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.libraryStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ImportDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitImportDecl(this);

  final String key;

  final String? alias;

  final List<String> showList;

  String? fullName;

  ImportDecl(this.key,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.alias,
      this.showList = const []})
      : super(SemanticNames.importStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class NamespaceDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitNamespaceDecl(this);

  final String id;

  final String? classId;

  final BlockStmt definition;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isExported;

  bool get isMember => classId != null;

  const NamespaceDecl(this.id, this.definition,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.classId,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.isExported = false})
      : super(SemanticNames.namespaceDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class TypeAliasDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitTypeAliasDecl(this);

  final String id;

  final String? classId;

  final List<GenericTypeParamExpr> genericTypeParameters;

  final TypeExpr value;

  bool get isMember => classId != null;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isExported;

  const TypeAliasDecl(this.id, this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.classId,
      this.genericTypeParameters = const [],
      this.isPrivate = false,
      this.isTopLevel = false,
      this.isExported = false})
      : super(SemanticNames.typeAliasDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class VarDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitVarDecl(this);

  final String id;

  final String? classId;

  final TypeExpr? declType;

  final AstNode? initializer;

  // final bool typeInferrence;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isConst;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isExported;

  final bool lateInitialize;

  const VarDecl(this.id,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.classId,
      this.declType,
      this.initializer,
      // this.typeInferrence = false,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isMutable = false,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.isExported = false,
      this.lateInitialize = false})
      : super(SemanticNames.variableDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ParamDecl extends VarDecl {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitParamDecl(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  const ParamDecl(String id,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      TypeExpr? declType,
      AstNode? initializer,
      bool isConst = false,
      bool isMutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false})
      : super(id,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length,
            declType: declType,
            initializer: initializer,
            isConst: isConst,
            isMutable: isMutable);
}

class ReferConstructCallExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitReferConstructCallExpr(this);

  final bool isSuper;

  final String? key;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  const ReferConstructCallExpr(
      this.isSuper, this.key, this.positionalArgs, this.namedArgs,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.referConstructorExpression,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class FuncDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitFuncDecl(this);

  final String internalName;

  final String? id;

  final String? classId;

  final List<GenericTypeParamExpr> genericTypeParameters;

  final String? externalTypeId;

  final TypeExpr? returnType;

  final ReferConstructCallExpr? referConstructor;

  final bool hasParamDecls;

  final List<ParamDecl> paramDecls;

  final int minArity;

  final int maxArity;

  final AstNode? definition;

  bool get isMember => classId != null;

  bool get isAbstract => definition != null;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isExported;

  final FunctionCategory category;

  bool get isLiteral => category == FunctionCategory.literal;

  const FuncDecl(this.internalName, this.paramDecls,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.id,
      this.classId,
      this.genericTypeParameters = const [],
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
      this.isPrivate = false,
      this.isTopLevel = false,
      this.isExported = false,
      this.category = FunctionCategory.normal})
      : super(SemanticNames.functionDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ClassDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitClassDecl(this);

  final String id;

  final String? classId;

  final List<GenericTypeParamExpr> genericTypeParameters;

  final TypeExpr? superType;

  final List<TypeExpr> implementsTypes;

  final List<TypeExpr> withTypes;

  bool get isMember => classId != null;

  bool get isNested => classId != null;

  final bool isExternal;

  final bool isAbstract;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isExported;

  final bool hasUserDefinedConstructor;

  final BlockStmt definition;

  const ClassDecl(this.id, this.definition,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.classId,
      this.genericTypeParameters = const [],
      this.superType,
      this.implementsTypes = const [],
      this.withTypes = const [],
      this.isExternal = false,
      this.isAbstract = false,
      this.isPrivate = false,
      this.isExported = true,
      this.isTopLevel = false,
      this.hasUserDefinedConstructor = false})
      : super(SemanticNames.classDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class EnumDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEnumDecl(this);

  final String id;

  final String? classId;

  final List<String> enumerations;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isExported;

  const EnumDecl(
    this.id,
    this.enumerations, {
    HTSource? source,
    int line = 0,
    int column = 0,
    int offset = 0,
    int length = 0,
    this.classId,
    this.isExternal = false,
    this.isPrivate = false,
    this.isTopLevel = false,
    this.isExported = true,
  }) : super(SemanticNames.enumDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class StructDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitStructDecl(this);

  final String id;

  final String? classId;

  final String? prototypeId;

  final List<VarDecl> fields;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isExported;

  bool get isMember => classId != null;

  StructDecl(this.id, this.fields,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      this.classId,
      this.prototypeId,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.isExported = false})
      : super(SemanticNames.structDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}
