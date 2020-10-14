import 'token.dart';
import 'common.java';

/// 抽象的访问者模式，包含访问表达式的抽象语法树的接口
///
///语句和表达式的区别在于：1，语句以";"结尾，而表达式没有";""
///
/// 2，访问语句返回void，访问表达式返回dynamic
///
/// 3，访问语句称作execute，访问表达式称作evaluate
///
/// 4，语句包含表达式，而表达式不包含语句
abstract class ExprVisitor {
  /// Null
  dynamic visitNullExpr(NullExpr expr);

  /// 字面量
  dynamic visitLiteralExpr(LiteralExpr expr);

  /// 圆括号表达式 - 元组
  dynamic visitGroupExpr(GroupExpr expr);

  /// 方括号表达式 - 数组
  dynamic visitVectorExpr(VectorExpr expr);

  /// 花括号表达式 - 字典
  dynamic visitBlockExpr(BlockExpr expr);

  /// 单目表达式
  dynamic visitUnaryExpr(UnaryExpr expr);

  /// 双目表达式
  dynamic visitBinaryExpr(BinaryExpr expr);

  /// 类型名
  // dynamic visitTypeExpr(TypeExpr expr);

  /// 变量名
  dynamic visitVarExpr(VarExpr expr);

  /// 类型
  // dynamic visitTypeExpr(TypeExpr expr);

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
  final int line;
  final int column;
  final String fileName;

  /// 取表达式右值，返回值本身
  dynamic accept(ExprVisitor visitor);

  Expr(this.line, this.column, this.fileName);

  Expr clone();
}

class NullExpr extends Expr {
  @override
  String get type => HS_Common.nullExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitNullExpr(this);

  NullExpr(int line, int column, String fileName) : super(line, column, fileName);

  Expr clone() => this;
}

class LiteralExpr extends Expr {
  @override
  String get type => HS_Common.literalExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitLiteralExpr(this);

  int _constIndex;
  int get constantIndex => _constIndex;

  LiteralExpr(int constantIndex, int line, int column, String fileName) : super(line, column, fileName) {
    _constIndex = constantIndex;
  }

  Expr clone() => LiteralExpr(_constIndex, line, column, fileName);
}

class GroupExpr extends Expr {
  @override
  String get type => HS_Common.groupExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitGroupExpr(this);

  final Expr inner;

  GroupExpr(this.inner, String fileName) : super(inner.line, inner.column, fileName);

  Expr clone() => GroupExpr(inner.clone(), fileName);
}

class VectorExpr extends Expr {
  @override
  String get type => HS_Common.vectorExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitVectorExpr(this);

  List<Expr> vector;

  VectorExpr(this.vector, int line, int column, String fileName) : super(line, column, fileName) {
    vector ??= [];
  }

  Expr clone() {
    var new_list = <Expr>[];
    for (var expr in vector) {
      new_list.add(expr.clone());
    }
    return VectorExpr(new_list, line, column, fileName);
  }
}

class BlockExpr extends Expr {
  @override
  String get type => HS_Common.blockExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitBlockExpr(this);

  Map<Expr, Expr> map;

  BlockExpr(this.map, int line, int column, String fileName) : super(line, column, fileName) {
    map ??= {};
  }

  // List<Expr> list;

  // BlockExpr(this.list, int line, int column, String fileName) : super(line, column, fileName) {
  //   list ??= [];
  // }

  Expr clone() {
    var new_map = <Expr, Expr>{};
    for (var expr in map.keys) {
      new_map[expr.clone()] = map[expr];
    }
    return BlockExpr(new_map, line, column, fileName);
  }
}

class UnaryExpr extends Expr {
  @override
  String get type => HS_Common.unaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitUnaryExpr(this);

  /// 各种单目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  UnaryExpr(this.op, this.value, fileName) : super(op.line, op.column, fileName);

  Expr clone() => UnaryExpr(op, value.clone(), fileName);
}

class BinaryExpr extends Expr {
  @override
  String get type => HS_Common.binaryExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitBinaryExpr(this);

