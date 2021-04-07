import '../token.dart';
import '../lexicon.dart';
import '../type.dart';
import '../common.dart';

/// 抽象的访问者模式，包含访问表达式的抽象语法树的接口
abstract class ASTNodeVisitor {
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
}

abstract class ASTNode {
  final String type;

  final String fileName;
  final int line;
  final int column;

  /// 取表达式右值，返回值本身
  dynamic accept(ASTNodeVisitor visitor);

  ASTNode(this.type, this.fileName, this.line, this.column);

  ASTNode clone();
}

class NullExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr(String fileName, int line, int column)
      : super(HTLexicon.nullExpr, fileName, line, column);

  @override
  ASTNode clone() => NullExpr(fileName, line, column);
}

class BooleanExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  BooleanExpr(this.value, String fileName, int line, int column)
      : super(HTLexicon.literalBooleanExpr, fileName, line, column);

  @override
  ASTNode clone() => BooleanExpr(value, fileName, line, column);
}

class ConstIntExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitConstIntExpr(this);

  final int constIndex;

  ConstIntExpr(this.constIndex, String fileName, int line, int column)
      : super(HTLexicon.literalIntExpr, fileName, line, column);

  @override
  ASTNode clone() => ConstIntExpr(constIndex, fileName, line, column);
}

class ConstFloatExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitConstFloatExpr(this);

  final int constIndex;

  ConstFloatExpr(this.constIndex, String fileName, int line, int column)
      : super(HTLexicon.literalFloatExpr, fileName, line, column);

  @override
  ASTNode clone() => ConstFloatExpr(constIndex, fileName, line, column);
}

class ConstStringExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitConstStringExpr(this);

  final int constIndex;

  ConstStringExpr(this.constIndex, String fileName, int line, int column)
      : super(HTLexicon.literalStringExpr, fileName, line, column);

  @override
  ASTNode clone() => ConstStringExpr(constIndex, fileName, line, column);
}

class LiteralVectorExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) =>
      visitor.visitLiteralVectorExpr(this);

  final List<ASTNode> vector;

  LiteralVectorExpr(String fileName, int line, int column,
      [this.vector = const []])
      : super(HTLexicon.literalVectorExpr, fileName, line, column);

  @override
  ASTNode clone() {
    var new_list = <ASTNode>[];
    for (final expr in vector) {
      new_list.add(expr.clone());
    }
    return LiteralVectorExpr(fileName, line, column, new_list);
  }
}

class LiteralDictExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitLiteralDictExpr(this);

  final Map<ASTNode, ASTNode> map;

  LiteralDictExpr(String fileName, int line, int column, [this.map = const {}])
      : super(HTLexicon.blockExpr, fileName, line, column);

  @override
  ASTNode clone() {
    var new_map = <ASTNode, ASTNode>{};
    for (final expr in map.keys) {
      new_map[expr.clone()] = map[expr]!.clone();
    }
    return LiteralDictExpr(fileName, line, column, new_map);
  }
}

class GroupExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitGroupExpr(this);

  final ASTNode inner;

  GroupExpr(this.inner)
      : super(HTLexicon.groupExpr, inner.fileName, inner.line, inner.column);

  @override
  ASTNode clone() => GroupExpr(inner.clone());
}

class UnaryExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitUnaryExpr(this);

  /// 各种单目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final ASTNode value;

  UnaryExpr(this.op, this.value)
      : super(HTLexicon.unaryExpr, op.fileName, op.line, op.column);

  @override
  ASTNode clone() => UnaryExpr(op, value.clone());
}

class BinaryExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitBinaryExpr(this);

  /// 左值
  final ASTNode left;

  /// 各种双目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final ASTNode right;

  BinaryExpr(this.left, this.op, this.right)
      : super(HTLexicon.binaryExpr, op.fileName, op.line, op.column);

  @override
  ASTNode clone() => BinaryExpr(left.clone(), op, right.clone());
}

// class TypeExpr extends Expr {
//   @override
//   final String type = env.lexicon.VarExpr;

//   @override
//   dynamic accept(ExprVisitor visitor) => visitor.visitTypeExpr(this);

//   final Token name;

//   final List<TypeExpr> arguments;

//   TypeExpr(this.name, this.typeParams, String fileName) : super(name.line, name.column, fileName);

//   Expr clone() => TypeExpr(name, typeParams, fileName);
// }

class SymbolExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitSymbolExpr(this);

  final Token id;

  SymbolExpr(this.id)
      : super(HTLexicon.symbolExpr, id.fileName, id.line, id.column);

  @override
  ASTNode clone() => SymbolExpr(id);
}

class AssignExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitAssignExpr(this);

  /// 变量名
  final Token variable;

  /// 各种赋值符号变体
  final Token op;

  /// 变量名、表达式、函数调用
  final ASTNode value;

  AssignExpr(this.variable, this.op, this.value)
      : super(HTLexicon.assignExpr, variable.fileName, op.line, op.column);

  @override
  ASTNode clone() => AssignExpr(variable, op, value);
}

class SubGetExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final ASTNode collection;

  /// 索引
  final ASTNode key;

  SubGetExpr(this.collection, this.key)
      : super(HTLexicon.subGetExpr, collection.fileName, collection.line,
            collection.column);

  @override
  ASTNode clone() => SubGetExpr(collection, key);
}

class SubSetExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitSubSetExpr(this);

  /// 数组
  final ASTNode collection;

  /// 索引
  final ASTNode key;

  /// 值
  final ASTNode value;

  SubSetExpr(this.collection, this.key, this.value)
      : super(HTLexicon.subSetExpr, collection.fileName, collection.line,
            collection.column);

  @override
  ASTNode clone() => SubSetExpr(collection, key, value);
}

class MemberGetExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitMemberGetExpr(this);

  /// 集合
  final ASTNode collection;

  /// 属性
  final Token key;

  MemberGetExpr(this.collection, this.key)
      : super(HTLexicon.memberGetExpr, collection.fileName, collection.line,
            collection.column);

  @override
  ASTNode clone() => MemberGetExpr(collection, key);
}

class MemberSetExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitMemberSetExpr(this);

  /// 集合
  final ASTNode collection;

  /// 属性
  final Token key;

  /// 值
  final ASTNode value;

  MemberSetExpr(this.collection, this.key, this.value)
      : super(HTLexicon.memberSetExpr, collection.fileName, collection.line,
            collection.column);

  @override
  ASTNode clone() => MemberSetExpr(collection, key, value);
}

class CallExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitCallExpr(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final ASTNode callee;

  /// 函数声明的参数是parameter，调用时传入的变量叫argument
  final List<ASTNode> positionalArgs;

  final Map<String, ASTNode> namedArgs;

  CallExpr(this.callee, this.positionalArgs, this.namedArgs)
      : super(HTLexicon.callExpr, callee.fileName, callee.line, callee.column);

  @override
  ASTNode clone() {
    var new_args = <ASTNode>[];
    for (final expr in positionalArgs) {
      new_args.add(expr.clone());
    }

    var new_named_args = <String, ASTNode>{};
    for (final name in namedArgs.keys) {
      new_named_args[name] = namedArgs[name]!.clone();
    }

    return CallExpr(callee.clone(), new_args, new_named_args);
  }
}

class ThisExpr extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitThisExpr(this);

  final Token keyword;

  ThisExpr(this.keyword)
      : super(
            HTLexicon.thisExpr, keyword.fileName, keyword.line, keyword.column);

  @override
  ASTNode clone() => ThisExpr(keyword);
}

class ImportStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitImportStmt(this);

  final Token keyword;

  final String key;

  final String? namespace;

  ImportStmt(this.keyword, this.key, [this.namespace])
      : super(HTLexicon.importStmt, keyword.fileName, keyword.line,
            keyword.column);

  @override
  ASTNode clone() => ImportStmt(keyword, key, namespace);
}

class ExprStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final ASTNode expr;

  ExprStmt(this.expr)
      : super(HTLexicon.exprStmt, expr.fileName, expr.line, expr.column);

  @override
  ASTNode clone() => ExprStmt(expr.clone());
}

class BlockStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitBlockStmt(this);

  final List<ASTNode> block;

  BlockStmt(this.block, String fileName, int line, int column)
      : super(HTLexicon.blockStmt, fileName, line, column);

  @override
  ASTNode clone() {
    var new_list = <ASTNode>[];
    for (final expr in block) {
      new_list.add(expr.clone());
    }
    return BlockStmt(new_list, fileName, line, column);
  }
}

class ReturnStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final ASTNode? value;

  ReturnStmt(this.keyword, this.value)
      : super(HTLexicon.returnStmt, keyword.fileName, keyword.line,
            keyword.column);

  @override
  ASTNode clone() => ReturnStmt(keyword, value?.clone());
}

class IfStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitIfStmt(this);

  final ASTNode condition;

  final ASTNode? thenBranch;

  final ASTNode? elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch)
      : super(HTLexicon.ifStmt, condition.fileName, condition.line,
            condition.column);

  @override
  ASTNode clone() =>
      IfStmt(condition.clone(), thenBranch?.clone(), elseBranch?.clone());
}

class WhileStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitWhileStmt(this);

  final ASTNode condition;

  final ASTNode? loop;

  WhileStmt(this.condition, this.loop)
      : super(HTLexicon.whileStmt, condition.fileName, condition.line,
            condition.column);

  @override
  ASTNode clone() => WhileStmt(condition.clone(), loop?.clone());
}

class BreakStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitBreakStmt(this);

  final Token keyword;

  BreakStmt(this.keyword)
      : super(HTLexicon.breakStmt, keyword.fileName, keyword.line,
            keyword.column);

  @override
  ASTNode clone() => BreakStmt(keyword);
}

class ContinueStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitContinueStmt(this);

  final Token keyword;

  ContinueStmt(this.keyword)
      : super(HTLexicon.continueStmt, keyword.fileName, keyword.line,
            keyword.column);

  @override
  ASTNode clone() => ContinueStmt(keyword);
}

class VarDeclStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitVarDeclStmt(this);

  final Token id;

  final HTType? declType;

  final ASTNode? initializer;

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
      : super(HTLexicon.varDeclStmt, id.fileName, id.line, id.column);

  @override
  ASTNode clone() => VarDeclStmt(id,
      declType: declType,
      initializer: initializer,
      isExtern: isExtern,
      isImmutable: isImmutable,
      isStatic: isStatic);
}

class ParamDeclStmt extends VarDeclStmt {
  @override
  final type = HTLexicon.paramStmt;

  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitParamDeclStmt(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  ParamDeclStmt(Token id,
      {HTType? declType,
      ASTNode? initializer,
      bool isImmutable = false,
      this.isVariadic = false,
      this.isOptional = false,
      this.isNamed = false})
      : super(id,
            declType: declType,
            initializer: initializer,
            isImmutable: isImmutable);

  @override
  ASTNode clone() => ParamDeclStmt(id,
      declType: declType,
      initializer: initializer,
      isImmutable: isImmutable,
      isVariadic: isVariadic,
      isOptional: isOptional,
      isNamed: isNamed);
}

class FuncDeclStmt extends ASTNode {
  static int functionIndex = 0;

  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final Token? id;

  final List<String> typeParams;

  final HTType returnType;

  late final String _internalName;
  String get internalName => _internalName;

  final String? classId;
  // final HTType? classType;

  final List<ParamDeclStmt> params;

  final int arity;

  final List<ASTNode>? definition;

  final bool isExtern;

  final bool isStatic;

  final bool isConst;

  final bool isVariadic;

  final FunctionType funcType;

  FuncDeclStmt(
      this.returnType, this.params, String fileName, int line, int column,
      {this.id,
      this.classId,
      this.typeParams = const [],
      this.arity = 0,
      this.definition,
      this.isExtern = false,
      this.isStatic = false,
      this.isConst = false,
      this.isVariadic = false,
      this.funcType = FunctionType.normal})
      : super(HTLexicon.funcDeclStmt, fileName, line, column) {
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
  ASTNode clone() {
    var new_params = <ParamDeclStmt>[];
    for (final expr in params) {
      new_params.add(expr.clone() as ParamDeclStmt);
    }

    var new_body;
    if (definition != null) {
      new_body = <ASTNode>[];
      for (final expr in definition!) {
        new_body.add(expr.clone());
      }
    }

    return FuncDeclStmt(returnType, new_params, fileName, line, column,
        id: id,
        classId: classId,
        typeParams: typeParams,
        arity: arity,
        definition: new_body,
        isExtern: isExtern,
        isStatic: isStatic,
        isConst: isConst,
        funcType: funcType);
  }
}

class ClassDeclStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitClassDeclStmt(this);

  final Token id;

  final ClassType classType;

  final List<VarDeclStmt> variables;

  final List<FuncDeclStmt> methods;

  final List<String> typeParams;

  final SymbolExpr? superClass;

  final ClassDeclStmt? superClassDeclStmt;

  final HTType? superClassTypeArgs;

  ClassDeclStmt(this.id, this.variables, this.methods,
      {this.classType = ClassType.normal,
      this.typeParams = const [],
      this.superClass,
      this.superClassDeclStmt,
      this.superClassTypeArgs})
      : super(HTLexicon.classDeclStmt, id.fileName, id.line, id.column);

  @override
  ASTNode clone() {
    var new_vars = <VarDeclStmt>[];
    for (final expr in variables) {
      new_vars.add(expr.clone() as VarDeclStmt);
    }

    var new_methods = <FuncDeclStmt>[];
    for (final expr in methods) {
      new_methods.add(expr.clone() as FuncDeclStmt);
    }

    return ClassDeclStmt(id, new_vars, new_methods,
        classType: classType,
        typeParams: typeParams,
        superClass: superClass,
        superClassDeclStmt: superClassDeclStmt,
        superClassTypeArgs: superClassTypeArgs);
  }
}

class EnumDeclStmt extends ASTNode {
  @override
  dynamic accept(ASTNodeVisitor visitor) => visitor.visitEnumDeclStmt(this);
  final Token id;

  final List<String> enumerations;

  final bool isExtern;

  EnumDeclStmt(this.id, this.enumerations, {this.isExtern = false})
      : super(HTLexicon.enumDeclStmt, id.fileName, id.line, id.column);

  @override
  ASTNode clone() => EnumDeclStmt(id, enumerations, isExtern: isExtern);
}
