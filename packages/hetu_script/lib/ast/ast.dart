import 'package:pub_semver/pub_semver.dart';

import '../declaration/namespace/declaration_namespace.dart';
import '../parser/token.dart';
import '../source/source.dart';
import '../declaration/declaration.dart';
import '../../resource/resource.dart' show HTResourceType;
import '../../source/line_info.dart';
import '../error/error.dart';
import '../../common/internal_identifier.dart';
import '../common/function_category.dart';

part 'visitor/abstract_ast_visitor.dart';

/// An abstract node of an abstract syntax tree.
abstract class ASTNode {
  final String type;

  List<ASTAnnotation> precedings = [];

  ASTAnnotation? trailing;

  ASTAnnotation? trailingAfterComma;

  List<ASTAnnotation> succeedings = [];

  String get documentation {
    final documentation = StringBuffer();
    for (final line in precedings) {
      if (line.isDocumentation) {
        documentation.writeln(line.content);
      }
    }
    return documentation.toString();
  }

  final bool isStatement;

  bool get isExpression => !isStatement;

  /// Wether this is a struct/code block expression.
  final bool isBlock;

  /// Wether this value is constantant value,
  /// i.e. its value is computed before compile into bytecode.
  bool get isConstValue => value != null;

  final bool isAwait;

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

  ASTNode(
    this.type, {
    this.isStatement = false,
    this.isAwait = false,
    this.isBlock = false,
    this.source,
    this.line = 0,
    this.column = 0,
    this.offset = 0,
    this.length = 0,
  });
}

/// Comments or empty lines. Which has no meaning when interpreting,
/// but they have meanings in formatting,
/// so we keeps them as a special ASTNode.
abstract class ASTAnnotation extends ASTNode {
  final String content;

  final bool isDocumentation;

  ASTAnnotation(
    super.type, {
    required this.content,
    required this.isDocumentation,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  });
}

class ASTComment extends ASTAnnotation {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitComment(this);

  final bool isMultiLine;

  final bool isTrailing;

  ASTComment({
    required String content,
    required super.isDocumentation,
    required this.isMultiLine,
    required this.isTrailing,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.comment, content: content);

  ASTComment.fromCommentToken(TokenComment token)
      : this(
          content: token.literal,
          isDocumentation: token.isDocumentation,
          isMultiLine: token.isMultiLine,
          isTrailing: token.isTrailing,
        );
}

class ASTEmptyLine extends ASTAnnotation {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitEmptyLine(this);

  ASTEmptyLine({
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.emptyLine,
          content: '\n',
          isDocumentation: false,
        );
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

  ASTSource({
    required this.nodes,
    this.imports = const [],
    this.errors = const [],
    required super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.source, isStatement: true) {
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

  final String entryFullname;

  final HTResourceType entryResourceType;

  final List<HTError> errors;

  final Version? version;

  ASTCompilation({
    required this.values,
    required this.sources,
    required this.entryFullname,
    required this.entryResourceType,
    required this.errors,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
    this.version,
  }) : super(InternalIdentifier.compilation, isStatement: true) {
    // for (final decl in values.values) {
    //   decl.parent = this;
    // }
    // for (final decl in sources.values) {
    //   decl.parent = this;
    // }
  }
}

class ASTEmpty extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitEmptyExpr(this);

  ASTEmpty({
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.empty);
}

class ASTLiteralNull extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitNullExpr(this);

  ASTLiteralNull({
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalNull);
}

class ASTLiteralBoolean extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool _value;

  @override
  bool get value => _value;

  ASTLiteralBoolean(
    this._value, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalBoolean);
}

class ASTLiteralInteger extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitIntLiteralExpr(this);

  final int _value;

  @override
  int get value => _value;

  ASTLiteralInteger(
    this._value, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalInteger);
}

class ASTLiteralFloat extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitFloatLiteralExpr(this);

  final double _value;

  @override
  double get value => _value;

  ASTLiteralFloat(
    this._value, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalFloat);
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

