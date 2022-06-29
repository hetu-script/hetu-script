import '../declaration/namespace/declaration_namespace.dart';
import '../parser/token.dart';
import '../grammar/constant.dart';
import '../source/source.dart';
import '../declaration/declaration.dart';
import '../../resource/resource.dart' show HTResourceType;
import '../../source/line_info.dart';
import '../error/error.dart';
import '../comment/comment.dart';

part 'visitor/abstract_ast_visitor.dart';

/// An abstract node of an abstract syntax tree.
abstract class ASTNode {
  final String type;

  List<Comment> precedingComments = [];

  Comment? trailingComment;

  List<Comment> succeedingComments = [];

  bool get isExpression => true;

  bool get isStatement => !isExpression;

  bool get hasEndOfStmtMark => false;

  /// Wether this value is constantant value,
  /// i.e. its value can be computed before compile into bytecode.
  bool get isConstValue => value != null;

  /// If this is a constant expressions, the constant interpreter will compute the value
  /// and assign to this property, otherwise, this peoperty is null.
  dynamic value;

  final HTSource? source;

  // ASTNode? parent;

  final int line;

  final int column;

  final int offset;

  final int length;

  int get end => offset + length;

  /// Visit this node
  dynamic accept(AbstractASTVisitor visitor);

  /// Visit all the sub nodes of this, doing nothing by default.
  void subAccept(AbstractASTVisitor visitor) {}

  ASTNode(this.type,
      {this.source,
      this.line = 0,
      this.column = 0,
      this.offset = 0,
      this.length = 0});
}

/// Parse result of a single file
class ASTSource extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitSource(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final stmt in nodes) {
      stmt.accept(visitor);
    }
  }

  String get fullName => source!.fullName;

  HTResourceType get resourceType => source!.type;

  LineInfo get lineInfo => source!.lineInfo;

  final List<ImportExportDecl> imports;

  final List<ASTNode> nodes;

  final List<HTError> errors;

  /// This value is false untill assigned by analyzer
  bool isResolved = false;

  @override
  bool get isExpression => false;

  ASTSource(
      {required this.nodes,
      required super.source,
      this.imports = const [],
      this.errors = const [],
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.source) {
    // for (final decl in imports) {
    //   decl.parent = this;
    // }
    // for (final decl in nodes) {
    //   decl.parent = this;
    // }
  }
}

/// A bundle of all imported sources
class ASTCompilation extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitCompilation(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final node in values.values) {
      node.accept(visitor);
    }
    for (final node in sources.values) {
      node.accept(visitor);
    }
  }

  final Map<String, ASTSource> values;

  final Map<String, ASTSource> sources;

  final String entryResourceName;

  final HTResourceType entryResourceType;

  final List<HTError> errors;

  @override
  bool get isExpression => false;

  ASTCompilation(
      {required this.values,
      required this.sources,
      required this.entryResourceName,
      required this.entryResourceType,
      required this.errors,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.compilation) {
    // for (final decl in values.values) {
    //   decl.parent = this;
    // }
    // for (final decl in sources.values) {
    //   decl.parent = this;
    // }
  }
}

class ASTEmptyLine extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitEmptyExpr(this);

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ASTEmptyLine(
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.empty);
}

class ASTLiteralNull extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitNullExpr(this);

  ASTLiteralNull(
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalNull);
}

class ASTLiteralBoolean extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool _value;

  @override
  bool get value => _value;

  ASTLiteralBoolean(this._value,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalBoolean);
}

class ASTLiteralInteger extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitIntLiteralExpr(this);

  final int _value;

  @override
  int get value => _value;

  ASTLiteralInteger(this._value,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalInteger);
}

class ASTLiteralFloat extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitFloatLiteralExpr(this);

  final double _value;

  @override
  double get value => _value;

  ASTLiteralFloat(this._value,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalFloat);
}

class ASTLiteralString extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitStringLiteralExpr(this);

  final String _value;

  @override
  String get value => _value;

  final String quotationLeft;

  final String quotationRight;

  ASTLiteralString(this._value, this.quotationLeft, this.quotationRight,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalString);
}