  /// 左值
  final Expr left;

  /// 各种双目操作符
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr right;

  BinaryExpr(this.left, this.op, this.right, String fileName) : super(op.line, op.column, fileName);

  Expr clone() => BinaryExpr(left.clone(), op, right.clone(), fileName);
}

// class TypeExpr extends Expr {
//   @override
//   String get type => HS_Common.VarExpr;

//   @override
//   dynamic accept(ExprVisitor visitor) => visitor.visitTypeExpr(this);

//   final Token name;

//   final List<TypeExpr> arguments;

//   TypeExpr(this.name, this.typeParams, String fileName) : super(name.line, name.column, fileName);

//   Expr clone() => TypeExpr(name, typeParams, fileName);
// }

class VarExpr extends Expr {
  @override
  String get type => HS_Common.varExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitVarExpr(this);

  final Token name;

  VarExpr(this.name, String fileName) : super(name.line, name.column, fileName);

  Expr clone() => VarExpr(name, fileName);
}

class AssignExpr extends Expr {
  @override
  String get type => HS_Common.assignExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitAssignExpr(this);

  /// 变量名
  final Token variable;

  /// 各种赋值符号变体
  final Token op;

  /// 变量名、表达式、函数调用
  final Expr value;

  AssignExpr(this.variable, this.op, this.value, String fileName) : super(op.line, op.column, fileName);

  Expr clone() => AssignExpr(variable, op, value.clone(), fileName);
}

class SubGetExpr extends Expr {
  @override
  String get type => HS_Common.subGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubGetExpr(this);

  /// 数组
  final Expr collection;

  /// 索引
  final Expr key;

  SubGetExpr(this.collection, this.key, String fileName) : super(collection.line, collection.column, fileName);

  Expr clone() => SubGetExpr(collection.clone(), key.clone(), fileName);
}

class SubSetExpr extends Expr {
  @override
  String get type => HS_Common.subSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitSubSetExpr(this);

  /// 数组
  final Expr collection;

  /// 索引
  final Expr key;

  /// 值
  final Expr value;

  SubSetExpr(this.collection, this.key, this.value, String fileName)
      : super(collection.line, collection.column, fileName);

  Expr clone() => SubSetExpr(collection.clone(), key.clone(), value.clone(), fileName);
}

class MemberGetExpr extends Expr {
  @override
  String get type => HS_Common.memberGetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberGetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  MemberGetExpr(this.collection, this.key, String fileName) : super(collection.line, collection.column, fileName);

  Expr clone() => MemberGetExpr(collection.clone(), key, fileName);
}

class MemberSetExpr extends Expr {
  @override
  String get type => HS_Common.memberSetExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitMemberSetExpr(this);

  /// 集合
  final Expr collection;

  /// 属性
  final Token key;

  /// 值
  final Expr value;

  MemberSetExpr(this.collection, this.key, this.value, String fileName)
      : super(collection.line, collection.column, fileName);

  Expr clone() => MemberSetExpr(collection.clone(), key, value.clone(), fileName);
}

class CallExpr extends Expr {
  @override
  String get type => HS_Common.callExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitCallExpr(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final Expr callee;

  /// 函数声明的参数是parameter，调用时传入的变量叫argument
  final List<Expr> args;

  CallExpr(this.callee, this.args, String fileName) : super(callee.line, callee.column, fileName);

  Expr clone() {
    var new_args = <Expr>[];
    for (var expr in args) {
      new_args.add(expr.clone());
    }
    return CallExpr(callee.clone(), new_args, fileName);
  }
}

class ThisExpr extends Expr {
  @override
  String get type => HS_Common.thisExpr;

  @override
  dynamic accept(ExprVisitor visitor) => visitor.visitThisExpr(this);

  final Token keyword;

  ThisExpr(this.keyword, String fileName) : super(keyword.line, keyword.column, fileName);

  Expr clone() => ThisExpr(keyword, fileName);
}