  ASTLiteralString(
    this._value,
    this.quotationLeft,
    this.quotationRight, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalString);
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
    this.text,
    this.quotationLeft,
    this.quotationRight,
    this.interpolations, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.stringInterpolation,
          isAwait: interpolations.any((element) => element.isAwait),
        ) {
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

  IdentifierExpr(
    this.id, {
    this.isMarked = false,
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.identifierExpression);

  IdentifierExpr.fromToken(
    Token idTok, {
    bool isMarked = false,
    bool isLocal = true,
    HTSource? source,
  }) : this(idTok.literal,
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

  SpreadExpr(
    this.collection, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.spreadExpression,
          isAwait: collection.isAwait,
        );
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

  CommaExpr(
    this.list, {
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.commaExpression,
          isAwait: list.any((element) => element.isAwait),
        );
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

  ListExpr(
    this.list, {
    HTSource? source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.literalList,
          isAwait: list.any((element) => element.isAwait),
        );
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

  InOfExpr(
    this.collection,
    this.valueOf, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.inOfExpression,
          isAwait: collection.isAwait,
        );
}

class GroupExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitGroupExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    inner.accept(visitor);
  }

  final ASTNode inner;

  GroupExpr(
    this.inner, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.groupExpression,
          isAwait: inner.isAwait,
        );
}

abstract class TypeExpr extends ASTNode {
  bool get isLocal;

  TypeExpr(
    super.exprType, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  });
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

  IntrinsicTypeExpr({
    required this.id,
    this.isTop = false,
    this.isBottom = false,
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.intrinsicTypeExpression);
}

class NominalTypeExpr extends TypeExpr {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitNominalTypeExpr(this);

  final IdentifierExpr id;

  final List<IdentifierExpr> namespacesWithin;

  final List<TypeExpr> arguments;

  final bool isNullable;

  @override
  final bool isLocal;

  NominalTypeExpr({
    required this.id,
    this.namespacesWithin = const [],
    this.arguments = const [],
    this.isNullable = false,
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.nominalTypeExpression);
}

class ParamTypeExpr extends ASTNode {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitParamTypeExpr(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    declType.accept(visitor);
  }

  /// Wether this is an optional positional parameter.
  final bool isOptionalPositional;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  /// Wether this is a optional named parameter.
  bool get isNamed => id != null;

  final IdentifierExpr? id;

  final TypeExpr declType;

  ParamTypeExpr(
    this.declType, {
    this.id,
    this.isOptionalPositional = false,
    this.isVariadic = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.paramTypeExpression);
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

  FuncTypeExpr(
    this.returnType, {
    this.genericTypeParameters = const [],
    this.paramTypes = const [],
    this.hasOptionalParam = false,
    this.hasNamedParam = false,
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.functionTypeExpression);
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

  FieldTypeExpr(
    this.id,
    this.fieldType, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.fieldTypeExpression);
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

  StructuralTypeExpr({
    this.fieldTypes = const [],
    this.isLocal = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.structuralTypeExpression);
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

  GenericTypeParameterExpr(
    this.id, {
    this.superType,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.genericTypeParamExpression);
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

  UnaryPrefixExpr(
    this.op,
    this.object, {
    super.isAwait,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.unaryPrefixExpression);
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

  UnaryPostfixExpr(
    this.object,
    this.op, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.unaryPostfixExpression);
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

  BinaryExpr(
    this.left,
    this.op,
    this.right, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.binaryExpression,
          isAwait: left.isAwait || right.isAwait,
        );
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

  TernaryExpr(
    this.condition,
    this.thenBranch,
    this.elseBranch, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.ternaryExpression,
          isAwait:
              condition.isAwait || thenBranch.isAwait || elseBranch.isAwait,
        );
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

  AssignExpr(
    this.left,
    this.op,
    this.right, {
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.assignExpression,
          isAwait: right.isAwait,
        );
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

  MemberExpr(
    this.object,
    this.key, {
    this.isNullable = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.memberGetExpression,
          isAwait: object.isAwait,
        );
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

  SubExpr(
    this.object,
    this.key, {
    this.isNullable = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.subGetExpression,
          isAwait: object.isAwait || key.isAwait,
        );
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

  final ASTAnnotation? documentationsWithinEmptyContent;

  final List<ASTNode> positionalArgs;

  final Map<String, ASTNode> namedArgs;

  final bool isNullable;

  final bool hasNewOperator;

  CallExpr(
    this.callee, {
    this.positionalArgs = const [],
    this.namedArgs = const {},
    this.documentationsWithinEmptyContent,
    this.isNullable = false,
    this.hasNewOperator = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.callExpression,
          isAwait: callee.isAwait ||
              positionalArgs.any((element) => element.isAwait) ||
              namedArgs.values.any((element) => element.isAwait),
        );
}

class IfExpr extends ASTNode {
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

  IfExpr(
    this.condition,
    this.thenBranch, {
    this.elseBranch,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.ifExpression,
          isAwait: condition.isAwait ||
              thenBranch.isAwait ||
              (elseBranch?.isAwait ?? false),
          isBlock: thenBranch.isBlock,
        ) {
    if (elseBranch != null) {
      assert(thenBranch.isBlock == elseBranch!.isBlock);
    }
  }
}

class ForExpr extends ASTNode {
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

  ForExpr(
    this.init,
    this.condition,
    this.increment,
    this.loop, {
    this.hasBracket = false,
    super.isBlock,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.forExpression,
          isAwait: (init?.isAwait ?? false) ||
              (condition?.isAwait ?? false) ||
              (increment?.isAwait ?? false) ||
              loop.isAwait,
        );
}

class ForRangeExpr extends ASTNode {
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

  ForRangeExpr(
    this.iterator,
    this.collection,
    this.loop, {
    this.hasBracket = false,
    this.iterateValue = false,
    super.isBlock,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.forRangeExpression,
          isAwait: collection.isAwait || loop.isAwait,
        );
}

abstract class Statement extends ASTNode {
  bool hasEndOfStmtMark;

  Statement(
    super.type, {
    super.isAwait,
    this.hasEndOfStmtMark = false,
    super.isStatement = true,
    super.isBlock,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) {
    if (isBlock) {
      assert(!hasEndOfStmtMark);
    }
  }
}

class AssertStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitAssertStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    expr.accept(visitor);
  }

  final ASTNode expr;

  AssertStmt(
    this.expr, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.assertStatement,
          isAwait: expr.isAwait,
        );
}

class ThrowStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitThrowStmt(this);

  final ASTNode message;

  ThrowStmt(
    this.message, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.throwStatement,
          isAwait: message.isAwait,
          isBlock: message.isBlock,
        );
}

class ExprStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitExprStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    expr.accept(visitor);
  }

  final ASTNode expr;

  ExprStmt(
    this.expr, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.expressionStatement,
          isAwait: expr.isAwait,
          isBlock: expr.isBlock,
        );
}

class BlockStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBlockStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    for (final stmt in statements) {
      stmt.accept(visitor);
    }
  }

  final List<ASTNode> statements;

  final bool isCodeBlock;

  final String? id;

  BlockStmt(
    this.statements, {
    this.isCodeBlock = true,
    this.id,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.blockStatement,
          isAwait: statements.any((element) => element.isAwait),
          isBlock: true,
        );
}

class ReturnStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitReturnStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    value?.accept(visitor);
  }

  final Token keyword;

  final ASTNode? returnValue;

  ReturnStmt(
    this.keyword, {
    this.returnValue,
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.returnStatement,
          isAwait: returnValue?.isAwait ?? false,
          isBlock: returnValue?.isBlock ?? false,
        );
}

class WhileStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitWhileStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    condition.accept(visitor);
    loop.accept(visitor);
  }

  final ASTNode condition;

  final BlockStmt loop;

  WhileStmt(
    this.condition,
    this.loop, {
    super.isBlock,
    super.hasEndOfStmtMark,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.whileStatement,
          isAwait: condition.isAwait || loop.isAwait,
        );
}

class DoStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitDoStmt(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    loop.accept(visitor);
    condition?.accept(visitor);
  }

  final BlockStmt loop;

  final ASTNode? condition;

  DoStmt(
    this.loop,
    this.condition, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.doStatement,
          isAwait: loop.isAwait || (condition?.isAwait ?? false),
        );
}

class SwitchStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitSwitch(this);

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

  SwitchStmt(
    this.cases,
    this.elseBranch,
    this.condition, {
    super.isStatement = true,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.switchStatement,
          isAwait: (condition?.isAwait ?? false) ||
              (elseBranch?.isAwait ?? false) ||
              cases.keys.any((element) => element.isAwait) ||
              cases.values.any((element) => element.isAwait),
          isBlock: true,
        );
}

class BreakStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  BreakStmt(
    this.keyword, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.breakStatement);
}

class ContinueStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  ContinueStmt(
    this.keyword, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.continueStatement);
}

class DeleteStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitDeleteStmt(this);

  final String symbol;

  DeleteStmt(
    this.symbol, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.deleteStatement);
}

class DeleteMemberStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitDeleteMemberStmt(this);

  final ASTNode object;

  final String key;

  DeleteMemberStmt(
    this.object,
    this.key, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.deleteMemberStatement);
}

class DeleteSubStmt extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) =>
      visitor.visitDeleteSubStmt(this);

  final ASTNode object;

  final ASTNode key;

  DeleteSubStmt(
    this.object,
    this.key, {
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.deleteSubMemberStatement);
}

class ImportExportDecl extends Statement {
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

  /// The normalized absolute path of the imported file.
  /// It is left as null at the first time of parsing,
  /// because at this time we don't know yet.
  String? fullFromPath;

  ImportExportDecl({
    this.fromPath,
    this.alias,
    this.showList = const [],
    this.isPreloadedModule = false,
    this.isExport = false,
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(isExport
            ? InternalIdentifier.exportStatement
            : InternalIdentifier.importStatement);
}

class NamespaceDecl extends Statement {
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

  NamespaceDecl(
    this.id,
    this.definition, {
    this.classId,
    this.isPrivate = false,
    this.isTopLevel = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.namespaceDeclaration,
          isBlock: true,
        );
}

class TypeAliasDecl extends Statement {
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

  bool get isMember => classId != null;

  final bool isPrivate;

  final bool isTopLevel;

  TypeAliasDecl(
    this.id,
    this.typeValue, {
    this.classId,
    this.genericTypeParameters = const [],
    super.hasEndOfStmtMark = false,
    this.isPrivate = false,
    this.isTopLevel = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.typeAliasDeclaration);
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

//   ConstDecl(this.id, this.constExpr,
//       {this.declType,
//       this.classId,
//       this.hasEndOfStmtMark = false,
//       this.isTopLevel = false,
//       HTSource? source,
//       int line = 0,
//       int column = 0,
//       int offset = 0,
//       int length = 0,})
//       : super(InternalIdentifier.constantDeclaration,
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

  final bool isStructField;

  final bool isExternal;

  final bool isStatic;

  final bool isMutable;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isField;

  final bool lateFinalize;

  final bool lateInitialize;

  final bool hasEndOfStmtMark;

  VarDecl(
    this.id, {
    String? internalName,
    this.classId,
    this.declType,
    this.initializer,
    super.isStatement = true,
    this.hasEndOfStmtMark = false,
    // this.typeInferrence = false,
    this.isConst = false,
    this.isStructField = false,
    this.isExternal = false,
    this.isStatic = false,
    this.isMutable = false,
    this.isPrivate = false,
    this.isTopLevel = false,
    this.isField = false,
    this.lateFinalize = false,
    this.lateInitialize = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  })  : _internalName = internalName,
        super(InternalIdentifier.variableDeclaration);
}

class DestructuringDecl extends Statement {
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

  DestructuringDecl({
    required this.ids,
    required this.isVector,
    required this.initializer,
    this.isTopLevel = false,
    this.isMutable = false,
    super.hasEndOfStmtMark = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.destructuringDeclaration);
}

class ParamDecl extends VarDecl {
  @override
  String get type => InternalIdentifier.parameterDeclaration;

  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitParamDecl(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  final bool isInitialization;

  ParamDecl(
    super.id, {
    super.declType,
    super.initializer,
    this.isVariadic = false,
    this.isOptional = false,
    this.isNamed = false,
    this.isInitialization = false,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          isMutable: true,
          isStatement: false,
        );
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

  final bool hasEndOfStmtMark;

  RedirectingConstructorCallExpr(
    this.callee,
    this.positionalArgs,
    this.namedArgs, {
    this.hasEndOfStmtMark = false,
    this.key,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.redirectingConstructor);
}

class FuncDecl extends Statement {
  @override
  dynamic accept(AbstractASTVisitor visitor) => visitor.visitFuncDecl(this);

  @override
  void subAccept(AbstractASTVisitor visitor) {
    returnType?.accept(visitor);
    redirectingConstructorCall?.accept(visitor);
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

  final RedirectingConstructorCallExpr? redirectingConstructorCall;

  final bool hasParamDecls;

  final List<ParamDecl> paramDecls;

  final int minArity;

  final int maxArity;

  final bool isExpressionBody;

  final ASTNode? definition;

  bool get isAbstract => definition == null && !isExternal;

  final bool isAsync;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final bool isPrivate;

  final bool isTopLevel;

  final bool isField;

  final FunctionCategory category;

  FuncDecl(
    this.internalName, {
    this.id,
    this.classId,
    this.genericTypeParameters = const [],
    this.externalTypeId,
    this.redirectingConstructorCall,
    this.paramDecls = const [],
    this.hasParamDecls = true,
    this.returnType,
    this.minArity = 0,
    this.maxArity = 0,
    this.isExpressionBody = false,
    this.definition,
    this.isAsync = false,
    this.isExternal = false,
    this.isStatic = false,
    this.isConst = false,
    this.isVariadic = false,
    this.isPrivate = false,
    this.isTopLevel = false,
    this.isField = false,
    this.category = FunctionCategory.normal,
    super.isStatement,
    super.hasEndOfStmtMark,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.functionDeclaration,
          isBlock: (!isExpressionBody && definition != null),
        );
}

class ClassDecl extends Statement {
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

  ClassDecl(
    this.id,
    this.definition, {
    this.classId,
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
    super.hasEndOfStmtMark,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.classDeclaration,
          isStatement: true,
          isBlock: true,
        );
}

class EnumDecl extends Statement {
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

  EnumDecl(
    this.id,
    this.enumerations, {
    this.classId,
    this.isExternal = false,
    this.isPrivate = false,
    this.isTopLevel = false,
    super.hasEndOfStmtMark,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.enumDeclaration,
          isStatement: true,
          isBlock: true,
        );
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

  final List<IdentifierExpr> mixinIds;

  final List<ASTNode> definition;

  final bool isPrivate;

  final bool isTopLevel;

  // final bool lateInitialize;

  StructDecl(
    this.id,
    this.definition, {
    this.prototypeId,
    this.mixinIds = const [],
    this.isPrivate = false,
    this.isTopLevel = false,
    super.isStatement,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(
          InternalIdentifier.structDeclaration,
          isBlock: true,
        );
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

  bool get isSpread => key == null;

  final ASTNode fieldValue;

  StructObjField({
    this.key,
    required this.fieldValue,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalStructField);
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
    this.fields, {
    this.id,
    this.prototypeId,
    super.source,
    super.line = 0,
    super.column = 0,
    super.offset = 0,
    super.length = 0,
  }) : super(InternalIdentifier.literalStruct);
}