class ASTStringInterpolation extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitStringInterpolationExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final expr in interpolations) {
      expr.accept(visitor);
    }
  }

  final String text;

  final String quotationLeft;

  final String quotationRight;

  final List<ASTNode> interpolations;

  ASTStringInterpolation(
      this.text, this.quotationLeft, this.quotationRight, this.interpolations,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalStringInterpolation) {
    // for (final ast in interpolations) {
    //   ast.parent = this;
    // }
  }
}

class IdentifierExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitIdentifierExpr(this);

  final String id;

  final bool isMarked;

  final bool isLocal;

  /// This value is null untill assigned by analyzer
  HTDeclarationNamespace<ASTNode?>? analysisNamespace;

  /// This value is null untill assigned by analyzer
  HTDeclaration? declaration;

  IdentifierExpr(this.id,
      {this.isMarked = false,
      this.isLocal = true,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.identifierExpr);

  IdentifierExpr.fromToken(Token idTok,
      {bool isMarked = false, bool isLocal = true, HTSource? source})
      : this(idTok.literal,
            isLocal: isLocal,
            source: source,
            line: idTok.line,
            column: idTok.column,
            offset: idTok.offset,
            length: idTok.length);
}

class SpreadExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitSpreadExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    collection.accept(visitor);
  }

  final ASTNode collection;

  SpreadExpr(this.collection,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.spreadExpr);
}

class CommaExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitCommaExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final item in list) {
      item.accept(visitor);
    }
  }

  final List<ASTNode> list;

  final bool isLocal;

  CommaExpr(this.list,
      {this.isLocal = true,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.commaExpr);
}

class ListExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitListExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final item in list) {
      item.accept(visitor);
    }
  }

  final List<ASTNode> list;

  ListExpr(this.list,
      {HTSource? source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalList);
}

class InOfExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitInOfExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    collection.accept(visitor);
  }

  final ASTNode collection;

  final bool valueOf;

  InOfExpr(this.collection, this.valueOf,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.inExpr);
}

class GroupExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitGroupExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    inner.accept(visitor);
  }

  final ASTNode inner;

  GroupExpr(this.inner,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.groupExpr);
}

abstract class TypeExpr extends ASTNode {
  bool get isLocal;

  TypeExpr(String exprType,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(exprType);
}

class IntrinsicTypeExpr extends TypeExpr {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitIntrinsicTypeExpr(this);

  final IdentifierExpr id;

  final bool isTop;

  final bool isBottom;

  @override
  final bool isLocal;

  IntrinsicTypeExpr(
      {required this.id,
      this.isTop = false,
      this.isBottom = false,
      this.isLocal = true,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.intrinsicTypeExpr);
}

class NominalTypeExpr extends TypeExpr {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitNominalTypeExpr(this);

  final IdentifierExpr id;

  final List<TypeExpr> arguments;

  final bool isNullable;

  @override
  final bool isLocal;

  NominalTypeExpr(
      {required this.id,
      this.arguments = const [],
      this.isNullable = false,
      this.isLocal = true,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.nominalTypeExpr);
}

class ParamTypeExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitParamTypeExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
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
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.paramTypeExpr);
}

class FuncTypeExpr extends TypeExpr {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitFunctionTypeExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
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

  @override
  final bool isLocal;

  FuncTypeExpr(this.returnType,
      {this.genericTypeParameters = const [],
      this.paramTypes = const [],
      this.hasOptionalParam = false,
      this.hasNamedParam = false,
      this.isLocal = true,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.funcTypeExpr);
}

class FieldTypeExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitFieldTypeExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    fieldType.accept(visitor);
  }

  final String id;

  final TypeExpr fieldType;

  FieldTypeExpr(this.id, this.fieldType,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.fieldTypeExpr);
}

class StructuralTypeExpr extends TypeExpr {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitStructuralTypeExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final field in fieldTypes) {
      field.accept(visitor);
    }
  }

  final List<FieldTypeExpr> fieldTypes;

  @override
  final bool isLocal;

  StructuralTypeExpr(
      {this.fieldTypes = const [],
      this.isLocal = true,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.structuralTypeExpr);
}

class GenericTypeParameterExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitGenericTypeParamExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    superType?.accept(visitor);
  }

  final IdentifierExpr id;

  final NominalTypeExpr? superType;

  GenericTypeParameterExpr(this.id,
      {this.superType,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.genericTypeParamExpr);
}

/// -e, !e，++e, --e
class UnaryPrefixExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitUnaryPrefixExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    object.accept(visitor);
  }

  final String op;

  final ASTNode object;

  UnaryPrefixExpr(this.op, this.object,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.unaryExpr);
}

/// e++, e--
class UnaryPostfixExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitUnaryPostfixExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    object.accept(visitor);
  }

  final ASTNode object;

  final String op;

  UnaryPostfixExpr(this.object, this.op,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.unaryExpr);
}

class BinaryExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBinaryExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }

  final ASTNode left;

  final String op;

  final ASTNode right;

  BinaryExpr(this.left, this.op, this.right,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.binaryExpr);
}

class TernaryExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitTernaryExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    condition.accept(visitor);
    thenBranch.accept(visitor);
    elseBranch.accept(visitor);
  }

  final ASTNode condition;

  final ASTNode thenBranch;

  final ASTNode elseBranch;

  TernaryExpr(this.condition, this.thenBranch, this.elseBranch,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.binaryExpr);
}

class AssignExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitAssignExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    left.accept(visitor);
    right.accept(visitor);
  }

  final ASTNode left;

  final String op;

  final ASTNode right;

  AssignExpr(this.left, this.op, this.right,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.assignExpr);
}

class MemberExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitMemberExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    object.accept(visitor);
    key.accept(visitor);
  }

  final ASTNode object;

  final IdentifierExpr key;

  final bool isNullable;

  MemberExpr(this.object, this.key,
      {this.isNullable = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.memberGetExpr);
}

class SubExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitSubExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    object.accept(visitor);
    key.accept(visitor);
  }

  final ASTNode object;

  final ASTNode key;

  final bool isNullable;

  SubExpr(this.object, this.key,
      {this.isNullable = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.subGetExpr);
}

class CallExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitCallExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    callee.accept(visitor);
    for (final posArg in positionalArgs) {
      posArg.accept(visitor);
    }
    for (final namedArg in namedArgs.values) {
      namedArg.accept(visitor);
    }
  }

  final ASTNode callee;

  final List<ASTNode> positionalArgs;

  final Map<String, ASTNode> namedArgs;

  final bool isNullable;

  final bool hasNewOperator;

  CallExpr(this.callee,
      {this.positionalArgs = const [],
      this.namedArgs = const {},
      this.isNullable = false,
      this.hasNewOperator = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.callExpr);
}

class AssertStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitAssertStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    expr.accept(visitor);
  }

  final ASTNode expr;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  AssertStmt(this.expr,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.assertStmt);
}

class ThrowStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitThrowStmt(this);

  final ASTNode message;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ThrowStmt(this.message,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.throwStmt);
}

class ExprStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitExprStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    expr.accept(visitor);
  }

  final ASTNode expr;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ExprStmt(this.expr,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.exprStmt);
}

class BlockStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBlockStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final stmt in statements) {
      stmt.accept(visitor);
    }
  }

  final List<ASTNode> statements;

  final bool hasOwnNamespace;

  final String? id;

  @override
  bool get isExpression => false;

  BlockStmt(this.statements,
      {this.hasOwnNamespace = true,
      this.id,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.blockStmt);
}

class ReturnStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitReturnStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    value?.accept(visitor);
  }

  final Token keyword;

  final ASTNode? returnValue;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ReturnStmt(this.keyword,
      {this.returnValue,
      this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.returnStmt);
}

class IfStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitIf(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    condition.accept(visitor);
    thenBranch.accept(visitor);
    elseBranch?.accept(visitor);
  }

  final ASTNode condition;

  final ASTNode thenBranch;

  final ASTNode? elseBranch;

  @override
  final bool isExpression;

  IfStmt(this.condition, this.thenBranch,
      {this.elseBranch,
      this.isExpression = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.ifStmt);
}

class WhileStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitWhileStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    condition.accept(visitor);
    loop.accept(visitor);
  }

  final ASTNode condition;

  final BlockStmt loop;

  @override
  bool get isExpression => false;

  WhileStmt(this.condition, this.loop,
      {super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.whileStmt);
}

class DoStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitDoStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    loop.accept(visitor);
    condition?.accept(visitor);
  }

  final BlockStmt loop;

  final ASTNode? condition;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  DoStmt(this.loop, this.condition,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.doStmt);
}

class ForStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitForStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    init?.accept(visitor);
    condition?.accept(visitor);
    increment?.accept(visitor);
    loop.accept(visitor);
  }

  final VarDecl? init;

  final ASTNode? condition;

  final ASTNode? increment;

  final bool hasBracket;

  final BlockStmt loop;

  @override
  bool get isExpression => false;

  ForStmt(this.init, this.condition, this.increment, this.loop,
      {this.hasBracket = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.forStmt);
}

class ForRangeStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitForRangeStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    iterator.accept(visitor);
    collection.accept(visitor);
    loop.accept(visitor);
  }

  final VarDecl iterator;

  final ASTNode collection;

  final bool hasBracket;

  final BlockStmt loop;

  final bool iterateValue;

  @override
  bool get isExpression => false;

  ForRangeStmt(this.iterator, this.collection, this.loop,
      {this.hasBracket = false,
      this.iterateValue = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.forInStmt);
}

class WhenStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitWhen(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    condition?.accept(visitor);
    for (final caseExpr in cases.keys) {
      caseExpr.accept(visitor);
      final branch = cases[caseExpr]!;
      branch.accept(visitor);
    }
    elseBranch?.accept(visitor);
  }

  final ASTNode? condition;

  final Map<ASTNode, ASTNode> cases;

  final ASTNode? elseBranch;

  @override
  final bool isExpression;

  WhenStmt(this.cases, this.elseBranch, this.condition,
      {this.isExpression = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.whenStmt);
}

class BreakStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  BreakStmt(this.keyword,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.breakStmt);
}

class ContinueStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  ContinueStmt(this.keyword,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.continueStmt);
}

class DeleteStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitDeleteStmt(this);

  final String symbol;

  @override
  final bool hasEndOfStmtMark;

  DeleteStmt(this.symbol,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.deleteStmt);
}

class DeleteMemberStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitDeleteMemberStmt(this);

  final ASTNode object;

  final String key;

  @override
  final bool hasEndOfStmtMark;

  DeleteMemberStmt(this.object, this.key,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.deleteMemberStmt);
}

class DeleteSubStmt extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitDeleteSubStmt(this);

  final ASTNode object;

  final ASTNode key;

  @override
  final bool hasEndOfStmtMark;

  DeleteSubStmt(this.object, this.key,
      {this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.deleteSubMemberStmt);
}

class ImportExportDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitImportExportDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    alias?.accept(visitor);
  }

  final String? fromPath;

  final IdentifierExpr? alias;

  final List<IdentifierExpr> showList;

  final bool isPreloadedModule;

  final bool isExport;

  bool get willExportAll => isExport && showList.isEmpty;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  /// The normalized absolute path of the imported file.
  /// It is left as null at the first time of parsing,
  /// because at this time we don't know yet.
  String? fullFromPath;

  ImportExportDecl(
      {this.fromPath,
      this.alias,
      this.showList = const [],
      this.isPreloadedModule = false,
      this.isExport = false,
      this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(isExport ? Semantic.exportStmt : Semantic.importStmt);
}

class NamespaceDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitNamespaceDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
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
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.namespaceDeclaration);
}

class TypeAliasDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitTypeAliasDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
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
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.typeAliasDeclaration);
}

