import 'dart:typed_data';
import 'dart:convert';

import 'expression.dart';
import 'statement.dart';
import 'parser.dart' show ParseStyle;

import 'opcode.dart';
import 'token.dart';
import 'common.dart';
import 'lexicon.dart';
import 'errors.dart';

class Compiler implements ExprVisitor, StmtVisitor {
  static const hetuSignatureData = [8, 5, 20, 21];
  static const hetuSignature = 134550549;
  static const hetuVersionData = [0, 1, 0, 0, 0, 0];

  // Uint8List compileTokens(List<Token> tokens, [ParseStyle style = ParseStyle.library]) {}
  late HT_Context _context;

  late String _curFileName;

  late BytesBuilder _bytesBuilder;

  Uint8List compileAST(List<Stmt> statements, HT_Context context, String fileName,
      [ParseStyle style = ParseStyle.library]) {
    _context = context;
    _curFileName = fileName;

    _bytesBuilder = BytesBuilder();

    // 河图字节码标记
    _bytesBuilder.add(hetuSignatureData);
    // 版本号
    _bytesBuilder.add(hetuVersionData);

    for (final stmt in statements) {
      _bytesBuilder.add(_compileStmt(stmt));
    }

    return _bytesBuilder.toBytes();
  }

  Uint8List compileTokens(List<Token> tokens, [ParseStyle style = ParseStyle.library]) {
    _bytesBuilder = BytesBuilder();
    // 河图字节码标记
    _bytesBuilder.add(hetuSignatureData);
    // 版本号
    _bytesBuilder.add(hetuVersionData);

    return _bytesBuilder.toBytes();
  }

  Uint8List _int64(int value) => Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);

  Uint8List _float64(double value) => Uint8List(8)..buffer.asByteData().setFloat64(0, value, Endian.big);

  Uint8List _string(String value) {
    final bytesBuilder = BytesBuilder();
    final stringData = utf8.encoder.convert(value);
    bytesBuilder.add(_int64(stringData.length));
    bytesBuilder.add(stringData);
    return bytesBuilder.toBytes();
  }

  Uint8List _compileExpr(Expr expr) => expr.accept(this);

  Uint8List _compileStmt(Stmt stmt) => stmt.accept(this);

  @override
  dynamic visitNullExpr(NullExpr expr) {}

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) {}

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HT_OpCode.local);
    bytesBuilder.addByte(HT_OpRandType.constInt64);
    bytesBuilder.add(_int64(expr.constIndex));
    return bytesBuilder.toBytes();
  }

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HT_OpCode.local);
    bytesBuilder.addByte(HT_OpRandType.constFloat64);
    bytesBuilder.add(_int64(expr.constIndex));
    return bytesBuilder.toBytes();
  }

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HT_OpCode.local);
    bytesBuilder.addByte(HT_OpRandType.constUtf8String);
    bytesBuilder.add(_int64(expr.constIndex));
    return bytesBuilder.toBytes();
  }

  @override
  dynamic visitGroupExpr(GroupExpr expr) {}

  @override
  dynamic visitLiteralVectorExpr(LiteralVectorExpr expr) {}

  @override
  dynamic visitLiteralDictExpr(LiteralDictExpr expr) {}

  @override
  dynamic visitLiteralFunctionExpr(LiteralFunctionExpr expr) {}

  // @override
  // dynamic visitTypeExpr(TypeExpr expr) {}

  @override
  dynamic visitSymbolExpr(SymbolExpr expr) {}

  @override
  dynamic visitUnaryExpr(UnaryExpr expr) {}

  @override
  dynamic visitBinaryExpr(BinaryExpr expr) {
    final bytesBuilder = BytesBuilder();

    final left = _compileExpr(expr.left);
    bytesBuilder.add(left);
    bytesBuilder.addByte(HT_OpCode.reg1);
    final right = _compileExpr(expr.right);
    bytesBuilder.add(right);
    bytesBuilder.addByte(HT_OpCode.reg2);

    switch (expr.op.type) {
      case HT_Lexicon.add:
        bytesBuilder.addByte(HT_OpCode.add);
        break;
      default:
        bytesBuilder.addByte(HT_OpCode.error);
        bytesBuilder.addByte(HT_ErrorCode.binOp);
        break;
    }

    return bytesBuilder.toBytes();
  }

  @override
  dynamic visitCallExpr(CallExpr expr) {}

  @override
  dynamic visitAssignExpr(AssignExpr expr) {}

  @override
  dynamic visitSubGetExpr(SubGetExpr expr) {}

  @override
  dynamic visitSubSetExpr(SubSetExpr expr) {}

  @override
  dynamic visitMemberGetExpr(MemberGetExpr expr) {}

  @override
  dynamic visitMemberSetExpr(MemberSetExpr expr) {}

  @override
  dynamic visitImportStmt(ImportStmt stmt) {}

  @override
  dynamic visitExprStmt(ExprStmt stmt) => _compileExpr(stmt.expr);

  @override
  dynamic visitBlockStmt(BlockStmt stmt) {}

  @override
  dynamic visitReturnStmt(ReturnStmt stmt) {}

  @override
  dynamic visitIfStmt(IfStmt stmt) {}

  @override
  dynamic visitWhileStmt(WhileStmt stmt) {}

  @override
  dynamic visitBreakStmt(BreakStmt stmt) {}

  @override
  dynamic visitContinueStmt(ContinueStmt stmt) {}

  @override
  dynamic visitThisExpr(ThisExpr expr) {}

  @override
  dynamic visitVarDeclStmt(VarDeclStmt stmt) {}

  @override
  dynamic visitParamDeclStmt(ParamDeclStmt stmt) {}

  @override
  dynamic visitFuncDeclStmt(FuncDeclStmt stmt) {}

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {}

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {}
}
