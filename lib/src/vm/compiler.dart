import 'dart:typed_data';
import 'dart:convert';

import '../parser.dart';
import 'opcode.dart';
import '../token.dart';
import '../common.dart';
import '../lexicon.dart';
import '../errors.dart';
import 'vm.dart';
import '../function.dart';

/// 声明空间，保存当前文件、类和函数体中包含的声明
/// 在编译后会提到整个代码块最前
class DeclarationBlock {
  final funcDecls = <String, Uint8List>{};
  final classDecls = <String, Uint8List>{};
  final varDecls = <String, Uint8List>{};

  bool contains(String id) => funcDecls.containsKey(id) || classDecls.containsKey(id) || varDecls.containsKey(id);
}

class Compiler extends Parser with VMRef {
  static const hetuSignatureData = [8, 5, 20, 21];
  static const hetuSignature = 134550549;
  static const hetuVersionData = [0, 1, 0, 0];

  String _curFileName = '';
  @override
  String get curFileName => _curFileName;

  final _constInt64 = <int>[];
  final _constFloat64 = <double>[];
  final _constUtf8String = <String>[];

  late final DeclarationBlock _globalBlock;
  late DeclarationBlock _curBlock;

  String? _curClassName;
  ClassType? _curClassType;

  late bool _debugMode;
  var _leftValueCheck = false;

  Future<Uint8List> compile(List<Token> tokens, HTVM interpreter, String fileName,
      [ParseStyle style = ParseStyle.module, debugMode = false]) async {
    this.interpreter = interpreter;
    _debugMode = debugMode;
    this.tokens.clear();
    this.tokens.addAll(tokens);
    _curFileName = fileName;

    _curBlock = _globalBlock = DeclarationBlock();

    final codeBytes = BytesBuilder();

    while (curTok.type != HTLexicon.endOfFile) {
      // if (stmt is ImportStmt) {
      //   final savedFileName = _curFileName;
      //   final path = interpreter.workingDirectory + stmt.key;
      //   await interpreter.import(path, libName: stmt.namespace);
      //   _curFileName = savedFileName;
      //   interpreter.curFileName = savedFileName;
      // }
      final exprStmts = _parseStmt(style: style);
      if (style == ParseStyle.block || style == ParseStyle.script) {
        codeBytes.add(exprStmts);
      }
    }

    _curFileName = '';

    final mainBytes = BytesBuilder();

    // 河图字节码标记
    mainBytes.addByte(HTOpCode.signature);
    mainBytes.add(hetuSignatureData);
    // 版本号
    mainBytes.addByte(HTOpCode.version);
    mainBytes.add(hetuVersionData);
    // 调试模式
    mainBytes.addByte(HTOpCode.debug);
    mainBytes.addByte(_debugMode ? 1 : 0);

    // 添加常量表
    mainBytes.addByte(HTOpCode.constTable);
    mainBytes.add(_uint16(_constInt64.length));
    for (var value in _constInt64) {
      mainBytes.add(_int64(value));
    }
    mainBytes.add(_uint16(_constFloat64.length));
    for (var value in _constFloat64) {
      mainBytes.add(_float64(value));
    }
    mainBytes.add(_uint16(_constUtf8String.length));
    for (var value in _constUtf8String) {
      mainBytes.add(_utf8String(value));
    }

    // 添加变量表，总是按照：函数、类、变量这个顺序
    mainBytes.addByte(HTOpCode.declTable);
    mainBytes.add(_uint16(_globalBlock.funcDecls.length));
    for (var decl in _globalBlock.funcDecls.values) {
      mainBytes.add(decl);
    }
    mainBytes.add(_uint16(_globalBlock.classDecls.length));
    for (var decl in _globalBlock.classDecls.values) {
      mainBytes.add(decl);
    }
    mainBytes.add(_uint16(_globalBlock.varDecls.length));
    for (var decl in _globalBlock.varDecls.values) {
      mainBytes.add(decl);
    }

    mainBytes.add(codeBytes.toBytes());

    // Return a module or a function result to interpreter.
    mainBytes.addByte(HTOpCode.endOfExec);

    return mainBytes.toBytes();
  }

