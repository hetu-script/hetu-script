import '../implementation/token.dart';
import '../implementation/lexicon.dart';
import '../implementation/type.dart';
import '../common/constants.dart';

/// Visitor interface for a abstract syntactic tree node
abstract class AstNodeVisitor {
  dynamic visitNullExpr(NullExpr expr);

  dynamic visitBooleanExpr(BooleanExpr expr);

  dynamic visitConstIntExpr(ConstIntExpr expr);

  dynamic visitConstFloatExpr(ConstFloatExpr expr);

  dynamic visitConstStringExpr(ConstStringExpr expr);

  dynamic visitLiteralListExpr(LiteralVectorExpr expr);

  dynamic visitLiteralMapExpr(LiteralDictExpr expr);

  dynamic visitGroupExpr(GroupExpr expr);

  dynamic visitUnaryExpr(UnaryExpr expr);

  dynamic visitBinaryExpr(BinaryExpr expr);

  dynamic visitTernaryExpr(TernaryExpr expr);

  dynamic visitTypeExpr(TypeExpr expr);

  dynamic visitFunctionTypeExpr(FunctionTypeExpr expr);

  dynamic visitSymbolExpr(SymbolExpr expr);

  // dynamic visitAssignExpr(AssignExpr expr);

  dynamic visitSubGetExpr(SubGetExpr expr);

  // dynamic visitSubSetExpr(SubSetExpr expr);

  dynamic visitMemberGetExpr(MemberGetExpr expr);

  // dynamic visitMemberSetExpr(MemberSetExpr expr);

  dynamic visitCallExpr(CallExpr expr);

  dynamic visitExprStmt(ExprStmt stmt);

  dynamic visitBlockStmt(BlockStmt stmt);

  dynamic visitReturnStmt(ReturnStmt stmt);

  dynamic visitIfStmt(IfStmt stmt);

  dynamic visitWhileStmt(WhileStmt stmt);

  dynamic visitBreakStmt(BreakStmt stmt);

  dynamic visitContinueStmt(ContinueStmt stmt);

  dynamic visitVarDeclStmt(VarDeclStmt stmt);

  dynamic visitParamDeclStmt(ParamDeclStmt stmt);

  dynamic visitFuncDeclStmt(FuncDeclStmt stmt);

  dynamic visitClassDeclStmt(ClassDeclStmt stmt);

  dynamic visitEnumDeclStmt(EnumDeclStmt stmt);
}

abstract class AstNode {
  final String type;

  final String moduleFullName;
  final int line;
  final int column;

  /// 取表达式右值，返回值本身
  dynamic accept(AstNodeVisitor visitor);

  AstNode(this.type, this.moduleFullName, this.line, this.column);

  AstNode clone();
}

class NullExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr(String moduleFullName, int line, int column)
      : super(SemanticType.literalNullExpr, moduleFullName, line, column);

  @override
  AstNode clone() => NullExpr(moduleFullName, line, column);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  BooleanExpr(this.value, String moduleFullName, int line, int column)
      : super(SemanticType.literalBooleanExpr, moduleFullName, line, column);

  @override
  AstNode clone() => BooleanExpr(value, moduleFullName, line, column);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstIntExpr(this);

  final int constIndex;

  ConstIntExpr(this.constIndex, String moduleFullName, int line, int column)
      : super(SemanticType.literalIntExpr, moduleFullName, line, column);

  @override
  AstNode clone() => ConstIntExpr(constIndex, moduleFullName, line, column);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstFloatExpr(this);

  final int constIndex;

  ConstFloatExpr(this.constIndex, String moduleFullName, int line, int column)
      : super(SemanticType.literalFloatExpr, moduleFullName, line, column);

  @override
  AstNode clone() => ConstFloatExpr(constIndex, moduleFullName, line, column);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstStringExpr(this);

  final int constIndex;

  ConstStringExpr(this.constIndex, String moduleFullName, int line, int column)
      : super(SemanticType.literalStringExpr, moduleFullName, line, column);

  @override
  AstNode clone() => ConstStringExpr(constIndex, moduleFullName, line, column);
}

class LiteralVectorExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitLiteralListExpr(this);

  final List<AstNode> vector;

  LiteralVectorExpr(String moduleFullName, int line, int column,
      [this.vector = const []])
      : super(SemanticType.literalVectorExpr, moduleFullName, line, column);

  @override
  AstNode clone() {
    var new_list = <AstNode>[];
    for (final expr in vector) {
      new_list.add(expr.clone());
    }
    return LiteralVectorExpr(moduleFullName, line, column, new_list);
  }
}

class LiteralDictExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitLiteralMapExpr(this);

  final Map<AstNode, AstNode> map;

  LiteralDictExpr(String moduleFullName, int line, int column,
      [this.map = const {}])
      : super(SemanticType.blockExpr, moduleFullName, line, column);

  @override
  AstNode clone() {
    var new_map = <AstNode, AstNode>{};
    for (final expr in map.keys) {
      new_map[expr.clone()] = map[expr]!.clone();
    }
    return LiteralDictExpr(moduleFullName, line, column, new_map);
  }
}

class GroupExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitGroupExpr(this);

  final AstNode inner;

  GroupExpr(this.inner)
      : super(SemanticType.groupExpr, inner.moduleFullName, inner.line,
            inner.column);

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
      : super(SemanticType.unaryExpr, op.moduleFullName, op.line, op.column);

  @override
  AstNode clone() => UnaryExpr(op, value.clone());
}

class BinaryExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBinaryExpr(this);

  final AstNode left;

  late final String op;

  final AstNode right;

  BinaryExpr(this.left, this.op, this.right)
      : super(SemanticType.binaryExpr, left.moduleFullName, left.line,
            left.column);

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
      : super(SemanticType.binaryExpr, condition.moduleFullName, condition.line,
            condition.column);

  @override
  AstNode clone() => TernaryExpr(condition, thenBranch, elseBranch);
}

class TypeExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitTypeExpr(this);

  final String id;

  final List<TypeExpr> arguments;

  TypeExpr(this.id, this.arguments, String moduleFullName, int line, int column)
      : super(SemanticType.typeExpr, moduleFullName, line, column);

  @override
  AstNode clone() => TypeExpr(id, arguments, moduleFullName, line, column);
}

class FunctionTypeExpr extends TypeExpr {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitFunctionTypeExpr(this);

  FunctionTypeExpr(String id, List<TypeExpr> arguments, String moduleFullName,
      int line, int column)
      : super(id, arguments, moduleFullName, line, column);

  @override
  AstNode clone() =>
      FunctionTypeExpr(id, arguments, moduleFullName, line, column);
}

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitSymbolExpr(this);

  final Token id;

  SymbolExpr(this.id)
      : super(SemanticType.symbolExpr, id.moduleFullName, id.line, id.column);

  @override
  AstNode clone() => SymbolExpr(id);
}

class SubGetExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final AstNode collection;

  /// 索引
  final AstNode key;

  SubGetExpr(this.collection, this.key)
      : super(SemanticType.subGetExpr, collection.moduleFullName,
            collection.line, collection.column);

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
//       : super(SemanticType.subSetExpr, collection.moduleFullName,
//             collection.line, collection.column);

//   @override
//   AstNode clone() => SubSetExpr(collection, key, value);
// }

class MemberGetExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitMemberGetExpr(this);

  /// 集合
  final AstNode collection;

  /// 属性
  final Token key;

  MemberGetExpr(this.collection, this.key)
      : super(SemanticType.memberGetExpr, collection.moduleFullName,
            collection.line, collection.column);

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
//       : super(SemanticType.memberSetExpr, collection.moduleFullName,
//             collection.line, collection.column);

//   @override
//   AstNode clone() => MemberSetExpr(collection, key, value);
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
      : super(SemanticType.callExpr, callee.moduleFullName, callee.line,
            callee.column);

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

class ExprStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final AstNode expr;

  ExprStmt(this.expr)
      : super(
            SemanticType.exprStmt, expr.moduleFullName, expr.line, expr.column);

  @override
  AstNode clone() => ExprStmt(expr.clone());
}

class BlockStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBlockStmt(this);

  final List<AstNode> statements;

  BlockStmt(this.statements, String moduleFullName, int line, int column)
      : super(SemanticType.blockStmt, moduleFullName, line, column);

  @override
  AstNode clone() {
    var new_list = <AstNode>[];
    for (final expr in statements) {
      new_list.add(expr.clone());
    }
    return BlockStmt(new_list, moduleFullName, line, column);
  }
}

class ReturnStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final AstNode? value;

  ReturnStmt(this.keyword, this.value)
      : super(SemanticType.returnStmt, keyword.moduleFullName, keyword.line,
            keyword.column);

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
      : super(SemanticType.ifStmt, condition.moduleFullName, condition.line,
            condition.column);

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
      : super(SemanticType.whileStmt, condition.moduleFullName, condition.line,
            condition.column);

  @override
  AstNode clone() =>
      WhileStmt(condition.clone(), loop?.clone(), isDoStmt: isDoStmt);
}

class BreakStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  BreakStmt(this.keyword)
      : super(SemanticType.breakStmt, keyword.moduleFullName, keyword.line,
            keyword.column);

  @override
  AstNode clone() => BreakStmt(keyword);
}

class ContinueStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  ContinueStmt(this.keyword)
      : super(SemanticType.continueStmt, keyword.moduleFullName, keyword.line,
            keyword.column);

  @override
  AstNode clone() => ContinueStmt(keyword);
}

class VarDeclStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitVarDeclStmt(this);

  final String id;

  final HTType? declType;

  final AstNode? initializer;

  final bool isDynamic;

  // 仅用于整个class都为external的情况
  final bool isExternal;

  final bool isImmutable;

  final bool isStatic;

  VarDeclStmt(this.id, String moduleFullName, int line, int column,
      {this.declType,
      this.initializer,
      this.isDynamic = false,
      this.isExternal = false,
      this.isImmutable = false,
      this.isStatic = false})
      : super(SemanticType.varDeclStmt, moduleFullName, line, column);

  @override
  AstNode clone() => VarDeclStmt(id, moduleFullName, line, column,
      declType: declType,
      initializer: initializer,
      isExternal: isExternal,
      isImmutable: isImmutable,
      isStatic: isStatic);
}

class ParamDeclStmt extends VarDeclStmt {
  @override
  final type = SemanticType.paramStmt;

  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitParamDeclStmt(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  ParamDeclStmt(String id, String moduleFullName, int line, int column,
      {HTType? declType,
      AstNode? initializer,
      bool isImmutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false})
      : super(id, moduleFullName, line, column,
            declType: declType,
            initializer: initializer,
            isImmutable: isImmutable);

  @override
  AstNode clone() => ParamDeclStmt(id, moduleFullName, line, column,
      declType: declType,
      initializer: initializer,
      isImmutable: isImmutable,
      isVariadic: isVariadic,
      isOptional: isOptional,
      isNamed: isNamed);
}

class FuncDeclStmt extends AstNode {
  static int functionIndex = 0;

  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final Token? id;

  final List<String> typeParameters;

  final HTType returnType;

  late final String _internalName;
  String get internalName => _internalName;

  final String? classId;
  // final HTType? classType;

  final List<ParamDeclStmt> params;

  final int arity;

  final List<AstNode>? definition;

  final bool isExternal;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final FunctionType funcType;

  FuncDeclStmt(
      this.returnType, this.params, String moduleFullName, int line, int column,
      {this.id,
      this.classId,
      this.typeParameters = const [],
      this.arity = 0,
      this.definition,
      this.isExternal = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.funcType = FunctionType.normal})
      : super(SemanticType.funcDeclStmt, moduleFullName, line, column) {
    var func_name = id?.lexeme ??
        HTLexicon.anonymousFunction + (functionIndex++).toString();

    if (funcType == FunctionType.constructor) {
      (id != null)
          ? _internalName = '$classId.$func_name'
          : _internalName = '$classId';
    } else if (funcType == FunctionType.getter) {
      _internalName = HTLexicon.getter + func_name;
    } else if (funcType == FunctionType.setter) {
      _internalName = HTLexicon.setter + func_name;
    } else {
      _internalName = func_name;
    }
  }

  @override
  AstNode clone() {
    var new_params = <ParamDeclStmt>[];
    for (final expr in params) {
      new_params.add(expr.clone() as ParamDeclStmt);
    }

    var new_body;
    if (definition != null) {
      new_body = <AstNode>[];
      for (final expr in definition!) {
        new_body.add(expr.clone());
      }
    }

    return FuncDeclStmt(returnType, new_params, moduleFullName, line, column,
        id: id,
        classId: classId,
        typeParameters: typeParameters,
        arity: arity,
        definition: new_body,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        funcType: funcType);
  }
}

class ClassDeclStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitClassDeclStmt(this);

  final Token id;

  final bool isExternal;

  final bool isAbstract;

  final List<VarDeclStmt> variables;

  final List<FuncDeclStmt> methods;

  final List<String> typeParameters;

  final SymbolExpr? superClass;

  final ClassDeclStmt? superClassDeclStmt;

  final HTType? superClassTypeArgs;

  ClassDeclStmt(this.id, this.variables, this.methods,
      {this.isExternal = false,
      this.isAbstract = false,
      this.typeParameters = const [],
      this.superClass,
      this.superClassDeclStmt,
      this.superClassTypeArgs})
      : super(
            SemanticType.classDeclStmt, id.moduleFullName, id.line, id.column);

  @override
  AstNode clone() {
    var new_vars = <VarDeclStmt>[];
    for (final expr in variables) {
      new_vars.add(expr.clone() as VarDeclStmt);
    }

    var new_methods = <FuncDeclStmt>[];
    for (final expr in methods) {
      new_methods.add(expr.clone() as FuncDeclStmt);
    }

    return ClassDeclStmt(id, new_vars, new_methods,
        isExternal: isExternal,
        isAbstract: isAbstract,
        typeParameters: typeParameters,
        superClass: superClass,
        superClassDeclStmt: superClassDeclStmt,
        superClassTypeArgs: superClassTypeArgs);
  }
}

class EnumDeclStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitEnumDeclStmt(this);

  final Token id;

  final List<String> enumerations;

  final bool isExternal;

  EnumDeclStmt(this.id, this.enumerations, {this.isExternal = false})
      : super(SemanticType.enumDeclStmt, id.moduleFullName, id.line, id.column);

  @override
  AstNode clone() => EnumDeclStmt(id, enumerations, isExternal: isExternal);
}
