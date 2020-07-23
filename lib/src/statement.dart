import 'token.dart';
import 'common.dart';
import 'expression.dart';

/// 抽象的访问者模式，包含访问语句的抽象语法树的接口
///
/// 表达式和语句的区别在于：1，语句以";"结尾，而表达式没有";""
///
/// 2，访问语句返回void，访问表达式返回dynamic
///
/// 3，访问语句称作execute，访问表达式称作evaluate
///
/// 4，语句包含表达式，而表达式不包含语句
abstract class StmtVisitor {
  /// 导入语句
  void visitImportStmt(ImportStmt stmt);

  /// 变量声明语句
  void visitVarStmt(VarStmt stmt);

  /// 表达式语句
  void visitExprStmt(ExprStmt stmt);

  /// 语句块：用于既允许单条语句，又允许语句块的场合，比如IfStatment
  void visitBlockStmt(BlockStmt stmt);

  /// 返回语句
  void visitReturnStmt(ReturnStmt stmt);

  /// If语句
  void visitIfStmt(IfStmt stmt);

  /// While语句
  void visitWhileStmt(WhileStmt stmt);

  /// Break语句
  void visitBreakStmt(BreakStmt stmt);

  /// 函数声明和定义
  void visitFuncStmt(FuncStmt stmt);

  /// 类
  void visitClassStmt(ClassStmt stmt);
}

abstract class Stmt {
  String get type;

  void accept(StmtVisitor visitor);
}

class ImportStmt extends Stmt {
  @override
  String get type => HS_Common.Import;

  @override
  void accept(StmtVisitor visitor) => visitor.visitImportStmt(this);

  final String filepath;

  ImportStmt(this.filepath);
}

class VarStmt extends Stmt {
  @override
  String get type => HS_Common.VarStmt;

  @override
  void accept(StmtVisitor visitor) => visitor.visitVarStmt(this);

  final Token typename;
  //final VarExpr typename;

  final Token varname;

  final Expr initializer;

  VarStmt(this.typename, this.varname, this.initializer);
}

class ExprStmt extends Stmt {
  @override
  String get type => HS_Common.ExprStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final Expr expr;

  ExprStmt(this.expr);
}

class BlockStmt extends Stmt {
  @override
  String get type => HS_Common.BlockStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitBlockStmt(this);

  final List<Stmt> block;

  BlockStmt(this.block);
}

class ReturnStmt extends Stmt {
  @override
  String get type => HS_Common.ReturnStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final Expr expr;

  ReturnStmt(this.keyword, this.expr);
}

class IfStmt extends Stmt {
  @override
  String get type => HS_Common.If;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitIfStmt(this);

  final Expr condition;

  final Stmt thenBranch;

  final Stmt elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch);
}

class WhileStmt extends Stmt {
  @override
  String get type => HS_Common.While;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitWhileStmt(this);

  final Expr condition;

  final Stmt loop;

  WhileStmt(this.condition, this.loop);
}

class BreakStmt extends Stmt {
  @override
  String get type => HS_Common.Break;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitBreakStmt(this);
}

class FuncStmt extends Stmt {
  @override
  String get type => HS_Common.FuncStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitFuncStmt(this);

  final String returnType;

  final Token name;

  final String className;

  final List<VarStmt> params;

  final int arity;

  List<Stmt> definition;

  final bool isExtern;

  final bool isStatic;

  final bool isConstructor;

  FuncStmt(this.returnType, this.name, this.params,
      {this.arity = 0,
      this.definition,
      this.className,
      this.isExtern = false,
      this.isStatic = false,
      this.isConstructor = false}) {
    this.definition ??= <Stmt>[];
  }
}

class ClassStmt extends Stmt {
  @override
  String get type => HS_Common.ClassStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitClassStmt(this);

  final Token name;

  final VarExpr superClass;

  final List<VarStmt> variables;

  final List<FuncStmt> methods;

  ClassStmt(this.name, this.superClass, this.variables, this.methods);
}