// class ConstDecl extends AstNode {
//   @override
//   dynamic accept(AbstractAstVisitor visitor) => visitor.visitConstDecl(this);

//   @override
//   void subAccept(AbstractAstVisitor visitor) {
//     // id.accept(visitor);
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

class VarDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitVarDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    declType?.accept(visitor);
    initializer?.accept(visitor);
  }

  final IdentifierExpr id;

  final String? _internalName;

  String get internalName => _internalName ?? id.id;

  final String? classId;

  final TypeExpr? declType;

  ASTNode? initializer;

  // final bool typeInferrence;

  bool get isMember => classId != null;

  final bool isConst;

  final bool isField;

  final bool isExternal;

  final bool isStatic;

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
      this.isConst = false,
      this.isField = false,
      this.isExternal = false,
      this.isStatic = false,
      this.isMutable = false,
      this.isPrivate = false,
      this.isTopLevel = false,
      this.lateFinalize = false,
      this.lateInitialize = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : _internalName = internalName,
        super(Semantic.variableDeclaration);
}

class DestructuringDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitDestructuringDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    initializer.subAccept(visitor);
  }

  final Map<IdentifierExpr, TypeExpr?> ids;

  ASTNode initializer;

  final bool isVector;

  final bool isTopLevel;

  final bool isMutable;

  @override
  bool get isExpression => false;

  @override
  final bool hasEndOfStmtMark;

  DestructuringDecl(
      {required this.ids,
      required this.isVector,
      required this.initializer,
      this.isTopLevel = false,
      this.isMutable = false,
      this.hasEndOfStmtMark = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.destructuringDeclaration);
}

class ParamDecl extends VarDecl {
  @override
  String get type => Semantic.parameterDeclaration;

  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitParamDecl(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  @override
  bool get isExpression => true;

  ParamDecl(IdentifierExpr id,
      {TypeExpr? declType,
      ASTNode? initializer,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(id,
            declType: declType, initializer: initializer, isMutable: true);
}

class RedirectingConstructorCallExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitReferConstructCallExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
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

  final List<ASTNode> positionalArgs;

  final Map<String, ASTNode> namedArgs;

  RedirectingConstructorCallExpr(
      this.callee, this.positionalArgs, this.namedArgs,
      {this.key,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.redirectingConstructorCallExpression);
}

class FuncDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitFuncDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
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

  final ASTNode? definition;

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

  FuncDecl(this.internalName,
      {this.id,
      this.classId,
      this.genericTypeParameters = const [],
      this.externalTypeId,
      this.redirectingCtorCallExpr,
      this.paramDecls = const [],
      this.hasParamDecls = true,
      this.returnType,
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
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.functionDeclaration);
}

class ClassDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitClassDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
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

  final List<NominalTypeExpr> implementsTypes;

  final List<NominalTypeExpr> withTypes;

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
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.classDeclaration);
}

class EnumDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitEnumDecl(this);

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
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.enumDeclaration);
}

class StructDecl extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitStructDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    prototypeId?.accept(visitor);
    for (final node in definition) {
      node.accept(visitor);
    }
  }

  final IdentifierExpr id;

  final IdentifierExpr? prototypeId;

  final List<ASTNode> definition;

  final bool isPrivate;

  final bool isTopLevel;

  // final bool lateInitialize;

  @override
  bool get isExpression => false;

  StructDecl(this.id, this.definition,
      {this.prototypeId,
      this.isPrivate = false,
      this.isTopLevel = false,
      // this.lateInitialize = true,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.structDeclaration);
}

class StructObjField extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitStructObjField(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    value?.accept(visitor);
  }

// if key is omitted, the value must be a identifier expr.
  final IdentifierExpr? key;

  final bool isSpread;

  final ASTNode? fieldValue;

  StructObjField(
      {this.key,
      this.fieldValue,
      this.isSpread = false,
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalStructField);
}

class StructObjExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitStructObjExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final field in fields) {
      field.subAccept(visitor);
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
      super.source,
      super.line = 0,
      super.column = 0,
      super.offset = 0,
      super.length = 0})
      : super(Semantic.literalStruct);
}
