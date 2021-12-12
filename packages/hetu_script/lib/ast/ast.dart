import '../declaration/namespace/namespace.dart';
// import '../grammar/lexicon.dart';
import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../declaration/declaration.dart';

part 'visitor/abstract_ast_visitor.dart';

abstract class AstNode {
  final String type;

  final HTSource? source;

  final int line;

  final int column;

  final int offset;

  final int length;

  int get end => offset + length;

  /// This value is null untill assigned by an analyzer
  HTNamespace? analysisNamespace;

  /// This value is null untill assigned by an analyzer
  HTDeclaration? declaration;

  /// Visit this node
  dynamic accept(AbstractAstVisitor visitor);

  /// Visit all the sub nodes of this, doing nothing by default.
  void subAccept(AbstractAstVisitor visitor) {}

  AstNode(this.type,
      {this.source,
      this.line = 0,
      this.column = 0,
      this.offset = 0,
      this.length = 0,
      this.analysisNamespace});
}

// Has no meaning, a helper for parser to recover from errors.
class EmptyExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEmptyExpr(this);

  EmptyExpr(
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

  final bool isDocumentation;

  CommentExpr(this.content,
      {this.isMultiline = false,
      this.isDocumentation = false,
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

  NullExpr(
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

  BooleanExpr(this.value,
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

  ConstIntExpr(this.value,
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

  ConstFloatExpr(this.value,
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

  ConstStringExpr(this.value, this.quotationLeft, this.quotationRight,
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
  void subAccept(AbstractAstVisitor visitor) {
    for (final node in interpolation) {
      node.accept(visitor);
    }
  }

  final String value;

  final String quotationLeft;

  final String quotationRight;

  final List<AstNode> interpolation;

  StringInterpolationExpr(
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

class IdentifierExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitIdentifierExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {}

  final String id;

  final bool isKeyword;

  final bool isLocal;

  final bool isSymbol;

  IdentifierExpr(this.id,
      {this.isSymbol = true,
      this.isKeyword = false,
      this.isLocal = true,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.symbolExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);

  IdentifierExpr.fromToken(Token id, {HTSource? source})
      : this(id.lexeme,
            isSymbol: id.type == SemanticNames.identifier,
            source: source,
            line: id.line,
            column: id.column,
            offset: id.offset,
            length: id.length,
            isKeyword: id.isKeyword);
}

class SpreadExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSpreadExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    value.accept(visitor);
  }

  final AstNode value;

  SpreadExpr(this.value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.spreadExpr,
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
  void subAccept(AbstractAstVisitor visitor) {
    for (final item in list) {
      item.accept(visitor);
    }
  }

  final List<AstNode> list;

  ListExpr(this.list,
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

// class MapExpr extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitMapExpr(this);

//   @override
//   void subAccept(AbstractAstVisitor visitor) {
//     for (final key in map.keys) {
//       key.accept(visitor);
//       final value = map[key]!;
//       value.accept(visitor);
//     }
//   }

//   final Map<AstNode, AstNode> map;

//   MapExpr(this.map,
//       {HTSource? source,
//       int line = 0,
//       int column = 0,
//       int offset = 0,
//       int length = 0})
//       : super(SemanticNames.mapLiteral,
//             source: source,
//             line: line,
//             column: column,
//             offset: offset,
//             length: length);
// }

class GroupExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitGroupExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    inner.accept(visitor);
  }

  final AstNode inner;

  GroupExpr(this.inner,
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
  void subAccept(AbstractAstVisitor visitor) {
    id?.accept(visitor);
    for (final item in arguments) {
      item.accept(visitor);
    }
  }

  final IdentifierExpr? id;

  final List<TypeExpr> arguments;

  final bool isNullable;

  final bool isLocal;

  TypeExpr(
      {this.id,
      this.arguments = const [],
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
  void subAccept(AbstractAstVisitor visitor) {
    id?.accept(visitor);
    declType.accept(visitor);
  }

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  bool get isNamed => id != null;

  /// Wether this is a named parameter.
  final IdentifierExpr? id;

  final TypeExpr declType;

  ParamTypeExpr(this.declType,
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
  void subAccept(AbstractAstVisitor visitor) {
    for (final item in genericTypeParameters) {
      item.accept(visitor);
    }
    for (final item in paramTypes) {
      item.accept(visitor);
    }
    returnType.accept(visitor);
  }

  final List<GenericTypeParameterExpr> genericTypeParameters;

  final List<ParamTypeExpr> paramTypes;

  final TypeExpr returnType;

  final bool hasOptionalParam;

  final bool hasNamedParam;

  FuncTypeExpr(this.returnType,
      {this.genericTypeParameters = const [],
      this.paramTypes = const [],
      this.hasOptionalParam = false,
      this.hasNamedParam = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0,
      bool isLocal = true})
      : super(
            isLocal: isLocal,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class GenericTypeParameterExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitGenericTypeParamExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id.accept(visitor);
    superType?.accept(visitor);
  }

  final IdentifierExpr id;

  final TypeExpr? superType;

  GenericTypeParameterExpr(this.id,
      {this.superType,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    value.accept(visitor);
  }

  final String op;

  final AstNode value;

  UnaryPrefixExpr(this.op, this.value,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    value.accept(visitor);
  }

  final AstNode value;

  final String op;

  UnaryPostfixExpr(this.value, this.op,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }

  final AstNode left;

  final String op;

  final AstNode right;

  BinaryExpr(this.left, this.op, this.right,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    condition.accept(visitor);
    thenBranch.accept(visitor);
    elseBranch.accept(visitor);
  }

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode elseBranch;

  TernaryExpr(this.condition, this.thenBranch, this.elseBranch,
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

class MemberExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitMemberExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    object.accept(visitor);
    key.accept(visitor);
  }

  final AstNode object;

  final IdentifierExpr key;

  MemberExpr(this.object, this.key,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    object.accept(visitor);
    key.accept(visitor);
    value.accept(visitor);
  }

  final AstNode object;

  final IdentifierExpr key;

  final AstNode value;

  MemberAssignExpr(this.object, this.key, this.value,
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

//   MemberCallExpr(this.collection, this.key, int line, int column, int offset, int length, {HTSource? source})
//       : super(SemanticType.memberGetExpr, source: source, line: line, column: column, offset: offset, length: length);
// }

class SubExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSubExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    object.accept(visitor);
    key.accept(visitor);
  }

  final AstNode object;

  final AstNode key;

  SubExpr(this.object, this.key,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    array.accept(visitor);
    key.accept(visitor);
    value.accept(visitor);
  }

  final AstNode array;

  final AstNode key;

  final AstNode value;

  SubAssignExpr(this.array, this.key, this.value,
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

//   SubCallExpr(this.collection, this.key, int line, int column, int offset, int length, {HTSource? source})
//       : super(SemanticType.subGetExpr, source: source, line: line, column: column, offset: offset, length: length);
// }

class CallExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCallExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    callee.accept(visitor);
    for (final posArg in positionalArgs) {
      posArg.accept(visitor);
    }
    for (final namedArg in namedArgs.values) {
      namedArg.accept(visitor);
    }
  }

  final AstNode callee;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  CallExpr(this.callee, this.positionalArgs, this.namedArgs,
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

class AssertStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitAssertStmt(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    expr.accept(visitor);
  }

  final AstNode expr;

  final bool hasEndOfStmtMark;

  AssertStmt(this.expr,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
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

class ExprStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitExprStmt(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    expr.accept(visitor);
  }

  final AstNode expr;

  final bool hasEndOfStmtMark;

  ExprStmt(this.expr,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    for (final stmt in statements) {
      stmt.accept(visitor);
    }
  }

  final List<AstNode> statements;

  final bool hasOwnNamespace;

  final String? id;

  BlockStmt(this.statements,
      {this.hasOwnNamespace = true,
      this.id,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    value?.accept(visitor);
  }

  final Token keyword;

  final AstNode? value;

  final bool hasEndOfStmtMark;

  ReturnStmt(this.keyword, this.value,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    condition.accept(visitor);
    thenBranch.accept(visitor);
    elseBranch?.accept(visitor);
  }

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode? elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    condition.accept(visitor);
    loop.accept(visitor);
  }

  final AstNode condition;

  final BlockStmt loop;

  WhileStmt(this.condition, this.loop,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    loop.accept(visitor);
    condition?.accept(visitor);
  }

  final BlockStmt loop;

  final AstNode? condition;

  DoStmt(this.loop, this.condition,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    init?.accept(visitor);
    condition?.accept(visitor);
    increment?.accept(visitor);
    loop.accept(visitor);
  }

  final VarDecl? init;

  final AstNode? condition;

  final AstNode? increment;

  final bool hasBracket;

  final BlockStmt loop;

  ForStmt(this.init, this.condition, this.increment, this.loop,
      {this.hasBracket = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.forStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ForRangeStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitForRangeStmt(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    iterator.accept(visitor);
    collection.accept(visitor);
    loop.accept(visitor);
  }

  final VarDecl iterator;

  final AstNode collection;

  final bool hasBracket;

  final BlockStmt loop;

  final bool iterateValue;

  ForRangeStmt(this.iterator, this.collection, this.loop,
      {this.hasBracket = false,
      this.iterateValue = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    condition?.accept(visitor);
    for (final caseExpr in cases.keys) {
      caseExpr.accept(visitor);
      final branch = cases[caseExpr]!;
      branch.accept(visitor);
    }
    elseBranch?.accept(visitor);
  }

  final AstNode? condition;

  final Map<AstNode, AstNode> cases;

  final AstNode? elseBranch;

  WhenStmt(this.cases, this.elseBranch, this.condition,
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

  final bool hasEndOfStmtMark;

  BreakStmt(this.keyword,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
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

  final bool hasEndOfStmtMark;

  ContinueStmt(this.keyword,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
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

  LibraryDecl(this.id,
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

class ImportExportDecl extends AstNode {
  @override
  String get type =>
      isExported ? SemanticNames.exportStmt : SemanticNames.importStmt;

  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitImportExportDecl(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    alias?.accept(visitor);
    for (final id in showList) {
      id.accept(visitor);
    }
  }

  final String? fromPath;

  final IdentifierExpr? alias;

  final List<IdentifierExpr> showList;

  /// The normalized absolute path of the imported module.
  /// It is left as null at the first time of parsing,
  /// because at this time we don't know yet.
  String? fullName;

  final bool hasEndOfStmtMark;

  final bool isExported;

  ImportExportDecl(
      {this.fromPath,
      this.showList = const [],
      this.alias,
      this.hasEndOfStmtMark = false,
      this.isExported = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.exportImportStmt,
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id.accept(visitor);
    definition.accept(visitor);
  }

  final IdentifierExpr id;

  final String? classId;

  final BlockStmt definition;

  final bool isTopLevel;

  bool get isMember => classId != null;

  final bool isPrivate;

  NamespaceDecl(this.id, this.definition,
      {this.classId,
      this.isPrivate = false,
      this.isTopLevel = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id.accept(visitor);
    for (final param in genericTypeParameters) {
      param.accept(visitor);
    }
    value.accept(visitor);
  }

  final IdentifierExpr id;

  final String? classId;

  final List<GenericTypeParameterExpr> genericTypeParameters;

  final TypeExpr value;

  final bool hasEndOfStmtMark;

  bool get isMember => classId != null;

  final bool isPrivate;

  final bool isTopLevel;

  TypeAliasDecl(this.id, this.value,
      {this.classId,
      this.genericTypeParameters = const [],
      this.hasEndOfStmtMark = false,
      this.isPrivate = false,
      this.isTopLevel = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id.accept(visitor);
    declType?.accept(visitor);
    initializer?.accept(visitor);
  }

  final IdentifierExpr id;

  final String? _internalName;

  String get internalName => _internalName ?? id.id;

  final String? classId;

  final TypeExpr? declType;

  final AstNode? initializer;

  final bool hasEndOfStmtMark;

  // final bool typeInferrence;

  bool get isMember => classId != null;

  final bool isField;

  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isConst;

  final bool isPrivate;

  final bool isTopLevel;

  final bool lateInitialize;

  VarDecl(this.id,
      {String? internalName,
      this.classId,
      this.declType,
      this.initializer,
      this.hasEndOfStmtMark = false,
      // this.typeInferrence = false,
      this.isField = false,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isMutable = false,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.lateInitialize = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : _internalName = internalName,
        super(SemanticNames.variableDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ParamDecl extends VarDecl {
  @override
  String get type => SemanticNames.parameterDeclaration;

  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitParamDecl(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  ParamDecl(IdentifierExpr id,
      {TypeExpr? declType,
      AstNode? initializer,
      bool isConst = false,
      bool isMutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

class RedirectingConstructorCallExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitReferConstructCallExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    callee.accept(visitor);
    key?.accept(visitor);
    for (final posArg in positionalArgs) {
      posArg.accept(visitor);
    }
    for (final namedArg in namedArgs.values) {
      namedArg.accept(visitor);
    }
  }

  final IdentifierExpr callee;

  final IdentifierExpr? key;

  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  RedirectingConstructorCallExpr(
      this.callee, this.positionalArgs, this.namedArgs,
      {this.key,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.redirectingConstructorCallExpression,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class FuncDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitFuncDecl(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id?.accept(visitor);
    for (final param in genericTypeParameters) {
      param.accept(visitor);
    }
    returnType?.accept(visitor);
    redirectingCtorCallExpr?.accept(visitor);
    for (final param in paramDecls) {
      param.accept(visitor);
    }
    definition?.accept(visitor);
  }

  final String internalName;

  final IdentifierExpr? id;

  final String? classId;

  final List<GenericTypeParameterExpr> genericTypeParameters;

  final String? externalTypeId;

  final TypeExpr? returnType;

  final RedirectingConstructorCallExpr? redirectingCtorCallExpr;

  final bool hasParamDecls;

  final List<ParamDecl> paramDecls;

  final int minArity;

  final int maxArity;

  final bool isExpressionBody;

  final bool hasEndOfStmtMark;

  final AstNode? definition;

  bool get isMember => classId != null;

  bool get isAbstract => definition != null;

  final bool isAsync;

  final bool isField;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final bool isPrivate;

  final bool isTopLevel;

  final FunctionCategory category;

  FuncDecl(this.internalName, this.paramDecls,
      {this.id,
      this.classId,
      this.genericTypeParameters = const [],
      this.externalTypeId,
      this.returnType,
      this.redirectingCtorCallExpr,
      this.hasParamDecls = true,
      this.minArity = 0,
      this.maxArity = 0,
      this.isExpressionBody = false,
      this.hasEndOfStmtMark = false,
      this.definition,
      this.isAsync = false,
      this.isField = false,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.category = FunctionCategory.normal,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id.accept(visitor);
    for (final param in genericTypeParameters) {
      param.accept(visitor);
    }
    superType?.accept(visitor);
    for (final implementsType in implementsTypes) {
      implementsType.accept(visitor);
    }
    for (final withType in withTypes) {
      withType.accept(visitor);
    }
    definition.accept(visitor);
  }

  final IdentifierExpr id;

  final String? classId;

  final List<GenericTypeParameterExpr> genericTypeParameters;

  final TypeExpr? superType;

  final List<TypeExpr> implementsTypes;

  final List<TypeExpr> withTypes;

  bool get isMember => classId != null;

  bool get isNested => classId != null;

  final bool isExternal;

  final bool isAbstract;

  final bool isPrivate;

  final bool isTopLevel;

  final bool hasUserDefinedConstructor;

  final BlockStmt definition;

  ClassDecl(this.id, this.definition,
      {this.classId,
      this.genericTypeParameters = const [],
      this.superType,
      this.implementsTypes = const [],
      this.withTypes = const [],
      this.isExternal = false,
      this.isAbstract = false,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.hasUserDefinedConstructor = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id.accept(visitor);
    for (final enumItem in enumerations) {
      enumItem.accept(visitor);
    }
  }

  final IdentifierExpr id;

  final String? classId;

  final List<IdentifierExpr> enumerations;

  bool get isMember => classId != null;

  final bool isExternal;

  final bool isPrivate;

  final bool isTopLevel;

  EnumDecl(this.id, this.enumerations,
      {this.classId,
      this.isExternal = false,
      this.isPrivate = false,
      this.isTopLevel = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.enumDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class StructDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitStructDecl(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    id.accept(visitor);
    prototypeId?.accept(visitor);
    for (final node in definition) {
      node.accept(visitor);
    }
  }

  final IdentifierExpr id;

  final IdentifierExpr? prototypeId;

  final List<AstNode> definition;

  final bool isPrivate;

  final bool isTopLevel;

  final bool lateInitialize;

  StructDecl(this.id, this.definition,
      {this.prototypeId,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.lateInitialize = true,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.structDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class StructObjField extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitStructObjField(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    value.accept(visitor);
  }

  final String? key; // if key is omitted, the value must be a identifier expr.

  final bool isSpread;

  final bool isComment;

  final AstNode value;

  StructObjField(this.value,
      {this.key,
      this.isSpread = false,
      this.isComment = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.structLiteralField,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class StructObjExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitStructObjExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    for (final value in fields) {
      value.accept(visitor);
    }
  }

  final String? id;

  final IdentifierExpr? prototypeId;

  final List<StructObjField> fields;

  StructObjExpr(
      //this.internalName,
      this.fields,
      {this.id,
      this.prototypeId,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(SemanticNames.structLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}
