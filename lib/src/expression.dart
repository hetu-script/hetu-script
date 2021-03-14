import 'token.dart';
import 'lexicon.dart';
import 'statement.dart' show FuncDeclStmt;

/// 抽象的访问者模式，包含访问表达式的抽象语法树的接口
///
/// 访问语句称作execute，访问表达式称作evaluate
abstract class ExprVisitor {
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

  /// 匿名函数字面量
  dynamic visitLiteralFunctionExpr(LiteralFunctionExpr expr);

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
}

abstract class Expr {
  String get type;
  final String? fileName;
  final int? line;
  final int? column;

  /// 取表达式右值，返回值本身
  dynamic accept(ExprVisitor visitor);

  Expr([this.fileName, this.line, this.column]);

  Expr clone();
}

class NullExpr extends Expr {
  @override
  String get type => HT_Lexicon.nullExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr([String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() => this;
}

class BooleanExpr extends Expr {
  @override
  String get type => HT_Lexicon.literalBooleanExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitBooleanExpr(this);

  final bool value;

  BooleanExpr(this.value, [String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() => BooleanExpr(value, fileName, line, column);
}

class ConstIntExpr extends Expr {
  @override
  String get type => HT_Lexicon.literalNumberExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitConstIntExpr(this);

  final int constIndex;

  ConstIntExpr(this.constIndex, [String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() => ConstIntExpr(constIndex, fileName, line, column);
}

class ConstFloatExpr extends Expr {
  @override
  String get type => HT_Lexicon.literalNumberExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitConstFloatExpr(this);

  final int constIndex;

  ConstFloatExpr(this.constIndex, [String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() => ConstIntExpr(constIndex, fileName, line, column);
}

class ConstStringExpr extends Expr {
  @override
  String get type => HT_Lexicon.literalNumberExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitConstStringExpr(this);

  final int constIndex;

  ConstStringExpr(this.constIndex, [String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() => ConstStringExpr(constIndex, fileName, line, column);
}

class LiteralVectorExpr extends Expr {
  @override
  String get type => HT_Lexicon.vectorExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitLiteralVectorExpr(this);

  final List<Expr> vector;

  LiteralVectorExpr([this.vector = const [], String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() {
    var new_list = <Expr>[];
    for (final expr in vector) {
      new_list.add(expr.clone());
    }
    return LiteralVectorExpr(new_list, fileName, line, column);
  }
}

class LiteralDictExpr extends Expr {
  @override
  String get type => HT_Lexicon.blockExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitLiteralDictExpr(this);

  final Map<Expr, Expr> map;

  LiteralDictExpr([this.map = const {}, String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() {
    var new_map = <Expr, Expr>{};
    for (final expr in map.keys) {
      new_map[expr.clone()] = map[expr]!;
    }
    return LiteralDictExpr(new_map, fileName, line, column);
  }
}

class LiteralFunctionExpr extends Expr {
  @override
  String get type => HT_Lexicon.literalFunctionExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitLiteralFunctionExpr(this);

  final FuncDeclStmt funcStmt;

  LiteralFunctionExpr(this.funcStmt, [String? fileName, int? line, int? column]) : super(fileName, line, column);

  @override
  Expr clone() => LiteralFunctionExpr(funcStmt, fileName, line, column);
}

class GroupExpr extends Expr {
  @override
  String get type => HT_Lexicon.groupExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitGroupExpr(this);

  final Expr inner;

  GroupExpr(this.inner, [String? fileName]) : super(fileName, inner.line, inner.column);

  @override
  Expr clone() => GroupExpr(inner.clone(), fileName);
}

class UnaryExpr extends Expr {
  @override
  String get type => HT_Lexicon.unaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitUnaryExpr(this);

  /// 各种单目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  UnaryExpr(this.op, this.value, fileName) : super(fileName, op.line, op.column);

  @override
  Expr clone() => UnaryExpr(op, value.clone(), fileName);
}

class BinaryExpr extends Expr {
  @override
  String get type => HT_Lexicon.binaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitBinaryExpr(this);

  /// 左值
  final Expr left;

  /// 各种双目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr right;

  BinaryExpr(this.left, this.op, this.right, String? fileName) : super(fileName, op.line, op.column);

  @override
  Expr clone() => BinaryExpr(left.clone(), op, right.clone(), fileName);
}

// class TypeExpr extends Expr {
//   @override
//   String get type => env.lexicon.VarExpr;

//   @override
//   dynamic accept(ExprVisitor visitor) => visitor.visitTypeExpr(this);

//   final Token name;

//   final List<TypeExpr> arguments;

//   TypeExpr(this.name, this.typeParams, String fileName) : super(name.line, name.column, fileName);

//   Expr clone() => TypeExpr(name, typeParams, fileName);
// }

class SymbolExpr extends Expr {
  @override
  String get type => HT_Lexicon.varExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSymbolExpr(this);

  final Token id;

  SymbolExpr(this.id, String? fileName) : super(fileName, id.line, id.column);

  @override
  Expr clone() => SymbolExpr(id, fileName);
}

class AssignExpr extends Expr {
  @override
  String get type => HT_Lexicon.assignExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitAssignExpr(this);

  /// 变量名
  final Token variable;

  /// 各种赋值符号变体
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  AssignExpr(this.variable, this.op, this.value, String? fileName) : super(fileName, op.line, op.column);

  @override
  Expr clone() => AssignExpr(variable, op, value.clone(), fileName);
}

class SubGetExpr extends Expr {
  @override
  String get type => HT_Lexicon.subGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final Expr collection;

  /// 索引
  final Expr key;

  SubGetExpr(this.collection, this.key, String? fileName) : super(fileName, collection.line, collection.column);

  @override
  Expr clone() => SubGetExpr(collection.clone(), key.clone(), fileName);
}

class SubSetExpr extends Expr {
  @override
  String get type => HT_Lexicon.subSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubSetExpr(this);

  /// 数组
  final Expr collection;

  /// 索引
  final Expr key;

  /// 值
  final Expr value;

  SubSetExpr(this.collection, this.key, this.value, String? fileName)
      : super(fileName, collection.line, collection.column);

  @override
  Expr clone() => SubSetExpr(collection.clone(), key.clone(), value.clone(), fileName);
}

class MemberGetExpr extends Expr {
  @override
  String get type => HT_Lexicon.memberGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberGetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  MemberGetExpr(this.collection, this.key, String? fileName) : super(fileName, collection.line, collection.column);

  @override
  Expr clone() => MemberGetExpr(collection.clone(), key, fileName);
}

class MemberSetExpr extends Expr {
  @override
  String get type => HT_Lexicon.memberSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberSetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  /// 值
  final Expr value;

  MemberSetExpr(this.collection, this.key, this.value, String? fileName)
      : super(fileName, collection.line, collection.column);

  @override
  Expr clone() => MemberSetExpr(collection.clone(), key, value.clone(), fileName);
}

class CallExpr extends Expr {
  @override
  String get type => HT_Lexicon.callExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitCallExpr(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final Expr callee;

  /// 函数声明的参数是parameter，调用时传入的变量叫argument
  final List<Expr> positionalArgs;

  final Map<String, Expr> namedArgs;

  CallExpr(this.callee, this.positionalArgs, this.namedArgs, String? fileName)
      : super(fileName, callee.line, callee.column);

  @override
  Expr clone() {
    var new_args = <Expr>[];
    for (final expr in positionalArgs) {
      new_args.add(expr.clone());
    }

    var new_named_args = <String, Expr>{};
    for (final name in namedArgs.keys) {
      new_named_args[name] = namedArgs[name]!.clone();
    }

    return CallExpr(callee.clone(), new_args, new_named_args, fileName);
  }
}

class ThisExpr extends Expr {
  @override
  String get type => HT_Lexicon.thisExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitThisExpr(this);

  final Token keyword;

  ThisExpr(this.keyword, String? fileName) : super(fileName, keyword.line, keyword.column);

  @override
  Expr clone() => ThisExpr(keyword, fileName);
}
