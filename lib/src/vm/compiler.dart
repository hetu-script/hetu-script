import 'dart:typed_data';
import 'dart:convert';

import '../parser.dart';
import 'opcode.dart';
import '../token.dart';
import '../namespace.dart';
import '../common.dart';
import '../lexicon.dart';
import '../errors.dart';
import '../interpreter.dart';

class Compiler extends Parser {
  static const hetuSignatureData = [8, 5, 20, 21];
  static const hetuSignature = 134550549;
  static const hetuVersionData = [0, 1, 0, 0];

  String _curFileName = '';
  @override
  String get curFileName => _curFileName;

  // Uint8List compileTokens(List<Token> tokens, [ParseStyle style = ParseStyle.library]) {}
  late final HTNamespace _context;

  late bool _debugMode;

  // @override
  // dynamic visitBinaryExpr(BinaryExpr expr) {
  //   final bytesBuilder = BytesBuilder();

  //   final left = _compileExpr(expr.left);
  //   bytesBuilder.add(left);
  //   bytesBuilder.addByte(HTOpCode.reg1);
  //   final right = _compileExpr(expr.right);
  //   bytesBuilder.add(right);
  //   bytesBuilder.addByte(HTOpCode.reg2);

  //   switch (expr.op.type) {
  //     case HTLexicon.add:
  //       bytesBuilder.addByte(HTOpCode.add);
  //       break;
  //     default:
  //       bytesBuilder.addByte(HTOpCode.error);
  //       bytesBuilder.addByte(HTErrorCode.binOp);
  //       break;
  //   }

  //   return bytesBuilder.toBytes();
  // }

  Future<Uint8List> compile(List<Token> tokens, Interpreter interpreter, HTNamespace context, String fileName,
      [ParseStyle style = ParseStyle.library, debugMode = false]) async {
    _context = context;
    _debugMode = debugMode;
    this.tokens.clear();
    this.tokens.addAll(tokens);
    _curFileName = fileName;

    final bytesBuilderCode = BytesBuilder();

    while (curTok.type != HTLexicon.endOfFile) {
      // if (stmt is ImportStmt) {
      //   final savedFileName = _curFileName;
      //   final path = interpreter.workingDirectory + stmt.key;
      //   await interpreter.import(path, libName: stmt.namespace);
      //   _curFileName = savedFileName;
      //   interpreter.curFileName = savedFileName;
      // }
      bytesBuilderCode.add(_parseStmt(style: style));
    }
    _curFileName = '';

    final bytesBuilderMain = BytesBuilder();

    // 河图字节码标记
    bytesBuilderMain.add(hetuSignatureData);
    // 版本号
    bytesBuilderMain.add(hetuVersionData);
    // 调试模式
    bytesBuilderMain.addByte(_debugMode ? 1 : 0);
    // 预留
    bytesBuilderMain.addByte(0);

    bytesBuilderMain.addByte(HTOpCode.constTable);

    final constInt = _context.constInt;
    bytesBuilderMain.add(_uint16(constInt.length));
    for (var value in constInt) {
      bytesBuilderMain.add(_int64(value));
    }
    final constFloat = _context.constFloat;
    bytesBuilderMain.add(_uint16(constFloat.length));
    for (var value in constFloat) {
      bytesBuilderMain.add(_float64(value));
    }
    final constUtf8String = _context.constUtf8String;
    bytesBuilderMain.add(_uint16(constUtf8String.length));
    for (var value in constUtf8String) {
      bytesBuilderMain.add(_utf8String(value));
    }

    // the code
    bytesBuilderMain.add(bytesBuilderCode.toBytes());

    // end of file marker
    bytesBuilderMain.addByte(HTOpCode.subReturn);

    return bytesBuilderMain.toBytes();
  }

