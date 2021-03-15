import 'token.dart';
import 'lexicon.dart';
import 'expression.dart';
import 'type.dart';

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

abstract class Stmt {
  String get type;

  dynamic accept(StmtVisitor visitor);
}

class ImportStmt extends Stmt {
  @override
  String get type => HT_Lexicon.importStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitImportStmt(this);

  final String path;

  final String? nameSpace;

  ImportStmt(this.path, {this.nameSpace});
}

class ExprStmt extends Stmt {
  @override
  String get type => HT_Lexicon.exprStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitExprStmt(this);

  /// 可能是单独的变量名，也可能是一个表达式作为函数使用
  final Expr expr;

  ExprStmt(this.expr);
}

class BlockStmt extends Stmt {
  @override
  String get type => HT_Lexicon.blockStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitBlockStmt(this);

  final List<Stmt> block;

  BlockStmt(this.block);
}

class ReturnStmt extends Stmt {
  @override
  String get type => HT_Lexicon.returnStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitReturnStmt(this);

  final Token keyword;

  final Expr? expr;

  ReturnStmt(this.keyword, this.expr);
}

class IfStmt extends Stmt {
  @override
  String get type => HT_Lexicon.ifStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitIfStmt(this);

  final Expr condition;

  final Stmt? thenBranch;

  final Stmt? elseBranch;

  IfStmt(this.condition, this.thenBranch, this.elseBranch);
}

class WhileStmt extends Stmt {
  @override
  String get type => HT_Lexicon.whileStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitWhileStmt(this);

  final Expr condition;

  final Stmt? loop;

  WhileStmt(this.condition, this.loop);
}

class BreakStmt extends Stmt {
  @override
  String get type => HT_Lexicon.breakStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitBreakStmt(this);
}

class ContinueStmt extends Stmt {
  @override
  String get type => HT_Lexicon.continueStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitContinueStmt(this);
}

class VarDeclStmt extends Stmt {
  @override
  String get type => HT_Lexicon.varStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitVarDeclStmt(this);

  final String? fileName;

  final Token id;

  final HT_TypeId declType;

  final Expr? initializer;

  final bool isDynamic;

  final bool isImmutable;

  final bool isExtern;

  final bool isStatic;

  VarDeclStmt(
    this.fileName,
    this.id, {
    this.declType = HT_TypeId.ANY,
    this.initializer,
    this.isDynamic = false,
    this.isImmutable = false,
    this.isExtern = false,
    this.isStatic = false,
  });
}

class ParamDeclStmt extends VarDeclStmt {
  @override
  String get type => HT_Lexicon.paramStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitParamDeclStmt(this);

  final bool isVariadic;

  final bool isOptional;

  final bool isNamed;

  ParamDeclStmt(
    String fileName,
    Token id, {
    HT_TypeId declType = HT_TypeId.ANY,
    Expr? initializer,
    bool isDynamic = false,
    bool isImmutable = false,
    bool isExtern = false,
    bool isStatic = false,
    this.isVariadic = false,
    this.isOptional = false,
    this.isNamed = false,
  }) : super(
          fileName,
          id,
          declType: declType,
          initializer: initializer,
          isDynamic: isDynamic,
          isImmutable: isImmutable,
        );
}

enum FuncStmtType {
  normal,
  constructor,
  getter,
  setter,
  method, // normal function within a class
  literal, // function expression with no function name
}

class FuncDeclStmt extends Stmt {
  static int functionIndex = 0;

  @override
  String get type => HT_Lexicon.funcStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitFuncDeclStmt(this);

  final String fileName;

  final Token keyword;

  late final String id;

  final List<String> typeParams;

  final HT_TypeId returnType;

  late final String _internalName;
  String get internalName => _internalName;

  final String? className;

  final List<ParamDeclStmt> params;

  final int arity;

  final List<Stmt>? definition;

  final bool isVariadic;

  final bool isExtern;

  final bool isStatic;

  final bool isConst;

  final FuncStmtType funcType;

  FuncDeclStmt(this.fileName, this.keyword, this.returnType, this.params,
      {String? id,
      this.className,
      this.typeParams = const [],
      this.arity = 0,
      this.definition,
      this.isVariadic = false,
      this.isExtern = false,
      this.isStatic = false,
      this.isConst = false,
      this.funcType = FuncStmtType.normal}) {
    this.id = id ?? HT_Lexicon.anonymousFunction + (functionIndex++).toString();

    if (funcType == FuncStmtType.getter) {
      _internalName = HT_Lexicon.getter + this.id;
    } else if (funcType == FuncStmtType.setter) {
      _internalName = HT_Lexicon.setter + this.id;
    } else {
      _internalName = this.id;
    }
  }
}

class ClassDeclStmt extends Stmt {
  @override
  String get type => HT_Lexicon.classStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitClassDeclStmt(this);

  final String fileName;

  final Token keyword;

  final String id;

  final List<String> typeParams;

  final SymbolExpr? superClass;

  final ClassDeclStmt? superClassDeclStmt;

  final HT_TypeId? superClassTypeArgs;

  final List<VarDeclStmt> variables;

  final List<FuncDeclStmt> methods;

  final bool isExtern;

  ClassDeclStmt(this.fileName, this.keyword, this.id, this.superClass, this.superClassDeclStmt, this.superClassTypeArgs,
      this.variables, this.methods,
      {this.typeParams = const [], this.isExtern = false});
}

class EnumDeclStmt extends Stmt {
  @override
  String get type => HT_Lexicon.enumStmt;

  @override
  dynamic accept(StmtVisitor visitor) => visitor.visitEnumDeclStmt(this);

  final String fileName;

  final Token keyword;

  final String id;

  final List<String> enumerations;

  final bool isExtern;

  EnumDeclStmt(this.fileName, this.keyword, this.id, this.enumerations, {this.isExtern = false});
}
