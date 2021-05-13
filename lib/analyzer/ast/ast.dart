import '../../core/token.dart';
import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';

part 'abstract_ast_visitor.dart';

abstract class AstNode {
  final String type;

  final int line;
  final int column;

  /// 取表达式右值，返回值本身
  dynamic accept(AbstractAstVisitor visitor);

  AstNode(this.type, this.line, this.column);
}

class NullExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr(int line, int column)
      : super(SemanticType.literalNullExpr, line, column);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  BooleanExpr(this.value, int line, int column)
      : super(SemanticType.literalBooleanExpr, line, column);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitConstIntExpr(this);

  final int constIndex;

  ConstIntExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalIntExpr, line, column);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstFloatExpr(this);

  final int constIndex;

  ConstFloatExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalFloatExpr, line, column);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitConstStringExpr(this);

  final int constIndex;

  ConstStringExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalStringExpr, line, column);
}

class LiteralListExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitLiteralListExpr(this);

  final Iterable<AstNode> vector;

  LiteralListExpr(int line, int column, [this.vector = const []])
      : super(SemanticType.literalVectorExpr, line, column);
}

class LiteralMapExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitLiteralMapExpr(this);

  final Map<AstNode, AstNode> map;

  LiteralMapExpr(int line, int column, [this.map = const {}])
      : super(SemanticType.blockExpr, line, column);
}

class GroupExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitGroupExpr(this);

  final AstNode inner;

  GroupExpr(this.inner)
      : super(SemanticType.groupExpr, inner.line, inner.column);
}

class UnaryExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitUnaryExpr(this);

  /// 各种单目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final AstNode value;

  UnaryExpr(this.op, this.value)
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

class ParamTypeExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitParamTypeExpr(this);

  final TypeExpr paramType;

  final String paramId;

  /// Wether this is an optional parameter.
  final bool isOptional;

  /// Wether this is a named parameter.
  final bool isNamed;

  /// Wether this is a variadic parameter.
  final bool isVariadic;

  ParamTypeExpr(this.paramType, int line, int column,
      {this.paramId = '',
      this.isOptional = false,
      this.isNamed = false,
      this.isVariadic = false})
      : super(SemanticType.paramTypeExpr, line, column);
}

class FunctionTypeExpr extends TypeExpr {
  final List<TypeExpr> genericTypeParameters;
  final List<ParamTypeExpr> parameterTypes;
  final TypeExpr returnType;

  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitFunctionTypeExpr(this);

  FunctionTypeExpr(this.returnType, int line, int column,
      {this.genericTypeParameters = const [], this.parameterTypes = const []})
      : super(HTLexicon.function, line, column);
}

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitSymbolExpr(this);

  final Token id;

  SymbolExpr(this.id) : super(SemanticType.symbolExpr, id.line, id.column);
}

class MemberGetExpr extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitMemberGetExpr(this);

  /// 集合
  final AstNode collection;

  /// 属性
  final Token key;

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

class ExprStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode expr;

  ExprStmt(this.expr) : super(SemanticType.exprStmt, expr.line, expr.column);
}

class BlockStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitBlockStmt(this);

  final String id;

  final Iterable<AstNode> statements;

  final bool createNamespace;

  BlockStmt(this.id, this.statements, int line, int column,
      {this.createNamespace = true})
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

  final AstNode? thenBranch;

  final AstNode? elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch)
      : super(SemanticType.ifStmt, condition.line, condition.column);
}

class WhileStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitWhileStmt(this);

  final AstNode condition;

  final AstNode? loop;

  WhileStmt(this.condition, this.loop)
      : super(SemanticType.whileStmt, condition.line, condition.column);
}

class DoStmt extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitDoStmt(this);

  final AstNode loop;

  final AstNode? condition;

  DoStmt(this.loop, this.condition)
      : super(SemanticType.doStmt, loop.line, loop.column);
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

  final bool isDynamic;

  // 仅用于整个class都为external的情况
  final bool isExternal;

  final bool isImmutable;

  final bool isStatic;

  VarDecl(this.id, int line, int column,
      {this.declType,
      this.initializer,
      this.isDynamic = false,
      this.isExternal = false,
      this.isImmutable = false,
      this.isStatic = false})
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

class FuncDecl extends AstNode {
  static int functionIndex = 0;

  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final Token? id;

  final Iterable<String> typeParameters;

  final TypeExpr? returnType;

  late final String _internalName;
  String get internalName => _internalName;

  final String? classId;
  // final HTType? classType;

  final List<ParamDecl> params;

  final int arity;

  final BlockStmt? definition;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final FunctionCategory category;

  FuncDecl(this.params, int line, int column,
      {this.id,
      this.classId,
      this.typeParameters = const [],
      this.returnType,
      this.arity = 0,
      this.definition,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.category = FunctionCategory.normal})
      : super(SemanticType.funcDecl, line, column) {
    var func_name = id?.lexeme ??
        HTLexicon.anonymousFunction + (functionIndex++).toString();

    if (category == FunctionCategory.constructor) {
      (id != null)
          ? _internalName = '$classId.$func_name'
          : _internalName = '$classId';
    } else if (category == FunctionCategory.getter) {
      _internalName = HTLexicon.getter + func_name;
    } else if (category == FunctionCategory.setter) {
      _internalName = HTLexicon.setter + func_name;
    } else {
      _internalName = func_name;
    }
  }
}

class ClassDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) =>
      visitor.visitClassDeclStmt(this);

  final Token id;

  final bool isExternal;

  final bool isAbstract;

  final Iterable<VarDecl> variables;

  final Iterable<FuncDecl> methods;

  final Iterable<String> typeParameters;

  final SymbolExpr? superClass;

  final ClassDecl? superClassDeclStmt;

  final TypeExpr? superClassTypeArgs;

  ClassDecl(this.id, this.variables, this.methods,
      {this.isExternal = false,
      this.isAbstract = false,
      this.typeParameters = const [],
      this.superClass,
      this.superClassDeclStmt,
      this.superClassTypeArgs})
      : super(SemanticType.classDecl, id.line, id.column);
}

class EnumDecl extends AstNode {
  @override
  dynamic accept(AbstractAstVisitor visitor) => visitor.visitEnumDeclStmt(this);

  final Token id;

  final Iterable<String> enumerations;

  final bool isExternal;

  EnumDecl(this.id, this.enumerations, {this.isExternal = false})
      : super(SemanticType.enumDecl, id.line, id.column);
}