  Uint8List _uint16(int value) => Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);

  Uint8List _int64(int value) => Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);

  Uint8List _float64(double value) => Uint8List(8)..buffer.asByteData().setFloat64(0, value, Endian.big);

  Uint8List _utf8String(String value) {
    final bytesBuilder = BytesBuilder();
    final stringData = utf8.encoder.convert(value);
    bytesBuilder.add(_int64(stringData.length));
    bytesBuilder.add(stringData);
    return bytesBuilder.toBytes();
  }

  Uint8List _parseStmt({ParseStyle style = ParseStyle.library}) {
    // if (curTok.type == HTLexicon.newLine) advance(1);
    // switch (style) {
    //   case ParseStyle.library:
    // final isExtern = expect([HTLexicon.EXTERNAL], consume: true, error: false);
    // // import语句
    // if (expect([HTLexicon.IMPORT])) {
    //   return _parseImportStmt();
    // } // var变量声明
    // if (expect([HTLexicon.VAR])) {
    //   return _parseVarStmt(isExtern: isExtern, isDynamic: true);
    // } // let
    // else if (expect([HTLexicon.LET])) {
    //   return _parseVarStmt(isExtern: isExtern);
    // } // const
    // else if (expect([HTLexicon.CONST])) {
    //   return _parseVarStmt(isExtern: isExtern, isImmutable: true);
    // } // 类声明
    // else if (expect([HTLexicon.CLASS])) {
    //   return _parseClassDeclStmt(isExtern: isExtern);
    // } // 枚举类声明
    // else if (expect([HTLexicon.ENUM])) {
    //   return _parseEnumDeclStmt(isExtern: isExtern);
    // } // 函数声明
    // else if (expect([HTLexicon.FUN])) {
    //   return _parseFuncDeclaration(FunctionType.normal, isExtern: isExtern);
    // } else {
    //   throw HTErrorUnexpected(curTok.lexeme);
    // }
    // case ParseStyle.function:
    // 函数块中不能出现extern或者static关键字的声明
    // var变量声明
    // if (expect([HTLexicon.VAR])) {
    //   return _parseVarStmt(isDynamic: true);
    // } // let
    // else if (expect([HTLexicon.LET])) {
    //   return _parseVarStmt();
    // } // const
    // else if (expect([HTLexicon.CONST])) {
    //   return _parseVarStmt(isImmutable: true);
    // } // 函数声明
    // else if (expect([HTLexicon.FUN])) {
    //   return _parseFuncDeclaration(FunctionType.normal);
    // } // 赋值语句
    // else if (expect([HTLexicon.identifier, HTLexicon.assign])) {
    //   return _parseAssignStmt();
    // } //If语句
    // else if (expect([HTLexicon.IF])) {
    //   return _parseIfStmt();
    // } // While语句
    // else if (expect([HTLexicon.WHILE])) {
    //   return _parseWhileStmt();
    // } // For语句
    // else if (expect([HTLexicon.FOR])) {
    //   return _parseForStmt();
    // } // 跳出语句
    // else if (expect([HTLexicon.BREAK])) {
    //   return BreakStmt(advance(1));
    // } // 继续语句
    // else if (expect([HTLexicon.CONTINUE])) {
    //   return ContinueStmt(advance(1));
    // } // 返回语句
    // else if (curTok.type == HTLexicon.RETURN) {
    //   return _parseReturnStmt();
    // }
    // 表达式
    // else {
    return _parseExprStmt();
    // }
    // case ParseStyle.klass:
    // final isExtern = expect([HTLexicon.EXTERNAL], consume: true, error: false);
    // final isStatic = expect([HTLexicon.STATIC], consume: true, error: false);
    // // var变量声明
    // if (expect([HTLexicon.VAR])) {
    //   return _parseVarStmt(isExtern: isExtern, isStatic: isStatic, isDynamic: true);
    // } // let
    // else if (expect([HTLexicon.LET])) {
    //   return _parseVarStmt(isExtern: isExtern, isStatic: isStatic);
    // } // const
    // else if (expect([HTLexicon.CONST])) {
    //   if (!isStatic) throw HTErrorConstMustBeStatic(curTok.lexeme);
    //   return _parseVarStmt(isExtern: isExtern, isStatic: true, isImmutable: true);
    // } // 构造函数
    // else if (curTok.lexeme == HTLexicon.CONSTRUCT) {
    //   return _parseFuncDeclaration(FunctionType.constructor, isExtern: isExtern, isStatic: isStatic);
    // } // setter函数声明
    // else if (curTok.lexeme == HTLexicon.GET) {
    //   return _parseFuncDeclaration(FunctionType.getter, isExtern: isExtern, isStatic: isStatic);
    // } // getter函数声明
    // else if (curTok.lexeme == HTLexicon.SET) {
    //   return _parseFuncDeclaration(FunctionType.setter, isExtern: isExtern, isStatic: isStatic);
    // } // 成员函数声明
    // else if (expect([HTLexicon.FUN])) {
    //   return _parseFuncDeclaration(FunctionType.method, isExtern: isExtern, isStatic: isStatic);
    // } else {
    //   throw HTErrorUnexpected(curTok.lexeme);
    // }
    // case ParseStyle.externalClass:
    // expect([HTLexicon.EXTERNAL], consume: true, error: false);
    // final isStatic = expect([HTLexicon.STATIC], consume: true, error: false);
    // // var变量声明
    // if (expect([HTLexicon.VAR])) {
    //   return _parseVarStmt(isExtern: true, isStatic: isStatic, isDynamic: true);
    // } // let
    // else if (expect([HTLexicon.LET])) {
    //   return _parseVarStmt(isExtern: true, isStatic: isStatic);
    // } // const
    // else if (expect([HTLexicon.CONST])) {
    //   if (!isStatic) throw HTErrorConstMustBeStatic(curTok.lexeme);
    //   return _parseVarStmt(isExtern: true, isStatic: true, isImmutable: false);
    // } // 构造函数
    // else if (curTok.lexeme == HTLexicon.CONSTRUCT) {
    //   return _parseFuncDeclaration(FunctionType.constructor, isExtern: true, isStatic: isStatic);
    // } // setter函数声明
    // else if (curTok.lexeme == HTLexicon.GET) {
    //   return _parseFuncDeclaration(FunctionType.getter, isExtern: true, isStatic: isStatic);
    // } // getter函数声明
    // else if (curTok.lexeme == HTLexicon.SET) {
    //   return _parseFuncDeclaration(FunctionType.setter, isExtern: true, isStatic: isStatic);
    // } // 成员函数声明
    // else if (expect([HTLexicon.FUN])) {
    //   return _parseFuncDeclaration(FunctionType.method, isExtern: true, isStatic: isStatic);
    // } else {
    //   throw HTErrorUnexpected(curTok.lexeme);
    // }
    // }
  }

  // Uint8List _parseTypeId() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  //   // final type_name = advance(1).lexeme;
  //   // var type_args = <HTTypeId>[];
  //   // if (expect([HTLexicon.angleLeft], consume: true, error: false)) {
  //   //   while ((curTok.type != HTLexicon.angleRight) && (curTok.type != HTLexicon.endOfFile)) {
  //   //     type_args.add(_parseTypeId());
  //   //     expect([HTLexicon.comma], consume: true, error: false);
  //   //   }
  //   //   expect([HTLexicon.angleRight], consume: true);
  //   // }

  //   // return HTTypeId(type_name, arguments: type_args);
  // }

  Uint8List _debugInfo() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.debugInfo);
    final line = Uint8List(4)..buffer.asByteData().setInt32(0, curTok.line, Endian.big);
    bytesBuilder.add(line);
    final column = Uint8List(4)..buffer.asByteData().setInt32(0, curTok.column, Endian.big);
    bytesBuilder.add(column);
    final filename = utf8.encoder.convert(_curFileName);
    final filenameLength = Uint8List(1)..buffer.asByteData().setInt8(0, filename.length);
    bytesBuilder.add(filenameLength);
    bytesBuilder.add(filename);
    return bytesBuilder.toBytes();
  }

  Uint8List _literalnull() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.literal);
    bytesBuilder.addByte(HTOpRandType.nil);
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _literalbool(bool value) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.literal);
    bytesBuilder.addByte(HTOpRandType.boolean);
    bytesBuilder.addByte(value ? 1 : 0);
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _literal(int constIndex, int type) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.literal);
    bytesBuilder.addByte(type);
    bytesBuilder.add(_uint16(constIndex));
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    return bytesBuilder.toBytes();
  }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  Uint8List _parseExpr() => _parseAssignmentExpr();

  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  Uint8List _parseAssignmentExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseLogicalOrExpr());

    //   if (HTLexicon.assignments.contains(curTok.type)) {
    //     final op = advance(1);
    //     final value = _parseAssignmentExpr();

    //     if (expr is SymbolExpr) {
    //       return AssignExpr(expr.id, op, value);
    //     } else if (expr is MemberGetExpr) {
    //       return MemberSetExpr(expr.collection, expr.key, value);
    //     } else if (expr is SubGetExpr) {
    //       return SubSetExpr(expr.collection, expr.key, value);
    //     }

    //     throw HTErrorInvalidLeftValue(op.lexeme);
    //   }

    return bytesBuilder.toBytes();
  }

  /// 逻辑或 or ，优先级 5，左合并
  Uint8List _parseLogicalOrExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseLogicalAndExpr());
    //   while (curTok.type == HTLexicon.or) {
    //     final op = advance(1);
    //     final right = _parseLogicalAndExpr();
    //     expr = BinaryExpr(expr, op, right);
    //   }
    return bytesBuilder.toBytes();
  }

  /// 逻辑和 and ，优先级 6，左合并
  Uint8List _parseLogicalAndExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseEqualityExpr());
    //   while (curTok.type == HTLexicon.and) {
    //     final op = advance(1);
    //     final right = _parseEqualityExpr();
    //     expr = BinaryExpr(expr, op, right);
    //   }
    return bytesBuilder.toBytes();
  }

  /// 逻辑相等 ==, !=，优先级 7，无合并
  Uint8List _parseEqualityExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseRelationalExpr());
    //   while (HTLexicon.equalitys.contains(curTok.type)) {
    //     final op = advance(1);
    //     final right = _parseRelationalExpr();
    //     expr = BinaryExpr(expr, op, right);
    //   }
    return bytesBuilder.toBytes();
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，无合并
  Uint8List _parseRelationalExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseAdditiveExpr());
    //   while (HTLexicon.relationals.contains(curTok.type)) {
    //     final op = advance(1);
    //     final right = _parseAdditiveExpr();
    //     expr = BinaryExpr(expr, op, right);
    //   }
    return bytesBuilder.toBytes();
  }

  /// 加法 +, -，优先级 13，左合并
  Uint8List _parseAdditiveExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseMultiplicativeExpr());
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(25);
    while (HTLexicon.additives.contains(curTok.type)) {
      // left value
      final op = advance(1).type;
      // right value
      bytesBuilder.add(_parseMultiplicativeExpr());
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(26);
      switch (op) {
        case HTLexicon.add:
          bytesBuilder.addByte(HTOpCode.add);
          bytesBuilder.add([25, 26, 25]); // 寄存器 0 = 寄存器 1 + 寄存器 2
          break;
        case HTLexicon.subtract:
          bytesBuilder.addByte(HTOpCode.subtract);
          bytesBuilder.add([25, 26, 25]); // 寄存器 0 = 寄存器 1 - 寄存器 2
          break;
        default:
          bytesBuilder.addByte(HTOpCode.error);
          bytesBuilder.addByte(HTErrorCode.binOp);
          bytesBuilder.add([0, 1]);
      }
    }

    return bytesBuilder.toBytes();
  }

  /// 乘法 *, /, %，优先级 14，左合并
  Uint8List _parseMultiplicativeExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseUnaryPrefixExpr());
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(27);
    while (HTLexicon.multiplicatives.contains(curTok.type)) {
      // left value
      final op = advance(1).type;
      // right value
      bytesBuilder.add(_parseUnaryPrefixExpr());
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(28);
      switch (op) {
        case HTLexicon.multiply:
          bytesBuilder.addByte(HTOpCode.multiply);
          bytesBuilder.add([27, 28, 27]); // 寄存器 0 = 寄存器 1 + 寄存器 2
          break;
        case HTLexicon.devide:
          bytesBuilder.addByte(HTOpCode.devide);
          bytesBuilder.add([27, 28, 27]); // 寄存器 0 = 寄存器 1 - 寄存器 2
          break;
        case HTLexicon.modulo:
          bytesBuilder.addByte(HTOpCode.modulo);
          bytesBuilder.add([27, 28, 27]); // 寄存器 0 = 寄存器 1 - 寄存器 2
          break;
        default:
          bytesBuilder.addByte(HTOpCode.error);
          bytesBuilder.addByte(HTErrorCode.binOp);
          bytesBuilder.add([0, 1]);
      }
    }

    return bytesBuilder.toBytes();
  }

  /// 前缀 -e, !e，优先级 15，不能合并
  Uint8List _parseUnaryPrefixExpr() {
    final bytesBuilder = BytesBuilder();
    //   // 因为是前缀所以不能像别的表达式那样先进行下一级的分析
    //   ASTNode expr;
    //   if (HTLexicon.unaryPrefixs.contains(curTok.type)) {
    //     var op = advance(1);

    //     expr = UnaryExpr(op, _parseUnaryPostfixExpr());
    //   } else {
    bytesBuilder.add(_parseUnaryPostfixExpr());
    //   }
    return bytesBuilder.toBytes();
  }

  /// 后缀 e., e[], e()，优先级 16，取属性不能合并，下标和函数调用可以右合并
  Uint8List _parseUnaryPostfixExpr() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parsePrimaryExpr());
    //多层函数调用可以合并
    // while (true) {
    //   if (expect([HTLexicon.call], consume: true, error: false)) {
    //     var positionalArgs = <ASTNode>[];
    //     var namedArgs = <String, ASTNode>{};

    //     while ((curTok.type != HTLexicon.roundRight) && (curTok.type != HTLexicon.endOfFile)) {
    //       final arg = _parseExpr();
    //       if (expect([HTLexicon.colon], consume: false)) {
    //         if (arg is SymbolExpr) {
    //           advance(1);
    //           var value = _parseExpr();
    //           namedArgs[arg.id.lexeme] = value;
    //         } else {
    //           throw HTErrorUnexpected(
    //             curTok.lexeme,
    //           );
    //         }
    //       } else {
    //         positionalArgs.add(arg);
    //       }

    //       if (curTok.type != HTLexicon.roundRight) {
    //         expect([HTLexicon.comma], consume: true);
    //       }
    //     }
    //     expect([HTLexicon.roundRight], consume: true);
    //     expr = CallExpr(expr, positionalArgs, namedArgs);
    //   } else if (expect([HTLexicon.memberGet], consume: true, error: false)) {
    //     final name = match(HTLexicon.identifier);
    //     expr = MemberGetExpr(expr, name);
    //   } else if (expect([HTLexicon.subGet], consume: true, error: false)) {
    //     var index_expr = _parseExpr();
    //     expect([HTLexicon.squareRight], consume: true);
    //     expr = SubGetExpr(expr, index_expr);
    //   } else {
    //     break;
    //   }
    // }
    return bytesBuilder.toBytes();
  }

  /// 只有一个Token的简单表达式
  Uint8List _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.NULL:
        advance(1);
        return _literalnull();
      case HTLexicon.TRUE:
        advance(1);
        return _literalbool(true);
      case HTLexicon.FALSE:
        advance(1);
        return _literalbool(false);
      case HTLexicon.integer:
        var index = _context.addConstInt(curTok.literal);
        advance(1);
        return _literal(index, HTOpRandType.int64);
      case HTLexicon.float:
        var index = _context.addConstFloat(curTok.literal);
        advance(1);
        return _literal(index, HTOpRandType.float64);
      case HTLexicon.string:
        var index = _context.addConstString(curTok.literal);
        advance(1);
        return _literal(index, HTOpRandType.utf8String);
      // case HTLexicon.THIS:
      //   advance(1);
      //   return ThisExpr(peek(-1));
      // case HTLexicon.identifier:
      //   advance(1);
      //   return SymbolExpr(peek(-1));
      // case HTLexicon.roundLeft:
      //   advance(1);
      //   var innerExpr = _parseExpr();
      //   expect([HTLexicon.roundRight], consume: true);
      //   return GroupExpr(innerExpr);
      // case HTLexicon.squareLeft:
      //   final line = curTok.line;
      //   final column = advance(1).column;
      //   var list_expr = <ASTNode>[];
      //   while (curTok.type != HTLexicon.squareRight) {
      //     list_expr.add(_parseExpr());
      //     if (curTok.type != HTLexicon.squareRight) {
      //       expect([HTLexicon.comma], consume: true);
      //     }
      //   }
      //   expect([HTLexicon.squareRight], consume: true);
      //   return LiteralVectorExpr(_curFileName, line, column, list_expr);
      // case HTLexicon.curlyLeft:
      //   final line = curTok.line;
      //   final column = advance(1).column;
      //   var map_expr = <ASTNode, ASTNode>{};
      //   while (curTok.type != HTLexicon.curlyRight) {
      //     var key_expr = _parseExpr();
      //     expect([HTLexicon.colon], consume: true);
      //     var value_expr = _parseExpr();
      //     expect([HTLexicon.comma], consume: true, error: false);
      //     map_expr[key_expr] = value_expr;
      //   }
      //   expect([HTLexicon.curlyRight], consume: true);
      //   return LiteralDictExpr(_curFileName, line, column, map_expr);

      // case HTLexicon.FUN:
      //   return _parseFuncDeclaration(FunctionType.literal);

      default:
        throw HTErrorUnexpected(curTok.lexeme);
    }
  }

  // // Uint8List _parseBlock({ParseStyle style = ParseStyle.library}) {
  // //   final bytesBuilder = BytesBuilder();
  // //   return bytesBuilder.toBytes();
  // // }

  // // Uint8List _parseBlockStmt({ParseStyle style = ParseStyle.library}) {
  // //   final bytesBuilder = BytesBuilder();
  // //   return bytesBuilder.toBytes();
  // // }

  // Uint8List _parseImportStmt() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // /// 变量声明语句
  // Uint8List _parseVarStmt() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // /// 为了避免涉及复杂的左值右值问题，赋值语句在河图中不作为表达式处理
  // /// 而是分成直接赋值，取值后复制和取属性后复制
  // Uint8List _parseAssignStmt() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  Uint8List _parseExprStmt() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseExpr());
    bytesBuilder.addByte(HTOpCode.endOfStatement);
    return bytesBuilder.toBytes();
  }

  // Uint8List _parseReturnStmt() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // Uint8List _parseIfStmt() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // Uint8List _parseWhileStmt() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // /// For语句其实会在解析时转换为While语句
  // Uint8List _parseForStmt() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // Uint8List _parseParameters() {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // Uint8List _parseFuncDeclaration(FunctionType functype, {bool isExtern = false, bool isStatic = false}) {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // Uint8List _parseClassDeclStmt({bool isExtern = false}) {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }

  // Uint8List _parseEnumDeclStmt({bool isExtern = false}) {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }
}
