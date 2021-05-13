import '../core/token.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';

/// Visitor interface for a abstract syntactic tree node
abstract class AstNodeVisitor {
  dynamic visitNullExpr(NullExpr expr);

  dynamic visitBooleanExpr(BooleanExpr expr);

  dynamic visitConstIntExpr(ConstIntExpr expr);

  dynamic visitConstFloatExpr(ConstFloatExpr expr);

  dynamic visitConstStringExpr(ConstStringExpr expr);

  dynamic visitLiteralListExpr(LiteralListExpr expr);

  dynamic visitLiteralMapExpr(LiteralMapExpr expr);

  dynamic visitGroupExpr(GroupExpr expr);

  dynamic visitUnaryExpr(UnaryExpr expr);

  dynamic visitBinaryExpr(BinaryExpr expr);

  dynamic visitTernaryExpr(TernaryExpr expr);

  dynamic visitTypeExpr(TypeExpr expr);

  dynamic visitParamTypeExpr(ParamTypeExpr expr);

  dynamic visitFunctionTypeExpr(FunctionTypeExpr expr);

  dynamic visitSymbolExpr(SymbolExpr expr);

  // dynamic visitAssignExpr(AssignExpr expr);

  dynamic visitSubGetExpr(SubGetExpr expr);

  // dynamic visitSubSetExpr(SubSetExpr expr);

  dynamic visitMemberGetExpr(MemberGetExpr expr);

  // dynamic visitMemberSetExpr(MemberSetExpr expr);

  dynamic visitCallExpr(CallExpr expr);

  dynamic visitUnaryPostfixExpr(UnaryPostfixExpr expr);

  dynamic visitExprStmt(ExprStmt stmt);

  dynamic visitBlockStmt(BlockStmt stmt);

  dynamic visitReturnStmt(ReturnStmt stmt);

  dynamic visitIfStmt(IfStmt stmt);

  dynamic visitWhileStmt(WhileStmt stmt);

  dynamic visitBreakStmt(BreakStmt stmt);

  dynamic visitContinueStmt(ContinueStmt stmt);

  dynamic visitVarDeclStmt(VarDecl stmt);

  dynamic visitParamDeclStmt(ParamDecl stmt);

  dynamic visitFuncDeclStmt(FuncDecl stmt);

  dynamic visitClassDeclStmt(ClassDecl stmt);

  dynamic visitEnumDeclStmt(EnumDecl stmt);
}

abstract class AstNode {
  final String type;

  final int line;
  final int column;

  /// 取表达式右值，返回值本身
  dynamic accept(AstNodeVisitor visitor);

  AstNode(this.type, this.line, this.column);

  AstNode clone();
}

class NullExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr(int line, int column)
      : super(SemanticType.literalNullExpr, line, column);

  @override
  AstNode clone() => NullExpr(line, column);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  BooleanExpr(this.value, int line, int column)
      : super(SemanticType.literalBooleanExpr, line, column);

  @override
  AstNode clone() => BooleanExpr(value, line, column);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstIntExpr(this);

  final int constIndex;

  ConstIntExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalIntExpr, line, column);

  @override
  AstNode clone() => ConstIntExpr(constIndex, line, column);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstFloatExpr(this);

  final int constIndex;

  ConstFloatExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalFloatExpr, line, column);

  @override
  AstNode clone() => ConstFloatExpr(constIndex, line, column);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstStringExpr(this);

  final int constIndex;

  ConstStringExpr(this.constIndex, int line, int column)
      : super(SemanticType.literalStringExpr, line, column);

  @override
  AstNode clone() => ConstStringExpr(constIndex, line, column);
}

class LiteralListExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitLiteralListExpr(this);

  final Iterable<AstNode> vector;

  LiteralListExpr(int line, int column, [this.vector = const []])
      : super(SemanticType.literalVectorExpr, line, column);

  @override
  AstNode clone() {
    var new_list = <AstNode>[];
    for (final expr in vector) {
      new_list.add(expr.clone());
    }
    return LiteralListExpr(line, column, new_list);
  }
}

class LiteralMapExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitLiteralMapExpr(this);

  final Map<AstNode, AstNode> map;

  LiteralMapExpr(int line, int column, [this.map = const {}])
      : super(SemanticType.blockExpr, line, column);

  @override
  AstNode clone() {
    var new_map = <AstNode, AstNode>{};
    for (final expr in map.keys) {
      new_map[expr.clone()] = map[expr]!.clone();
    }
    return LiteralMapExpr(line, column, new_map);
  }
}

class GroupExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitGroupExpr(this);

  final AstNode inner;

  GroupExpr(this.inner)
      : super(SemanticType.groupExpr, inner.line, inner.column);

  @override
  AstNode clone() => GroupExpr(inner.clone());
}

class UnaryExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitUnaryExpr(this);

  /// 各种单目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final AstNode value;

  UnaryExpr(this.op, this.value)
      : super(SemanticType.unaryExpr, op.line, op.column);

  @override
  AstNode clone() => UnaryExpr(op, value.clone());
}

class BinaryExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBinaryExpr(this);

  final AstNode left;

  final String op;

  final AstNode right;

  BinaryExpr(this.left, this.op, this.right)
      : super(SemanticType.binaryExpr, left.line, left.column);

  @override
  AstNode clone() => BinaryExpr(left, op, right);
}

class TernaryExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitTernaryExpr(this);

  final AstNode condition;

  final AstNode thenBranch;

  final AstNode elseBranch;

  TernaryExpr(this.condition, this.thenBranch, this.elseBranch)
      : super(SemanticType.binaryExpr, condition.line, condition.column);

  @override
  AstNode clone() => TernaryExpr(condition, thenBranch, elseBranch);
}

class TypeExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitTypeExpr(this);

  final String id;

  final List<TypeExpr> arguments;

  final bool isNullable;

  TypeExpr(this.id, int line, int column,
      {this.arguments = const [], this.isNullable = false})
      : super(SemanticType.typeExpr, line, column);

  @override
  AstNode clone() =>
      TypeExpr(id, line, column, arguments: arguments, isNullable: isNullable);
}

class ParamTypeExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitParamTypeExpr(this);

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

  @override
  AstNode clone() => ParamTypeExpr(paramType, line, column,
      paramId: paramId,
      isOptional: isOptional,
      isNamed: isNamed,
      isVariadic: isVariadic);
}

class FunctionTypeExpr extends TypeExpr {
  final List<TypeExpr> genericTypeParameters;
  final List<ParamTypeExpr> parameterTypes;
  final TypeExpr returnType;

  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitFunctionTypeExpr(this);

  FunctionTypeExpr(this.returnType, int line, int column,
      {this.genericTypeParameters = const [], this.parameterTypes = const []})
      : super(HTLexicon.function, line, column);

  @override
  AstNode clone() => FunctionTypeExpr(returnType, line, column,
      genericTypeParameters: genericTypeParameters,
      parameterTypes: parameterTypes);
}

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitSymbolExpr(this);

  final Token id;

  SymbolExpr(this.id) : super(SemanticType.symbolExpr, id.line, id.column);

  @override
  AstNode clone() => SymbolExpr(id);
}

class MemberGetExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitMemberGetExpr(this);

  /// 集合
  final AstNode collection;

  /// 属性
  final Token key;

  MemberGetExpr(this.collection, this.key)
      : super(SemanticType.memberGetExpr, collection.line, collection.column);

  @override
  AstNode clone() => MemberGetExpr(collection, key);
}

// class MemberSetExpr extends AstNode {
//   @override
//   dynamic accept(AstNodeVisitor visitor) => visitor.visitMemberSetExpr(this);

//   /// 集合
//   final AstNode collection;

//   /// 属性
//   final Token key;

//   /// 值
//   final AstNode value;

//   MemberSetExpr(this.collection, this.key, this.value)
//       : super(SemanticType.memberSetExpr, collection.
//             collection.line, collection.column);

//   @override
//   AstNode clone() => MemberSetExpr(collection, key, value);
// }

class SubGetExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final AstNode collection;

  /// 索引
  final AstNode key;

  SubGetExpr(this.collection, this.key)
      : super(SemanticType.subGetExpr, collection.line, collection.column);

  @override
  AstNode clone() => SubGetExpr(collection, key);
}

// class SubSetExpr extends AstNode {
//   @override
//   dynamic accept(AstNodeVisitor visitor) => visitor.visitSubSetExpr(this);

//   /// 数组
//   final AstNode collection;

//   /// 索引
//   final AstNode key;

//   /// 值
//   final AstNode value;

//   SubSetExpr(this.collection, this.key, this.value)
//       : super(SemanticType.subSetExpr, collection.
//             collection.line, collection.column);

//   @override
//   AstNode clone() => SubSetExpr(collection, key, value);
// }

class CallExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitCallExpr(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode callee;

  /// 函数声明的参数是parameter，调用时传入的变量叫argument
  final List<AstNode> positionalArgs;

  final Map<String, AstNode> namedArgs;

  CallExpr(this.callee, this.positionalArgs, this.namedArgs)
      : super(SemanticType.callExpr, callee.line, callee.column);

  @override
  AstNode clone() {
    var new_args = <AstNode>[];
    for (final expr in positionalArgs) {
      new_args.add(expr.clone());
    }

    var new_named_args = <String, AstNode>{};
    for (final name in namedArgs.keys) {
      new_named_args[name] = namedArgs[name]!.clone();
    }

    return CallExpr(callee.clone(), new_args, new_named_args);
  }
}

class UnaryPostfixExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitUnaryPostfixExpr(this);

  final AstNode value;

  final Token op;

  UnaryPostfixExpr(this.value, this.op)
      : super(SemanticType.unaryExpr, op.line, op.column);

  @override
  AstNode clone() => UnaryPostfixExpr(value.clone(), op);
}

class ExprStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode expr;

  ExprStmt(this.expr) : super(SemanticType.exprStmt, expr.line, expr.column);

  @override
  AstNode clone() => ExprStmt(expr.clone());
}

class BlockStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBlockStmt(this);

  final Iterable<AstNode> statements;

  BlockStmt(this.statements, int line, int column)
      : super(SemanticType.blockStmt, line, column);

  @override
  AstNode clone() {
    var new_list = <AstNode>[];
    for (final expr in statements) {
      new_list.add(expr.clone());
    }
    return BlockStmt(new_list, line, column);
  }
}

class ReturnStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final AstNode? value;

  ReturnStmt(this.keyword, this.value)
      : super(SemanticType.returnStmt, keyword.line, keyword.column);

  @override
  AstNode clone() => ReturnStmt(keyword, value?.clone());
}

class IfStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitIfStmt(this);

  final AstNode condition;

  final AstNode? thenBranch;

  final AstNode? elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch)
      : super(SemanticType.ifStmt, condition.line, condition.column);

  @override
  AstNode clone() =>
      IfStmt(condition.clone(), thenBranch?.clone(), elseBranch?.clone());
}

class WhileStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitWhileStmt(this);

  final AstNode condition;

  final AstNode? loop;

  final bool isDoStmt;

  WhileStmt(this.condition, this.loop, {this.isDoStmt = false})
      : super(SemanticType.whileStmt, condition.line, condition.column);

  @override
  AstNode clone() =>
      WhileStmt(condition.clone(), loop?.clone(), isDoStmt: isDoStmt);
}

class BreakStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  BreakStmt(this.keyword)
      : super(SemanticType.breakStmt, keyword.line, keyword.column);

  @override
  AstNode clone() => BreakStmt(keyword);
}

class ContinueStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  ContinueStmt(this.keyword)
      : super(SemanticType.continueStmt, keyword.line, keyword.column);

  @override
  AstNode clone() => ContinueStmt(keyword);
}

class VarDecl extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitVarDeclStmt(this);

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

  @override
  AstNode clone() => VarDecl(id, line, column,
      declType: declType,
      initializer: initializer,
      isExternal: isExternal,
      isImmutable: isImmutable,
      isStatic: isStatic);
}

class ParamDecl extends VarDecl {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitParamDeclStmt(this);

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

  @override
  AstNode clone() => ParamDecl(id, line, column,
      declType: declType,
      initializer: initializer,
      isImmutable: isImmutable,
      isVariadic: isVariadic,
      isOptional: isOptional,
      isNamed: isNamed);
}

class FuncDecl extends AstNode {
  static int functionIndex = 0;

  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final Token? id;

  final Iterable<String> typeParameters;

  final TypeExpr? returnType;

  late final String _internalName;
  String get internalName => _internalName;

  final String? classId;
  // final HTType? classType;

  final List<ParamDecl> params;

  final int arity;

  final Iterable<AstNode>? definition;

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

  @override
  AstNode clone() {
    var new_params = <ParamDecl>[];
    for (final expr in params) {
      new_params.add(expr.clone() as ParamDecl);
    }

    var new_body;
    if (definition != null) {
      new_body = <AstNode>[];
      for (final expr in definition!) {
        new_body.add(expr.clone());
      }
    }

    return FuncDecl(new_params, line, column,
        id: id,
        classId: classId,
        returnType: returnType,
        typeParameters: typeParameters,
        arity: arity,
        definition: new_body,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        category: category);
  }
}

class ClassDecl extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitClassDeclStmt(this);

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

  @override
  AstNode clone() {
    var new_vars = <VarDecl>[];
    for (final expr in variables) {
      new_vars.add(expr.clone() as VarDecl);
    }

    var new_methods = <FuncDecl>[];
    for (final expr in methods) {
      new_methods.add(expr.clone() as FuncDecl);
    }

    return ClassDecl(id, new_vars, new_methods,
        isExternal: isExternal,
        isAbstract: isAbstract,
        typeParameters: typeParameters,
        superClass: superClass,
        superClassDeclStmt: superClassDeclStmt,
        superClassTypeArgs: superClassTypeArgs);
  }
}

class EnumDecl extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitEnumDeclStmt(this);

  final Token id;

  final Iterable<String> enumerations;

  final bool isExternal;

  EnumDecl(this.id, this.enumerations, {this.isExternal = false})
      : super(SemanticType.enumDecl, id.line, id.column);

  @override
  AstNode clone() => EnumDecl(id, enumerations, isExternal: isExternal);
}
