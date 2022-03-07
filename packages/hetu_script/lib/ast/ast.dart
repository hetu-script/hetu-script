import '../declaration/namespace/declaration_namespace.dart';
import '../lexer/token.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../declaration/declaration.dart';
import '../../resource/resource.dart' show HTResourceType;
import '../../source/line_info.dart';
import '../error/error.dart';

part 'visitor/abstract_ast_visitor.dart';

class Comment {
  final String content;

  final bool isMultiline;

  final bool isDocumentation;

  Comment(this.content,
      {this.isMultiline = false, this.isDocumentation = false});
}

/// Root object of all ast node
abstract class AstNode {
  final String type;

  final precedingComments = <Comment>[];

  Comment? consumingLineEndComment;

  bool get isExpression => true;

  bool get isStatement => !isExpression;

  bool get hasEndOfStmtMark => false;

  bool get isConstValue => value != null;

  // for constant expressions, this value is not null
  dynamic value;

  final HTSource? source;

  AstNode? parent;

  final int line;

  final int column;

  final int offset;

  final int length;

  int get end => offset + length;

  /// This value is null untill assigned by an analyzer
  HTDeclarationNamespace? analysisNamespace;

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

/// Parse result of a single file
class AstSource extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitCompilationUnit(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    for (final stmt in nodes) {
      stmt.accept(visitor);
    }
  }

  String get fullName => source!.fullName;

  HTResourceType get resourceType => source!.type;

  LineInfo get lineInfo => source!.lineInfo;

  final List<ImportExportDecl> imports;

  final List<AstNode> nodes;

  final List<HTError>? errors;

  @override
  bool get isExpression => false;

  AstSource(
      {required this.nodes,
      required HTSource source,
      this.imports = const [],
      this.errors = const [],
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.compilationUnit,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length) {
    for (final decl in imports) {
      decl.parent = this;
    }
    for (final decl in nodes) {
      decl.parent = this;
    }
  }
}

/// A bundle of all imported sources
class AstCompilation extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCompilation(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    for (final node in values.values) {
      node.accept(visitor);
    }
    for (final node in sources.values) {
      node.accept(visitor);
    }
  }

  final Map<String, AstSource> values;

  final Map<String, AstSource> sources;

  final HTResourceType entryResourceType;

  final List<HTError> errors;

  @override
  bool get isExpression => false;

