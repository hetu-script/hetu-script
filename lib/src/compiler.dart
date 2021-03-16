import 'dart:typed_data';
import 'dart:convert';

import 'expression.dart';
import 'parser.dart' show ParseStyle;

import 'opcode.dart';
import 'token.dart';
import 'lexicon.dart';
import 'context.dart';

class Compiler implements ASTNodeVisitor {
  static const hetuSignatureData = [8, 5, 20, 21];
  static const hetuSignature = 134550549;
  static const hetuVersionData = [0, 1, 0, 0, 0, 0];
  int _curLine = 0;
  @override
  int get curLine => _curLine;
  int _curColumn = 0;
  @override
  int get curColumn => _curColumn;
  String _curFileName = '';
  @override
  String get curFileName => _curFileName;

  // Uint8List compileTokens(List<Token> tokens, [ParseStyle style = ParseStyle.library]) {}
  late HTContext _context;

  late BytesBuilder _bytesBuilder;

  Uint8List compileAST(List<ASTNode> statements, HTContext context, String fileName,
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

  Uint8List _compileExpr(ASTNode expr) => expr.accept(this);

  Uint8List _compileStmt(ASTNode stmt) => stmt.accept(this);

  @override
  dynamic visitNullExpr(NullExpr expr) {}

  @override
  dynamic visitBooleanExpr(BooleanExpr expr) {}

  @override
  dynamic visitConstIntExpr(ConstIntExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTOpRandType.constInt64);
    bytesBuilder.add(_int64(expr.constIndex));
    return bytesBuilder.toBytes();
  }

  @override
  dynamic visitConstFloatExpr(ConstFloatExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTOpRandType.constFloat64);
    bytesBuilder.add(_int64(expr.constIndex));
    return bytesBuilder.toBytes();
  }

  @override
  dynamic visitConstStringExpr(ConstStringExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTOpRandType.constUtf8String);
    bytesBuilder.add(_int64(expr.constIndex));
    return bytesBuilder.toBytes();
  }

  @override
  dynamic visitGroupExpr(GroupExpr expr) {}

  @override
  dynamic visitLiteralVectorExpr(LiteralVectorExpr expr) {}

  @override
  dynamic visitLiteralDictExpr(LiteralDictExpr expr) {}

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
    bytesBuilder.addByte(HTOpCode.reg1);
    final right = _compileExpr(expr.right);
    bytesBuilder.add(right);
    bytesBuilder.addByte(HTOpCode.reg2);

    switch (expr.op.type) {
      case HTLexicon.add:
        bytesBuilder.addByte(HTOpCode.add);
        break;
      default:
        bytesBuilder.addByte(HTOpCode.error);
        bytesBuilder.addByte(HTErrorCode.binOp);
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
  dynamic visitFuncDeclStmt(FuncDeclaration stmt) {}

  @override
  dynamic visitClassDeclStmt(ClassDeclStmt stmt) {}

  @override
  dynamic visitEnumDeclStmt(EnumDeclStmt stmt) {}
}
