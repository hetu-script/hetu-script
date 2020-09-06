import 'token.dart';
import 'common.dart';
import 'expression.dart';
import 'value.dart';

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

  /// Continue语句
  void visitContinueStmt(ContinueStmt stmt);

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
  String get type => HS_Common.ImportStmt;

  @override
  void accept(StmtVisitor visitor) => visitor.visitImportStmt(this);

  final String filepath;

  final String asspace;

  ImportStmt(this.filepath, {this.asspace});
}

class VarStmt extends Stmt {
  @override
  String get type => HS_Common.VarStmt;

  @override
  void accept(StmtVisitor visitor) => visitor.visitVarStmt(this);

  final Token name;

  final HS_Type declType;

  final Expr initializer;

  final bool isExtern;

  final bool isStatic;

  VarStmt(this.name, this.declType, {this.initializer, this.isExtern = false, this.isStatic = false});
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
  String get type => HS_Common.IfStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitIfStmt(this);

  final Expr condition;

  final Stmt thenBranch;

  final Stmt elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch);
}

class WhileStmt extends Stmt {
  @override
  String get type => HS_Common.WhileStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitWhileStmt(this);

  final Expr condition;

  final Stmt loop;

  WhileStmt(this.condition, this.loop);
}

class BreakStmt extends Stmt {
  @override
  String get type => HS_Common.BreakStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitBreakStmt(this);
}

class ContinueStmt extends Stmt {
  @override
  String get type => HS_Common.ContinueStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitContinueStmt(this);
}

enum FuncStmtType {
  normal,
  method,
  getter,
  setter,
  constructor,
}

class FuncStmt extends Stmt {
  @override
  String get type => HS_Common.FuncStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitFuncStmt(this);

  final Token keyword;

  final String name;

  final List<String> typeParams = [];

  final HS_Type returnType;

  String _internalName;
  String get internalName => _internalName;

  final String className;

  final List<VarStmt> params;

  final int arity;

  List<Stmt> definition;

  final bool isExtern;

  final bool isStatic;

  final bool isConst;

  final FuncStmtType funcType;

  FuncStmt(this.keyword, this.name, this.returnType, this.params,
      {List<String> typeParams,
      this.arity = 0,
      this.definition,
      this.className,
      this.isExtern = false,
      this.isStatic = false,
      this.isConst = false,
      this.funcType = FuncStmtType.normal}) {
    this.definition ??= <Stmt>[];
    if (funcType == FuncStmtType.constructor) {
      //_internalName = name.lexeme;
      _internalName = HS_Common.constructFun + name;
    } else if (funcType == FuncStmtType.getter) {
      _internalName = HS_Common.getFun + name;
    } else if (funcType == FuncStmtType.setter) {
      _internalName = HS_Common.setFun + name;
    } else {
      _internalName = name;
    }

    if (typeParams != null) this.typeParams.addAll(typeParams);
  }
}

class ClassStmt extends Stmt {
  @override
  String get type => HS_Common.ClassStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitClassStmt(this);

  final Token keyword;

  final String name;

  final List<String> typeParams = [];

  final HS_Type superClass;

  final List<VarStmt> variables;

  final List<FuncStmt> methods;

  ClassStmt(this.keyword, this.name, this.superClass, this.variables, this.methods, {List<String> typeParams}) {
    if (typeParams != null) this.typeParams.addAll(typeParams);
  }
}