  /// 0 to 65,535
  Uint8List _uint16(int value) => Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);

  /// 0 to 4,294,967,295
  // Uint8List _uint32(int value) => Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

  /// -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
  Uint8List _int64(int value) => Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);

  Uint8List _float64(double value) => Uint8List(8)..buffer.asByteData().setFloat64(0, value, Endian.big);

  Uint8List _shortUtf8String(String value) {
    final bytesBuilder = BytesBuilder();
    final stringData = utf8.encoder.convert(value);
    bytesBuilder.addByte(stringData.length);
    bytesBuilder.add(stringData);
    return bytesBuilder.toBytes();
  }

  Uint8List _utf8String(String value) {
    final bytesBuilder = BytesBuilder();
    final stringData = utf8.encoder.convert(value);
    bytesBuilder.add(_uint16(stringData.length));
    bytesBuilder.add(stringData);
    return bytesBuilder.toBytes();
  }

  // Fetch a utf8 string from the byte list
  String _readId(Uint8List bytes) {
    final length = bytes.first;
    return utf8.decoder.convert(bytes.sublist(1, length + 1));
  }

  Uint8List _parseStmt({ParseStyle style = ParseStyle.module}) {
    final bytesBuilder = BytesBuilder();
    // if (curTok.type == HTLexicon.newLine) advance(1);
    switch (style) {
      case ParseStyle.module:
        switch (curTok.type) {
          // case HTLexicon.EXTERNAL:
          //   advance(1);
          //   switch (curTok.type) {
          //     case HTLexicon.CLASS:
          //       return _parseClassDeclStmt(classType: ClassType.extern);
          //     case HTLexicon.ENUM:
          //       return _parseEnumDeclStmt(isExtern: true);
          //     case HTLexicon.VAR:
          //       return _parseVarStmt(isExtern: true, isDynamic: true);
          //     case HTLexicon.LET:
          //       return _parseVarStmt(isExtern: true);
          //     case HTLexicon.CONST:
          //       return _parseVarStmt(isExtern: true, isImmutable: true);
          //     case HTLexicon.FUN:
          //       return _parseFuncDeclaration(isExtern: true);
          //     default:
          //       throw HTErrorUnexpected(curTok.type);
          //   }
          // case HTLexicon.ABSTRACT:
          //   match(HTLexicon.CLASS);
          //   return _parseClassDeclStmt(classType: ClassType.abstracted);
          // case HTLexicon.INTERFACE:
          //   match(HTLexicon.CLASS);
          //   return _parseClassDeclStmt(classType: ClassType.interface);
          // case HTLexicon.MIXIN:
          //   match(HTLexicon.CLASS);
          //   return _parseClassDeclStmt(classType: ClassType.mix_in);
          case HTLexicon.CLASS:
            final decl = _parseClassDeclStmt();
            final id = _readId(decl);
            _curBlock.classDecls[id] = decl;
            break;
          // case HTLexicon.IMPORT:
          // return _parseImportStmt();
          case HTLexicon.VAR:
            final decl = _parseVarStmt(isDynamic: true);
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          case HTLexicon.LET:
            final decl = _parseVarStmt();
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          case HTLexicon.CONST:
            final decl = _parseVarStmt(isImmutable: true);
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          case HTLexicon.FUN:
            final decl = _parseFuncDeclaration();
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          default:
            throw HTErrorUnexpected(curTok.lexeme);
        }
        break;
      case ParseStyle.block:
        // 函数块中不能出现extern或者static关键字的声明
        switch (curTok.type) {
          // 变量声明
          case HTLexicon.VAR:
            final decl = _parseVarStmt(isDynamic: true);
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          case HTLexicon.LET:
            final decl = _parseVarStmt();
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          case HTLexicon.CONST:
            final decl = _parseVarStmt(isImmutable: true);
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          // 函数声明
          case HTLexicon.FUN:
            final decl = _parseFuncDeclaration();
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          case HTLexicon.RETURN:
            return _parseReturnStmt();
          // 表达式
          default:
            return _parseExprStmt();
        }
        break; //If语句
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
      case ParseStyle.klass:
        final isExtern = expect([HTLexicon.EXTERNAL], consume: true);
        final isStatic = expect([HTLexicon.STATIC], consume: true);
        switch (curTok.type) {
          // 变量声明
          case HTLexicon.VAR:
            final decl = _parseVarStmt(
                isDynamic: true,
                isExtern: isExtern || _curClassType == ClassType.extern,
                isMember: true,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          case HTLexicon.LET:
            final decl = _parseVarStmt(
                isExtern: isExtern || _curClassType == ClassType.extern, isMember: true, isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          case HTLexicon.CONST:
            final decl = _parseVarStmt(
                isExtern: isExtern || _curClassType == ClassType.extern,
                isImmutable: true,
                isMember: true,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.varDecls[id] = decl;
            break;
          // 函数声明
          case HTLexicon.FUN:
            final decl = _parseFuncDeclaration(
                funcType: FunctionType.method,
                isExtern: isExtern || _curClassType == ClassType.extern,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          case HTLexicon.CONSTRUCT:
            final decl = _parseFuncDeclaration(
                funcType: FunctionType.constructor, isExtern: isExtern || _curClassType == ClassType.extern);
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          case HTLexicon.GET:
            final decl = _parseFuncDeclaration(
                funcType: FunctionType.getter,
                isExtern: isExtern || _curClassType == ClassType.extern,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          case HTLexicon.SET:
            final decl = _parseFuncDeclaration(
                funcType: FunctionType.setter,
                isExtern: isExtern || _curClassType == ClassType.extern,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          default:
            throw HTErrorUnexpected(curTok.lexeme);
        }
        break;
      case ParseStyle.script:
        break;
    }

    return bytesBuilder.toBytes();
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
  //   //   match(HTLexicon.angleRight);
  //   // }

  //   // return HTTypeId(type_name, arguments: type_args);
  // }

  Uint8List _debugInfo() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.debugInfo);
    final line = Uint8List(4)..buffer.asByteData().setUint32(0, curTok.line, Endian.big);
    bytesBuilder.add(line);
    final column = Uint8List(4)..buffer.asByteData().setUint32(0, curTok.column, Endian.big);
    bytesBuilder.add(column);
    final filename = _shortUtf8String(_curFileName);
    bytesBuilder.add(filename);
    return bytesBuilder.toBytes();
  }

  Uint8List _localNull() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.NULL);
    return bytesBuilder.toBytes();
  }

  Uint8List _localBool(bool value) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.boolean);
    bytesBuilder.addByte(value ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  Uint8List _localConst(int constIndex, int type) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(type);
    bytesBuilder.add(_uint16(constIndex));
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _localSymbol(String id) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.symbol);
    bytesBuilder.add(_shortUtf8String(id));
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _localGroup(Uint8List innerExpr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.group);
    // bytesBuilder.add(_uint16(innerExpr.length + 1));
    bytesBuilder.add(innerExpr);
    bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _localList(List<Uint8List> exprList) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.list);
    bytesBuilder.add(_uint16(exprList.length));
    for (final expr in exprList) {
      bytesBuilder.add(expr);
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _localMap(Map<Uint8List, Uint8List> exprMap) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.map);
    bytesBuilder.add(_uint16(exprMap.length));
    for (final key in exprMap.keys) {
      bytesBuilder.add(key);
      bytesBuilder.addByte(HTOpCode.endOfExec);
      bytesBuilder.add(exprMap[key]!);
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  ///
  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  ///
  /// [endOfExec] 指是否在解析完表达式后中断执行，这样可以返回当前表达式的值
  Uint8List _parseExpr({bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    _leftValueCheck = true;
    final left = _parseLogicalOrExpr();
    bytesBuilder.add(left);
    if (HTLexicon.assignments.contains(curTok.type)) {
      if (_leftValueCheck) {
        bytesBuilder.addByte(HTOpCode.leftValue);
      } else {
        throw HTErrorIllegalLeftValueCompiler();
      }
      final right = BytesBuilder();
      late String op;
      while (HTLexicon.assignments.contains(curTok.type)) {
        op = advance(1).type;
        right.add(_parseExpr()); // 这里需要右合并，因此没有降到下一级
      }
      bytesBuilder.add(right.toBytes());
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(0);
      switch (op) {
        case HTLexicon.assign:
          bytesBuilder.addByte(HTOpCode.assign);
          break;
        case HTLexicon.assignMultiply:
          bytesBuilder.addByte(HTOpCode.assignMultiply);
          break;
        case HTLexicon.assignDevide:
          bytesBuilder.addByte(HTOpCode.assignDevide);
          break;
        case HTLexicon.assignAdd:
          bytesBuilder.addByte(HTOpCode.assignAdd);
          break;
        case HTLexicon.assignSubtract:
          bytesBuilder.addByte(HTOpCode.assignSubtract);
          break;
      }
      bytesBuilder.add([0]);
    }
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }

    return bytesBuilder.toBytes();
  }

  /// 逻辑或 or ，优先级 5，左合并
  Uint8List _parseLogicalOrExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseLogicalAndExpr();
    bytesBuilder.add(left);
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueCheck = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(1);
      while (curTok.type == HTLexicon.logicalOr) {
        advance(1); // or operator
        final right = _parseLogicalAndExpr();
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(2);
        bytesBuilder.addByte(HTOpCode.logicalOr);
        bytesBuilder.add([1, 2]);
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 逻辑和 and ，优先级 6，左合并
  Uint8List _parseLogicalAndExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseEqualityExpr();
    bytesBuilder.add(left);
    if (curTok.type == HTLexicon.logicalAnd) {
      _leftValueCheck = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(3);
      while (curTok.type == HTLexicon.logicalAnd) {
        advance(1); // and operator
        final right = _parseEqualityExpr();
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(4);
        bytesBuilder.addByte(HTOpCode.logicalAnd);
        bytesBuilder.add([3, 4]);
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 逻辑相等 ==, !=，优先级 7，不合并
  Uint8List _parseEqualityExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseRelationalExpr();
    bytesBuilder.add(left);
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueCheck = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(5);
      final op = advance(1).type;
      final right = _parseRelationalExpr();
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(6);
      switch (op) {
        case HTLexicon.equal:
          bytesBuilder.addByte(HTOpCode.equal);
          break;
        case HTLexicon.notEqual:
          bytesBuilder.addByte(HTOpCode.notEqual);
          break;
      }
      bytesBuilder.add([5, 6]);
    }
    return bytesBuilder.toBytes();
  }

  /// 逻辑比较 <, >, <=, >=，优先级 8，不合并
  Uint8List _parseRelationalExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseAdditiveExpr();
    bytesBuilder.add(left);
    if (HTLexicon.relationals.contains(curTok.type)) {
      _leftValueCheck = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(7);
      final op = advance(1).type;
      final right = _parseAdditiveExpr();
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(8);
      switch (op) {
        case HTLexicon.lesser:
          bytesBuilder.addByte(HTOpCode.lesser);
          break;
        case HTLexicon.greater:
          bytesBuilder.addByte(HTOpCode.greater);
          break;
        case HTLexicon.lesserOrEqual:
          bytesBuilder.addByte(HTOpCode.lesserOrEqual);
          break;
        case HTLexicon.greaterOrEqual:
          bytesBuilder.addByte(HTOpCode.greaterOrEqual);
          break;
      }
      bytesBuilder.add([7, 8]);
    }
    return bytesBuilder.toBytes();
  }

  /// 加法 +, -，优先级 13，左合并
  Uint8List _parseAdditiveExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseMultiplicativeExpr();
    bytesBuilder.add(left);
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueCheck = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(9);
      while (HTLexicon.additives.contains(curTok.type)) {
        final op = advance(1).type;
        final right = _parseMultiplicativeExpr();
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(10);
        switch (op) {
          case HTLexicon.add:
            bytesBuilder.addByte(HTOpCode.add);
            break;
          case HTLexicon.subtract:
            bytesBuilder.addByte(HTOpCode.subtract);
            break;
        }
        bytesBuilder.add([9, 10]); // 寄存器 0 = 寄存器 1 - 寄存器 2
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 乘法 *, /, %，优先级 14，左合并
  Uint8List _parseMultiplicativeExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseUnaryPrefixExpr();
    bytesBuilder.add(left);
    if (HTLexicon.multiplicatives.contains(curTok.type)) {
      _leftValueCheck = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(11);
      while (HTLexicon.multiplicatives.contains(curTok.type)) {
        final op = advance(1).type;
        final right = _parseUnaryPrefixExpr();
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(12);
        switch (op) {
          case HTLexicon.multiply:
            bytesBuilder.addByte(HTOpCode.multiply);
            break;
          case HTLexicon.devide:
            bytesBuilder.addByte(HTOpCode.devide);
            break;
          case HTLexicon.modulo:
            bytesBuilder.addByte(HTOpCode.modulo);
            break;
        }
        bytesBuilder.add([11, 12]); // 寄存器 0 = 寄存器 1 + 寄存器 2
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 前缀 -e, !e，++e, --e, 优先级 15，不合并
  Uint8List _parseUnaryPrefixExpr() {
    final bytesBuilder = BytesBuilder();
    // 因为是前缀所以要先判断操作符
    if (HTLexicon.unaryPrefixs.contains(curTok.type)) {
      _leftValueCheck = false;
      var op = advance(1).type;
      final value = _parseUnaryPostfixExpr();
      bytesBuilder.add(value);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(13);
      switch (op) {
        case HTLexicon.negative:
          bytesBuilder.addByte(HTOpCode.negative);
          break;
        case HTLexicon.logicalNot:
          bytesBuilder.addByte(HTOpCode.logicalNot);
          break;
        case HTLexicon.preIncrement:
          bytesBuilder.addByte(HTOpCode.preIncrement);
          break;
        case HTLexicon.preDecrement:
          bytesBuilder.addByte(HTOpCode.preDecrement);
          break;
      }
      bytesBuilder.addByte(13);
    } else {
      final value = _parseUnaryPostfixExpr();
      bytesBuilder.add(value);
    }
    return bytesBuilder.toBytes();
  }

  /// 后缀 e., e[], e(), e++, e-- 优先级 16，右合并
  Uint8List _parseUnaryPostfixExpr() {
    final bytesBuilder = BytesBuilder();
    final value = _parseLocalExpr();
    bytesBuilder.add(value);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(14);
    if (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
        final op = advance(1).type;
        switch (op) {
          case HTLexicon.memberGet:
            final key = match(HTLexicon.identifier).lexeme;
            bytesBuilder.addByte(HTOpCode.memberGet);
            bytesBuilder.addByte(14);
            bytesBuilder.add(_shortUtf8String(key));
            break;
          case HTLexicon.subGet:
            final key = _parseExpr(endOfExec: true);
            bytesBuilder.addByte(HTOpCode.subGet);
            bytesBuilder.addByte(14);

            break;
          case HTLexicon.call:
            _leftValueCheck = false;
            final positionalArgs = <Uint8List>[];
            final namedArgs = <String, Uint8List>{};
            while ((curTok.type != HTLexicon.roundRight) && (curTok.type != HTLexicon.endOfFile)) {
              if (expect([HTLexicon.identifier, HTLexicon.colon], consume: false)) {
                final name = advance(2).lexeme;
                namedArgs[name] = _parseExpr(endOfExec: true);
              } else {
                positionalArgs.add(_parseExpr(endOfExec: true));
              }
              if (curTok.type != HTLexicon.roundRight) {
                match(HTLexicon.comma);
              }
            }
            match(HTLexicon.roundRight);
            bytesBuilder.addByte(HTOpCode.call);
            bytesBuilder.addByte(14);
            bytesBuilder.addByte(positionalArgs.length);
            for (var i = 0; i < positionalArgs.length; ++i) {
              bytesBuilder.add(positionalArgs[i]);
            }
            bytesBuilder.addByte(namedArgs.length);
            for (final name in namedArgs.keys) {
              bytesBuilder.add(_shortUtf8String(name));
              bytesBuilder.add(namedArgs[name]!);
            }
            break;
          case HTLexicon.postIncrement:
            _leftValueCheck = false;
            bytesBuilder.addByte(HTOpCode.postIncrement);
            bytesBuilder.addByte(14);
            break;
          case HTLexicon.postDecrement:
            _leftValueCheck = false;
            bytesBuilder.addByte(HTOpCode.postDecrement);
            bytesBuilder.addByte(14);
            break;
        }
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 优先级最高的表达式
  Uint8List _parseLocalExpr() {
    switch (curTok.type) {
      case HTLexicon.NULL:
        _leftValueCheck = false;
        advance(1);
        return _localNull();
      case HTLexicon.TRUE:
        _leftValueCheck = false;
        advance(1);
        return _localBool(true);
      case HTLexicon.FALSE:
        _leftValueCheck = false;
        advance(1);
        return _localBool(false);
      case HTLexicon.integer:
        _leftValueCheck = false;
        _constInt64.add(curTok.literal);
        final index = _constInt64.length - 1;
        advance(1);
        return _localConst(index, HTValueTypeCode.int64);
      case HTLexicon.float:
        _leftValueCheck = false;
        _constFloat64.add(curTok.literal);
        final index = _constFloat64.length - 1;
        advance(1);
        return _localConst(index, HTValueTypeCode.float64);
      case HTLexicon.string:
        _leftValueCheck = false;
        _constUtf8String.add(curTok.literal);
        final index = _constUtf8String.length - 1;
        advance(1);
        return _localConst(index, HTValueTypeCode.utf8String);
      case HTLexicon.identifier:
        return _localSymbol(advance(1).lexeme);
      case HTLexicon.roundLeft:
        _leftValueCheck = false;
        advance(1);
        var innerExpr = _parseExpr();
        match(HTLexicon.roundRight);
        return _localGroup(innerExpr);
      case HTLexicon.squareLeft:
        _leftValueCheck = false;
        advance(1);
        final exprList = <Uint8List>[];
        while (curTok.type != HTLexicon.squareRight) {
          exprList.add(_parseExpr());
          if (curTok.type != HTLexicon.squareRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.squareRight);
        return _localList(exprList);
      case HTLexicon.curlyLeft:
        _leftValueCheck = false;
        advance(1);
        var exprMap = <Uint8List, Uint8List>{};
        while (curTok.type != HTLexicon.curlyRight) {
          var key = _parseExpr();
          match(HTLexicon.colon);
          var value = _parseExpr();
          exprMap[key] = value;
          if (curTok.type != HTLexicon.curlyRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.curlyRight);
        return _localMap(exprMap);

      // case HTLexicon.THIS:
      //   advance(1);
      //   return ThisExpr(peek(-1));
      // case HTLexicon.FUN:
      //   return _parseFuncDeclaration(FunctionType.literal);

      default:
        throw HTErrorUnexpected(curTok.lexeme);
    }
  }

  Uint8List _parseBlock({ParseStyle style = ParseStyle.block, bool endOfExec = false}) {
    match(HTLexicon.curlyLeft);
    final bytesBuilder = BytesBuilder();
    final declsBytesBuilder = BytesBuilder();
    final blockBytesBuilder = BytesBuilder();
    final savedDeclBlock = _curBlock;
    _curBlock = DeclarationBlock();
    while (curTok.type != HTLexicon.curlyRight && curTok.type != HTLexicon.endOfFile) {
      blockBytesBuilder.add(_parseStmt(style: style));
    }
    // 添加变量表，总是按照：函数、类、变量这个顺序
    declsBytesBuilder.addByte(HTOpCode.declTable);
    declsBytesBuilder.add(_uint16(_curBlock.funcDecls.length));
    for (var decl in _curBlock.funcDecls.values) {
      declsBytesBuilder.add(decl);
    }
    declsBytesBuilder.add(_uint16(_curBlock.classDecls.length));
    for (var decl in _curBlock.classDecls.values) {
      declsBytesBuilder.add(decl);
    }
    declsBytesBuilder.add(_uint16(_curBlock.varDecls.length));
    for (var decl in _curBlock.varDecls.values) {
      declsBytesBuilder.add(decl);
    }
    _curBlock = savedDeclBlock;
    match(HTLexicon.curlyRight);
    bytesBuilder.add(declsBytesBuilder.toBytes());
    bytesBuilder.add(blockBytesBuilder.toBytes());
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  // Uint8List _parseImportStmt() {
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
    return bytesBuilder.toBytes();
  }

  Uint8List _parseReturnStmt() {
    advance(1); // keyword

    final bytesBuilder = BytesBuilder();
    if (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.semicolon &&
        curTok.type != HTLexicon.endOfFile) {
      bytesBuilder.add(_parseExpr(endOfExec: true));
    }
    expect([HTLexicon.semicolon], consume: true);

    return bytesBuilder.toBytes();
  }

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

  /// 变量声明语句
  Uint8List _parseVarStmt(
      {bool isDynamic = false,
      bool isExtern = false,
      bool isImmutable = false,
      bool isMember = false,
      bool isStatic = false}) {
    advance(1);
    final id = match(HTLexicon.identifier).lexeme;

    if (_curBlock.contains(id)) {
      throw HTErrorDefinedParser(id);
    }

    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(isDynamic ? 1 : 0);
    bytesBuilder.addByte(isExtern ? 1 : 0);
    bytesBuilder.addByte(isImmutable ? 1 : 0);
    bytesBuilder.addByte(isMember ? 1 : 0);
    bytesBuilder.addByte(isStatic ? 1 : 0);

    // var decl_type;
    // if (expect([HTLexicon.colon], consume: true, error: false)) {
    //   decl_type = _parseTypeId();
    // }

    if (expect([HTLexicon.assign], consume: true)) {
      final initializer = _parseExpr(endOfExec: true);
      bytesBuilder.addByte(1);
      bytesBuilder.add(_uint16(initializer.length));
      bytesBuilder.add(initializer);
    } else {
      bytesBuilder.addByte(0);
    }
    // 语句结尾
    expect([HTLexicon.semicolon], consume: true);

    return bytesBuilder.toBytes();
  }

  Uint8List _parseFuncDeclaration(
      {FunctionType funcType = FunctionType.normal,
      bool isExtern = false,
      bool isStatic = false,
      bool isConst = false}) {
    advance(1);
    String? declId;
    late final id;
    if (curTok.type == HTLexicon.identifier) {
      declId = advance(1).lexeme;
    }

    switch (funcType) {
      case FunctionType.constructor:
        id = (declId == null) ? _curClassName! : '${_curClassName!}.$declId';
        break;
      case FunctionType.getter:
        if (_curBlock.contains(declId!)) {
          throw HTErrorDefinedParser(declId);
        }
        id = HTLexicon.getter + declId;
        break;
      case FunctionType.setter:
        if (_curBlock.contains(declId!)) {
          throw HTErrorDefinedParser(declId);
        }
        id = HTLexicon.setter + declId;
        break;
      default:
        id = declId ?? HTLexicon.anonymousFunction + (HTFunction.anonymousIndex++).toString();
    }

    if (_curBlock.contains(id)) {
      throw HTErrorDefinedParser(id);
    }

    final funcBytesBuilder = BytesBuilder();
    if (id != null) {
      // funcBytesBuilder.addByte(HTOpCode.funcDecl);
      funcBytesBuilder.add(_shortUtf8String(id));
      funcBytesBuilder.addByte(funcType.index);
      funcBytesBuilder.addByte(isExtern ? 1 : 0);
      funcBytesBuilder.addByte(isStatic ? 1 : 0);
      funcBytesBuilder.addByte(isConst ? 1 : 0);
    } else {
      funcBytesBuilder.addByte(HTOpCode.local);
      funcBytesBuilder.addByte(HTValueTypeCode.function);
    }

    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <Uint8List>[];

    if (funcType != FunctionType.getter && expect([HTLexicon.roundLeft], consume: true)) {
      var isOptional = false;
      var isNamed = false;
      while ((curTok.type != HTLexicon.roundRight) &&
          (curTok.type != HTLexicon.squareRight) &&
          (curTok.type != HTLexicon.curlyRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        // 可选参数，根据是否有方括号判断，一旦开始了可选参数，则不再增加参数数量arity要求
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            //检查命名参数，根据是否有花括号判断
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }

        var isVariadic = false;
        if (!isNamed) {
          isVariadic = expect([HTLexicon.varargs], consume: true);
        }

        if (!isNamed && !isVariadic) {
          if (!isOptional) {
            ++minArity;
            ++maxArity;
          } else {
            ++maxArity;
          }
        }

        final paramBytesBuilder = BytesBuilder();
        var paramId = match(HTLexicon.identifier).lexeme;
        paramBytesBuilder.add(_shortUtf8String(paramId));
        paramBytesBuilder.addByte(isOptional ? 1 : 0);
        paramBytesBuilder.addByte(isNamed ? 1 : 0);
        paramBytesBuilder.addByte(isVariadic ? 1 : 0);

        // HTTypeId? declType;
        // if (expect([HTLexicon.colon], consume: true, error: false)) {
        //   declType = _parseTypeId();
        // }

        Uint8List? initializer;
        //参数默认值
        if ((isOptional || isNamed) && (expect([HTLexicon.assign], consume: true))) {
          initializer = _parseExpr();
          paramBytesBuilder.addByte(1); // bool，表示有初始化表达式
          paramBytesBuilder.add(_uint16(initializer.length + 1));
          paramBytesBuilder.add(initializer);
        } else {
          paramBytesBuilder.addByte(0);
        }
        paramDecls.add(paramBytesBuilder.toBytes());

        if (curTok.type != HTLexicon.squareRight &&
            curTok.type != HTLexicon.curlyRight &&
            curTok.type != HTLexicon.roundRight) {
          match(HTLexicon.comma);
        }

        if (isVariadic) {
          isFuncVariadic = true;
          break;
        }
      }

      if (isOptional) {
        match(HTLexicon.squareRight);
      } else if (isNamed) {
        match(HTLexicon.curlyRight);
      }

      match(HTLexicon.roundRight);

      // setter只能有一个参数，就是赋值语句的右值，但此处并不需要判断类型
      if ((funcType == FunctionType.setter) && (minArity != 1)) {
        throw HTErrorSetter();
      }
    }

    funcBytesBuilder.addByte(isFuncVariadic ? 1 : 0);

    // var return_type = HTTypeId.ANY;
    // if ((funcType != FunctionType.constructor) && (expect([HTLexicon.colon], consume: true, error: false))) {
    //   return_type = _parseTypeId();
    // }

    funcBytesBuilder.addByte(minArity);
    funcBytesBuilder.addByte(maxArity);
    funcBytesBuilder.addByte(paramDecls.length); // max 255
    for (var decl in paramDecls) {
      funcBytesBuilder.add(decl);
    }

    // 处理函数定义部分的语句块
    if (curTok.type == HTLexicon.curlyLeft) {
      funcBytesBuilder.addByte(1); // bool: has definition
      final body = _parseBlock(endOfExec: true);
      funcBytesBuilder.add(_uint16(body.length)); // definition bytes length
      funcBytesBuilder.add(body);
    } else {
      funcBytesBuilder.addByte(0); // bool: has no definition
    }

    expect([HTLexicon.semicolon], consume: true);

    return funcBytesBuilder.toBytes();
  }

  Uint8List _parseClassDeclStmt({ClassType classType = ClassType.normal}) {
    advance(1); // keyword
    final id = match(HTLexicon.identifier).lexeme;

    if (_curBlock.contains(id)) {
      throw HTErrorDefinedParser(id);
    }

    final savedClassName = _curClassName;
    _curClassName = id;
    final savedClassType = _curClassType;
    _curClassType = classType;

    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(classType.index);

    String? superClassId;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      superClassId = advance(1).lexeme;
      if (superClassId == id) {
        throw HTErrorUnexpected(id);
      } else if (!_curBlock.classDecls.containsKey(id)) {
        throw HTErrorNotClass(curTok.lexeme);
      }

      bytesBuilder.addByte(1); // bool: has super class
      bytesBuilder.add(_shortUtf8String(superClassId));

      // if (expect([HTLexicon.angleLeft], consume: true)) {
      //   // 泛型参数
      //   super_class_type_args = _parseTypeId();
      //   match(HTLexicon.angleRight);
      // }
    } else {
      bytesBuilder.addByte(0); // bool: has super class
    }

    final classDefinition = _parseBlock(style: ParseStyle.klass);

    bytesBuilder.add(classDefinition);
    bytesBuilder.addByte(HTOpCode.endOfExec);

    _curClassName = savedClassName;
    _curClassType = savedClassType;
    return bytesBuilder.toBytes();
  }

  // Uint8List _parseEnumDeclStmt({bool isExtern = false}) {
  //   final bytesBuilder = BytesBuilder();
  //   return bytesBuilder.toBytes();
  // }
}