  AstCompilation(
      {required this.values,
      required this.sources,
      required this.entryResourceType,
      required this.errors,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.compilation,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length) {
    for (final decl in values.values) {
      decl.parent = this;
    }
    for (final decl in sources.values) {
      decl.parent = this;
    }
  }
}

class EmptyLine extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEmptyExpr(this);

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  EmptyLine(
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.empty,
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
      : super(Semantic.nullLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class BooleanLiteralExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool _value;

  @override
  bool get value => _value;

  BooleanLiteralExpr(this._value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.booleanLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class IntegerLiteralExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitIntLiteralExpr(this);

  final int _value;

  @override
  int get value => _value;

  IntegerLiteralExpr(this._value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.integerLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class FloatLiteralExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitFloatLiteralExpr(this);

  final double _value;

  @override
  double get value => _value;

  FloatLiteralExpr(this._value,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.floatLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class StringLiteralExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitStringLiteralExpr(this);

  final String _value;

  @override
  String get value => _value;

  final String quotationLeft;

  final String quotationRight;

  StringLiteralExpr(this._value, this.quotationLeft, this.quotationRight,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.stringLiteral,
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
    for (final expr in interpolations) {
      expr.accept(visitor);
    }
  }

  final String text;

  final String quotationLeft;

  final String quotationRight;

  final List<AstNode> interpolations;

  StringInterpolationExpr(
      this.text, this.quotationLeft, this.quotationRight, this.interpolations,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.stringInterpolation,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length) {
    for (final ast in interpolations) {
      ast.parent = this;
    }
  }
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
      : super(Semantic.symbolExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);

  IdentifierExpr.fromToken(Token idTok, {bool isLocal = true, HTSource? source})
      : this(idTok.lexeme,
            isSymbol: idTok.type == Semantic.identifier,
            isKeyword: idTok.isKeyword,
            isLocal: isLocal,
            source: source,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: idTok.length);
}

class SpreadExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSpreadExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    collection.accept(visitor);
  }

  final AstNode collection;

  SpreadExpr(this.collection,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.spreadExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class CommaExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitCommaExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    for (final item in list) {
      item.accept(visitor);
    }
  }

  final List<AstNode> list;

  final bool isLocal;

  CommaExpr(this.list,
      {this.isLocal = true,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.commaExpr,
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
      : super(Semantic.listLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class InOfExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitInOfExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    collection.accept(visitor);
  }

  final AstNode collection;

  final bool valueOf;

  InOfExpr(this.collection, this.valueOf,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.inExpr,
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
      : super(Semantic.groupExpr,
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
      : super(Semantic.typeExpr,
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
      : super(Semantic.paramTypeExpr,
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

class FieldTypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitFieldTypeExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    fieldType.accept(visitor);
  }

  final String id;

  final TypeExpr fieldType;

  FieldTypeExpr(this.id, this.fieldType,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.fieldTypeExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class StructuralTypeExpr extends TypeExpr {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitStructuralTypeExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    for (final field in fieldTypes) {
      field.accept(visitor);
    }
  }

  final List<FieldTypeExpr> fieldTypes;

  StructuralTypeExpr(
      {this.fieldTypes = const [],
      bool isLocal = true,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
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
      : super(Semantic.genericTypeParamExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

/// -e, !e，++e, --e
class UnaryPrefixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPrefixExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    object.accept(visitor);
  }

  final String op;

  final AstNode object;

  UnaryPrefixExpr(this.op, this.object,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.unaryExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

/// e., e?., e[], e?[], e(), e?(), e++, e--
class UnaryPostfixExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitUnaryPostfixExpr(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    object.accept(visitor);
  }

  final AstNode object;

  final String op;

  UnaryPostfixExpr(this.object, this.op,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.unaryExpr,
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
      : super(Semantic.binaryExpr,
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
      : super(Semantic.binaryExpr,
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

  final bool isNullable;

  MemberExpr(this.object, this.key,
      {this.isNullable = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.memberGetExpr,
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
    assignValue.accept(visitor);
  }

  final AstNode object;

  final IdentifierExpr key;

  final AstNode assignValue;

  MemberAssignExpr(this.object, this.key, this.assignValue,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.memberSetExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

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

  final bool isNullable;

  SubExpr(this.object, this.key,
      {this.isNullable = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.subGetExpr,
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
    assignValue.accept(visitor);
  }

  final AstNode array;

  final AstNode key;

  final AstNode assignValue;

  SubAssignExpr(this.array, this.key, this.assignValue,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.subSetExpr,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

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

  final bool isNullable;

  CallExpr(this.callee,
      {this.positionalArgs = const [],
      this.namedArgs = const {},
      this.isNullable = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.callExpr,
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

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  AssertStmt(this.expr,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.assertStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ThrowStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitThrowStmt(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {}

  final AstNode message;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ThrowStmt(this.message,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.throwStmt,
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

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ExprStmt(this.expr,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.exprStmt,
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

  @override
  bool get isExpression => false;

  BlockStmt(this.statements,
      {this.hasOwnNamespace = true,
      this.id,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.blockStmt,
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

  final AstNode? returnValue;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ReturnStmt(this.keyword,
      {this.returnValue,
      this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.returnStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class IfStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitIf(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    condition.accept(visitor);
    thenBranch.accept(visitor);
    elseBranch?.accept(visitor);
  }

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode? elseBranch;

  @override
  final bool isExpression;

  IfStmt(this.condition, this.thenBranch,
      {this.elseBranch,
      this.isExpression = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.ifStmt,
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

  @override
  bool get isExpression => false;

  WhileStmt(this.condition, this.loop,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.whileStmt,
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

  @override
  bool get isExpression => false;

  DoStmt(this.loop, this.condition,
      {HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.doStmt,
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

  @override
  bool get isExpression => false;

  ForStmt(this.init, this.condition, this.increment, this.loop,
      {this.hasBracket = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.forStmt,
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

  @override
  bool get isExpression => false;

  ForRangeStmt(this.iterator, this.collection, this.loop,
      {this.hasBracket = false,
      this.iterateValue = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.forInStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class WhenStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhen(this);

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

  @override
  final bool isExpression;

  WhenStmt(this.cases, this.elseBranch, this.condition,
      {this.isExpression = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.whenStmt,
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

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  BreakStmt(this.keyword,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.breakStmt,
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

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ContinueStmt(this.keyword,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.continueStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class DeleteStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitDeleteStmt(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {}

  final String symbol;

  @override
  final bool hasEndOfStmtMark;

  DeleteStmt(this.symbol,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.deleteStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class DeleteMemberStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitDeleteMemberStmt(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {}

  final AstNode object;

  final String key;

  @override
  final bool hasEndOfStmtMark;

  DeleteMemberStmt(this.object, this.key,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.deleteMemberStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class DeleteSubStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitDeleteSubStmt(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {}

  final AstNode object;

  final AstNode key;

  @override
  final bool hasEndOfStmtMark;

  DeleteSubStmt(this.object, this.key,
      {this.hasEndOfStmtMark = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.deleteSubMemberStmt,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ImportExportDecl extends AstNode {
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

  final bool isPreloadedModule;

  /// The normalized absolute path of the imported file.
  /// It is left as null at the first time of parsing,
  /// because at this time we don't know yet.
  String? fullName;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  final bool isExport;

  ImportExportDecl(
      {this.fromPath,
      this.showList = const [],
      this.alias,
      this.hasEndOfStmtMark = false,
      this.isExport = false,
      this.isPreloadedModule = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(isExport ? Semantic.exportStmt : Semantic.importStmt,
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

  @override
  bool get isExpression => false;

  NamespaceDecl(this.id, this.definition,
      {this.classId,
      this.isPrivate = false,
      this.isTopLevel = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.namespaceDeclaration,
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
    typeValue.accept(visitor);
  }

  final IdentifierExpr id;

  final String? classId;

  final List<GenericTypeParameterExpr> genericTypeParameters;

  final TypeExpr typeValue;

  @override
  final bool hasEndOfStmtMark;

  bool get isMember => classId != null;

  final bool isPrivate;

  final bool isTopLevel;

  @override
  bool get isExpression => false;

  TypeAliasDecl(this.id, this.typeValue,
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
      : super(Semantic.typeAliasDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

// class ConstDecl extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitConstDecl(this);

//   @override
//   void subAccept(AbstractAstVisitor visitor) {
//     id.accept(visitor);
//     declType?.accept(visitor);
//     constExpr.accept(visitor);
//   }

//   final IdentifierExpr id;

//   final String? classId;

//   final TypeExpr? declType;

//   final AstNode constExpr;

//   @override
//   final bool hasEndOfStmtMark;

//   final bool isTopLevel;

//   @override
//   bool get isExpression => false;

//   ConstDecl(this.id, this.constExpr,
//       {this.declType,
//       this.classId,
//       this.hasEndOfStmtMark = false,
//       this.isTopLevel = false,
//       HTSource? source,
//       int line = 0,
//       int column = 0,
//       int offset = 0,
//       int length = 0})
//       : super(Semantic.constantDeclaration,
//             source: source,
//             line: line,
//             column: column,
//             offset: offset,
//             length: length);
// }

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

  AstNode? initializer;

  // final bool typeInferrence;

  bool get isMember => classId != null;

  final bool isField;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isMutable;

  final bool isPrivate;

  final bool isTopLevel;

  final bool lateFinalize;

  final bool lateInitialize;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

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
      this.lateFinalize = false,
      this.lateInitialize = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : _internalName = internalName,
        super(Semantic.variableDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class DestructuringDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitDestructuringDecl(this);

  @override
  void subAccept(AbstractAstVisitor visitor) {
    for (final id in ids.keys) {
      id.accept(visitor);
      final typeExpr = ids[id];
      typeExpr?.accept(visitor);
    }
  }

  final Map<IdentifierExpr, TypeExpr?> ids;

  AstNode initializer;

  final bool isVector;

  final bool isMutable;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  DestructuringDecl(
      {required this.ids,
      required this.isVector,
      required this.initializer,
      this.hasEndOfStmtMark = false,
      this.isMutable = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.destructuringDeclaration,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}

class ParamDecl extends VarDecl {
  @override
  String get type => Semantic.parameterDeclaration;

  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitParamDecl(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  @override
  bool get isExpression => true;

  ParamDecl(IdentifierExpr id,
      {TypeExpr? declType,
      AstNode? initializer,
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
            isMutable: true);
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
      : super(Semantic.redirectingConstructorCallExpression,
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

  @override
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

  @override
  bool get isExpression => false;

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
      : super(Semantic.functionDeclaration,
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

  final bool lateResolve;

  final BlockStmt definition;

  @override
  bool get isExpression => false;

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
      this.lateResolve = true,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.classDeclaration,
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

  @override
  bool get isExpression => false;

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
      : super(Semantic.enumDeclaration,
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

  @override
  bool get isExpression => false;

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
      : super(Semantic.structDeclaration,
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
    key?.accept(visitor);
    value?.accept(visitor);
  }

// if key is omitted, the value must be a identifier expr.
  final IdentifierExpr? key;

  final bool isSpread;

  final AstNode? fieldValue;

  StructObjField(
      {this.key,
      this.fieldValue,
      this.isSpread = false,
      HTSource? source,
      int line = 0,
      int column = 0,
      int offset = 0,
      int length = 0})
      : super(Semantic.structLiteralField,
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
    id?.accept(visitor);
    prototypeId?.accept(visitor);
    for (final field in fields) {
      field.accept(visitor);
    }
  }

  final IdentifierExpr? id;

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
      : super(Semantic.structLiteral,
            source: source,
            line: line,
            column: column,
            offset: offset,
            length: length);
}
