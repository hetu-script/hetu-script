import '../implementation/token.dart';
import '../implementation/lexicon.dart';
import '../implementation/type.dart';
import '../common/constants.dart';

/// Visitor interface for a abstract syntactic tree node
abstract class AstNodeVisitor {
  /// Null
  dynamic visitNullExpr(NullExpr expr);

  // 布尔
  dynamic visitBooleanExpr(BooleanExpr expr);

  /// 数字常量
  dynamic visitConstIntExpr(ConstIntExpr expr);

  /// 数字常量
  dynamic visitConstFloatExpr(ConstFloatExpr expr);

  /// 字符串常量
  dynamic visitConstStringExpr(ConstStringExpr expr);

  /// 数组字面量
  dynamic visitLiteralVectorExpr(LiteralVectorExpr expr);

  /// 字典字面量
  dynamic visitLiteralDictExpr(LiteralDictExpr expr);

  /// 圆括号表达式
  dynamic visitGroupExpr(GroupExpr expr);

  /// 单目表达式
  dynamic visitUnaryExpr(UnaryExpr expr);

  /// 双目表达式
  dynamic visitBinaryExpr(BinaryExpr expr);

  /// 类型名
  // dynamic visitTypeExpr(TypeExpr expr);

  /// 变量名
  dynamic visitSymbolExpr(SymbolExpr expr);

  /// 赋值表达式，返回右值，执行顺序优先右边
  ///
  /// 因此，a = b = c 解析为 a = (b = c)
  dynamic visitAssignExpr(AssignExpr expr);

  /// 下标取值表达式
  dynamic visitSubGetExpr(SubGetExpr expr);

  /// 下标赋值表达式
  dynamic visitSubSetExpr(SubSetExpr expr);

  /// 属性取值表达式
  dynamic visitMemberGetExpr(MemberGetExpr expr);

  /// 属性赋值表达式
  dynamic visitMemberSetExpr(MemberSetExpr expr);

  /// 函数调用表达式，即便返回值是void的函数仍然还是表达式
  dynamic visitCallExpr(CallExpr expr);

  /// This表达式
  dynamic visitThisExpr(ThisExpr expr);

  /// 导入语句
  dynamic visitImportStmt(ImportStmt stmt);

  /// 表达式语句
  dynamic visitExprStmt(ExprStmt stmt);

  /// 语句块：用于既允许单条语句，又允许语句块的场合，比如IfStatment
  dynamic visitBlockStmt(BlockStmt stmt);

  /// 返回语句
  dynamic visitReturnStmt(ReturnStmt stmt);

  /// If语句
  dynamic visitIfStmt(IfStmt stmt);

  /// While语句
  dynamic visitWhileStmt(WhileStmt stmt);

  /// Break语句
  dynamic visitBreakStmt(BreakStmt stmt);

  /// Continue语句
  dynamic visitContinueStmt(ContinueStmt stmt);

  /// 变量声明语句
  dynamic visitVarDeclStmt(VarDeclStmt stmt);

  /// 参数声明语句
  dynamic visitParamDeclStmt(ParamDeclStmt stmt);

  /// 函数声明和定义
  dynamic visitFuncDeclStmt(FuncDeclStmt stmt);

  /// 类
  dynamic visitClassDeclStmt(ClassDeclStmt stmt);

  /// 枚举类
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt);

  /// Parse result of a single script file, root for analyze
  dynamic visitAstModule(AstModule module);
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

  NullExpr(String fileName, int line, int column)
      : super(SemanticType.literalNullExpr, fileName, line, column);

  @override
  AstNode clone() => NullExpr(moduleFullName, line, column);
}

class BooleanExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  BooleanExpr(this.value, String fileName, int line, int column)
      : super(SemanticType.literalBooleanExpr, fileName, line, column);

  @override
  AstNode clone() => BooleanExpr(value, moduleFullName, line, column);
}

class ConstIntExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstIntExpr(this);

  final int constIndex;

  ConstIntExpr(this.constIndex, String fileName, int line, int column)
      : super(SemanticType.literalIntExpr, fileName, line, column);

  @override
  AstNode clone() => ConstIntExpr(constIndex, moduleFullName, line, column);
}

class ConstFloatExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstFloatExpr(this);

  final int constIndex;

  ConstFloatExpr(this.constIndex, String fileName, int line, int column)
      : super(SemanticType.literalFloatExpr, fileName, line, column);

  @override
  AstNode clone() => ConstFloatExpr(constIndex, moduleFullName, line, column);
}

class ConstStringExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitConstStringExpr(this);

  final int constIndex;

  ConstStringExpr(this.constIndex, String fileName, int line, int column)
      : super(SemanticType.literalStringExpr, fileName, line, column);

  @override
  AstNode clone() => ConstStringExpr(constIndex, moduleFullName, line, column);
}

class LiteralVectorExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) =>
      visitor.visitLiteralVectorExpr(this);

  final List<AstNode> vector;

  LiteralVectorExpr(String fileName, int line, int column,
      [this.vector = const []])
      : super(SemanticType.literalVectorExpr, fileName, line, column);

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
  dynamic accept(AstNodeVisitor visitor) => visitor.visitLiteralDictExpr(this);

  final Map<AstNode, AstNode> map;

  LiteralDictExpr(String fileName, int line, int column, [this.map = const {}])
      : super(SemanticType.blockExpr, fileName, line, column);

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
      : super(SemanticType.unaryExpr, op.fileName, op.line, op.column);

  @override
  AstNode clone() => UnaryExpr(op, value.clone());
}

class BinaryExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBinaryExpr(this);

  /// 左值
  final AstNode left;

  /// 各种双目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final AstNode right;

  BinaryExpr(this.left, this.op, this.right)
      : super(SemanticType.binaryExpr, op.fileName, op.line, op.column);

  @override
  AstNode clone() => BinaryExpr(left.clone(), op, right.clone());
}

// class TypeExpr extends Expr {
//   @override
//   final String type = env.lexicon.VarExpr;

//   @override
//   dynamic accept(ExprVisitor visitor) => visitor.visitTypeExpr(this);

//   final Token name;

//   final List<TypeExpr> arguments;

//   TypeExpr(this.name, this.typeParameters, String fileName) : super(name.line, name.column, fileName);

//   Expr clone() => TypeExpr(name, typeParameters, fileName);
// }

class SymbolExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitSymbolExpr(this);

  final Token id;

  SymbolExpr(this.id)
      : super(SemanticType.symbolExpr, id.fileName, id.line, id.column);

  @override
  AstNode clone() => SymbolExpr(id);
}

class AssignExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitAssignExpr(this);

  /// 变量名
  final Token variable;

  /// 各种赋值符号变体
  final Token op;

  /// 变量名、表达式、函数调用
  final AstNode value;

  AssignExpr(this.variable, this.op, this.value)
      : super(SemanticType.assignExpr, variable.fileName, op.line, op.column);

  @override
  AstNode clone() => AssignExpr(variable, op, value);
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

class SubSetExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitSubSetExpr(this);

  /// 数组
  final AstNode collection;

  /// 索引
  final AstNode key;

  /// 值
  final AstNode value;

  SubSetExpr(this.collection, this.key, this.value)
      : super(SemanticType.subSetExpr, collection.moduleFullName,
            collection.line, collection.column);

  @override
  AstNode clone() => SubSetExpr(collection, key, value);
}

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

class MemberSetExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitMemberSetExpr(this);

  /// 集合
  final AstNode collection;

  /// 属性
  final Token key;

  /// 值
  final AstNode value;

  MemberSetExpr(this.collection, this.key, this.value)
      : super(SemanticType.memberSetExpr, collection.moduleFullName,
            collection.line, collection.column);

  @override
  AstNode clone() => MemberSetExpr(collection, key, value);
}

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

class ThisExpr extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitThisExpr(this);

  final Token keyword;

  ThisExpr(this.keyword)
      : super(SemanticType.thisExpr, keyword.fileName, keyword.line,
            keyword.column);

  @override
  AstNode clone() => ThisExpr(keyword);
}

class ImportStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitImportStmt(this);

  final Token keyword;

  final String key;

  final String? namespace;

  ImportStmt(this.keyword, this.key, [this.namespace])
      : super(SemanticType.importStmt, keyword.fileName, keyword.line,
            keyword.column);

  @override
  AstNode clone() => ImportStmt(keyword, key, namespace);
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

  BlockStmt(this.statements, String fileName, int line, int column)
      : super(SemanticType.blockStmt, fileName, line, column);

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
      : super(SemanticType.returnStmt, keyword.fileName, keyword.line,
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

  WhileStmt(this.condition, this.loop)
      : super(SemanticType.whileStmt, condition.moduleFullName, condition.line,
            condition.column);

  @override
  AstNode clone() => WhileStmt(condition.clone(), loop?.clone());
}

class BreakStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  BreakStmt(this.keyword)
      : super(SemanticType.breakStmt, keyword.fileName, keyword.line,
            keyword.column);

  @override
  AstNode clone() => BreakStmt(keyword);
}

class ContinueStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  ContinueStmt(this.keyword)
      : super(SemanticType.continueStmt, keyword.fileName, keyword.line,
            keyword.column);

  @override
  AstNode clone() => ContinueStmt(keyword);
}

class VarDeclStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitVarDeclStmt(this);

  final Token id;

  final HTType? declType;

  final AstNode? initializer;

  final bool isDynamic;

  // 仅用于整个class都为external的情况
  final bool isExtern;

  final bool isImmutable;

  final bool isStatic;

  VarDeclStmt(this.id,
      {this.declType,
      this.initializer,
      this.isDynamic = false,
      this.isExtern = false,
      this.isImmutable = false,
      this.isStatic = false})
      : super(SemanticType.varDeclStmt, id.fileName, id.line, id.column);

  @override
  AstNode clone() => VarDeclStmt(id,
      declType: declType,
      initializer: initializer,
      isExtern: isExtern,
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

  ParamDeclStmt(Token id,
      {HTType? declType,
      AstNode? initializer,
      bool isImmutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false})
      : super(id,
            declType: declType,
            initializer: initializer,
            isImmutable: isImmutable);

  @override
  AstNode clone() => ParamDeclStmt(id,
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

  final bool isExtern;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final FunctionType funcType;

  FuncDeclStmt(
      this.returnType, this.params, String fileName, int line, int column,
      {this.id,
      this.classId,
      this.typeParameters = const [],
      this.arity = 0,
      this.definition,
      this.isExtern = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.funcType = FunctionType.normal})
      : super(SemanticType.funcDeclStmt, fileName, line, column) {
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
        isExtern: isExtern,
        isStatic: isStatic,
        isConst: isConst,
        funcType: funcType);
  }
}

class ClassDeclStmt extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitClassDeclStmt(this);

  final Token id;

  final bool isExtern;

  final bool isAbstract;

  final List<VarDeclStmt> variables;

  final List<FuncDeclStmt> methods;

  final List<String> typeParameters;

  final SymbolExpr? superClass;

  final ClassDeclStmt? superClassDeclStmt;

  final HTType? superClassTypeArgs;

  ClassDeclStmt(this.id, this.variables, this.methods,
      {this.isExtern = false,
      this.isAbstract = false,
      this.typeParameters = const [],
      this.superClass,
      this.superClassDeclStmt,
      this.superClassTypeArgs})
      : super(SemanticType.classDeclStmt, id.fileName, id.line, id.column);

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
        isExtern: isExtern,
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

  final bool isExtern;

  EnumDeclStmt(this.id, this.enumerations, {this.isExtern = false})
      : super(SemanticType.enumDeclStmt, id.fileName, id.line, id.column);

  @override
  AstNode clone() => EnumDeclStmt(id, enumerations, isExtern: isExtern);
}

class AstModule extends AstNode {
  @override
  dynamic accept(AstNodeVisitor visitor) => visitor.visitAstModule(this);

  final List<AstNode> statements;

  AstModule(this.statements, String fileName, int line, int column)
      : super(SemanticType.blockStmt, fileName, line, column);

  @override
  AstNode clone() {
    var new_list = <AstNode>[];
    for (final expr in statements) {
      new_list.add(expr.clone());
    }
    return AstModule(new_list, moduleFullName, line, column);
  }
}
