import 'dart:typed_data';
import 'dart:convert';

import 'opcode.dart';
import 'vm.dart';
import '../parser.dart';
import '../token.dart';
import '../common.dart';
import '../lexicon.dart';
import '../errors.dart';
import '../function.dart';
import '../const_table.dart';

class HTRegIdx {
  static const value = 0;
  static const symbol = 1;
  static const objectSymbol = 2;
  static const refType = 3;
  static const loopCount = 4;
  static const assign = 7;
  static const orLeft = 8;
  static const andLeft = 9;
  static const equalLeft = 10;
  static const relationLeft = 11;
  static const addLeft = 12;
  static const multiplyLeft = 13;
  static const postfixObject = 14;
  static const postfixKey = 15;

  static const length = 16;
}

class _DeclarationBlock {
  final enumDecls = <String, Uint8List>{};
  final funcDecls = <String, Uint8List>{};
  final classDecls = <String, Uint8List>{};
  final varDecls = <String, Uint8List>{};

  bool contains(String id) =>
      funcDecls.containsKey(id) ||
      classDecls.containsKey(id) ||
      varDecls.containsKey(id);
}

class _ImportInfo {
  final String key;
  final String? name;
  final List<String> showList;
  _ImportInfo(this.key, {this.name, this.showList = const []});
}

/// Utility class that parse a string content into a uint8 list
class Compiler extends Parser with ConstTable, HetuRef {
  /// Hetu script bytecode's unique header
  static const hetuSignatureData = [8, 5, 20, 21];

  /// The version of the compiled bytecode,
  /// used to determine compatibility.
  static const hetuVersionData = [0, 1, 0, 0];

  late _DeclarationBlock _globalBlock;
  late _DeclarationBlock _curBlock;

  final _importedModules = <_ImportInfo>[];

  late String _curModuleUniqueKey;

  /// The module current processing, used in error message.
  @override
  String get curModuleUniqueKey => _curModuleUniqueKey;
  String? _curClassName;
  ClassType? _curClassType;

  late bool _debugMode;
  late bool _bundleMode;

  var _leftValueLegality = false;

  /// Create a compiler, needed an interpreter ref
  /// for importing another module during compilation
  Compiler(Hetu interpreter) {
    this.interpreter = interpreter;
  }

  /// Compiles a Token list.
  Future<Uint8List> compile(
      List<Token> tokens, Hetu interpreter, String moduleUniqueKey,
      {CodeType codeType = CodeType.module,
      debugMode = false,
      bool bundleMode = false}) async {
    _bundleMode = bundleMode;
    _debugMode = _bundleMode ? false : debugMode;
    _curModuleUniqueKey = moduleUniqueKey;

    _curBlock = _globalBlock = _DeclarationBlock();

    final code = _compile(tokens, codeType);

    for (final importInfo in _importedModules) {
      if (bundleMode) {
      } else {
        await interpreter.import(importInfo.key,
            curModuleUniqueKey: moduleUniqueKey,
            moduleName: importInfo.name,
            debugMode: _debugMode);
      }
    }

    final mainBuilder = BytesBuilder();
    // 河图字节码标记
    mainBuilder.addByte(HTOpCode.signature);
    mainBuilder.add(hetuSignatureData);
    // 版本号
    mainBuilder.addByte(HTOpCode.version);
    mainBuilder.add(hetuVersionData);
    // 调试模式
    mainBuilder.addByte(HTOpCode.debug);
    mainBuilder.addByte(_debugMode ? 1 : 0);
    // 添加常量表
    mainBuilder.addByte(HTOpCode.constTable);
    mainBuilder.add(_uint16(intTable.length));
    for (final value in intTable) {
      mainBuilder.add(_int64(value));
    }
    mainBuilder.add(_uint16(floatTable.length));
    for (final value in floatTable) {
      mainBuilder.add(_float64(value));
    }
    mainBuilder.add(_uint16(stringTable.length));
    for (final value in stringTable) {
      mainBuilder.add(_utf8String(value));
    }
    // 添加变量表，总是按照：函数、类、变量这个顺序
    mainBuilder.addByte(HTOpCode.declTable);
    mainBuilder.add(_uint16(_globalBlock.enumDecls.length));
    for (final decl in _globalBlock.enumDecls.values) {
      mainBuilder.add(decl);
    }
    mainBuilder.add(_uint16(_globalBlock.funcDecls.length));
    for (final decl in _globalBlock.funcDecls.values) {
      mainBuilder.add(decl);
    }
    mainBuilder.add(_uint16(_globalBlock.classDecls.length));
    for (final decl in _globalBlock.classDecls.values) {
      mainBuilder.add(decl);
    }
    mainBuilder.add(_uint16(_globalBlock.varDecls.length));
    for (final decl in _globalBlock.varDecls.values) {
      mainBuilder.add(decl);
    }
    // 添加程序本体代码
    mainBuilder.add(code);

    return mainBuilder.toBytes();
  }

  Uint8List _compile(List<Token> tokens,
      [CodeType codeType = CodeType.module]) {
    //, ImportInfo? importInfo]) {
    // _curImportInfo = importInfo;
    addTokens(tokens);
    final bytesBuilder = BytesBuilder();
    while (curTok.type != HTLexicon.endOfFile) {
      final exprStmts = _parseStmt(codeType: codeType);
      if (codeType == CodeType.block ||
          codeType == CodeType.function ||
          codeType == CodeType.script) {
        bytesBuilder.add(exprStmts);
      }
    }
    return bytesBuilder.toBytes();
  }

  void _parseImportStmt() async {
    advance(1);
    String key = match(HTLexicon.string).literal;
    String? name;
    if (expect([HTLexicon.AS], consume: true)) {
      name = match(HTLexicon.identifier).lexeme;
    }

    final showList = <String>[];
    if (expect([HTLexicon.SHOW], consume: true)) {
      while (curTok.type == HTLexicon.identifier) {
        showList.add(advance(1).lexeme);
        if (curTok.type != HTLexicon.comma) {
          break;
        } else {
          advance(1);
        }
      }
    }

    expect([HTLexicon.semicolon], consume: true);

    _importedModules.add(_ImportInfo(key, name: name, showList: showList));
  }

  /// -32768 to 32767
  Uint8List _int16(int value) =>
      Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.big);

  /// 0 to 65,535
  Uint8List _uint16(int value) =>
      Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);

  /// 0 to 4,294,967,295
  // Uint8List _uint32(int value) => Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

  /// -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
  Uint8List _int64(int value) =>
      Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);

  Uint8List _float64(double value) =>
      Uint8List(8)..buffer.asByteData().setFloat64(0, value, Endian.big);

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

  // Fetch a short utf8 string from the byte list
  String _readId(Uint8List bytes) {
    final length = bytes.first;
    return utf8.decoder.convert(bytes.sublist(1, length + 1));
  }

  Uint8List _parseStmt(
      {CodeType codeType = CodeType.module, bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    switch (codeType) {
      case CodeType.module:
        switch (curTok.type) {
          case HTLexicon.IMPORT:
            _parseImportStmt();
            break;
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.CLASS:
                final decl = _parseClassDeclStmt(classType: ClassType.extern);
                final id = _readId(decl);
                _curBlock.classDecls[id] = decl;
                break;
              case HTLexicon.ENUM:
                final decl = _parseEnumDeclStmt(isExtern: true);
                final id = _readId(decl);
                _curBlock.enumDecls[id] = decl;
                break;
              case HTLexicon.VAR:
              case HTLexicon.LET:
              case HTLexicon.CONST:
                throw HTErrorExternVar();
              case HTLexicon.FUN:
                final decl = _parseFuncDeclaration(
                    externType: ExternalFunctionType.externalFunction);
                final id = _readId(decl);
                _curBlock.funcDecls[id] = decl;
                break;
              default:
                throw HTErrorExpected(HTLexicon.declStmt, curTok.lexeme);
            }
            break;
          case HTLexicon.ENUM:
            final decl = _parseEnumDeclStmt();
            final id = _readId(decl);
            _curBlock.enumDecls[id] = decl;
            break;
          case HTLexicon.ABSTRACT:
            match(HTLexicon.CLASS);
            final decl = _parseClassDeclStmt(classType: ClassType.abstracted);
            final id = _readId(decl);
            _curBlock.classDecls[id] = decl;
            break;
          case HTLexicon.INTERFACE:
            match(HTLexicon.CLASS);
            final decl = _parseClassDeclStmt(classType: ClassType.interface);
            final id = _readId(decl);
            _curBlock.classDecls[id] = decl;
            break;
          case HTLexicon.MIXIN:
            match(HTLexicon.CLASS);
            final decl = _parseClassDeclStmt(classType: ClassType.mixIn);
            final id = _readId(decl);
            _curBlock.classDecls[id] = decl;
            break;
          case HTLexicon.CLASS:
            final decl = _parseClassDeclStmt();
            final id = _readId(decl);
            _curBlock.classDecls[id] = decl;
            break;
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
            throw HTErrorExpected(HTLexicon.declStmt, curTok.lexeme);
        }
        break;
      case CodeType.expression:
      case CodeType.script:
      case CodeType.function:
      case CodeType.block:
        // 函数块中不能出现extern或者static关键字的声明
        switch (curTok.type) {
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
            if (peek(1).type == HTLexicon.identifier) {
              final decl = _parseFuncDeclaration();
              final id = _readId(decl);
              _curBlock.funcDecls[id] = decl;
            } else {
              // 匿名函数表达式
              final func = _parseExprStmt();
              bytesBuilder.add(func);
            }
            break;
          case HTLexicon.IF:
            final ifStmt = _parseIfStmt();
            bytesBuilder.add(ifStmt);
            break;
          case HTLexicon.WHILE:
            final whileStmt = _parseWhileStmt();
            bytesBuilder.add(whileStmt);
            break;
          case HTLexicon.DO:
            final doStmt = _parseDoStmt();
            bytesBuilder.add(doStmt);
            break;
          case HTLexicon.FOR:
            final forStmt = _parseForStmt();
            bytesBuilder.add(forStmt);
            break;
          case HTLexicon.WHEN:
            final whenStmt = _parseWhenStmt();
            bytesBuilder.add(whenStmt);
            break;
          case HTLexicon.BREAK:
            advance(1);
            bytesBuilder.addByte(HTOpCode.breakLoop);
            break;
          case HTLexicon.CONTINUE:
            advance(1);
            bytesBuilder.addByte(HTOpCode.continueLoop);
            break;
          case HTLexicon.RETURN:
            final returnStmt = _parseReturnStmt();
            bytesBuilder.add(returnStmt);
            break;
          case HTLexicon.semicolon:
            advance(1);
            break;
          // 其他情况都认为是表达式
          default:
            final expr = _parseExprStmt();
            bytesBuilder.add(expr);
            break;
        }
        break;
      case CodeType.klass:
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
                isExtern: isExtern || _curClassType == ClassType.extern,
                isMember: true,
                isStatic: isStatic);
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
                externType: _curClassType == ClassType.extern
                    ? ExternalFunctionType.externalClassMethod
                    : isExtern
                        ? ExternalFunctionType.externalFunction
                        : ExternalFunctionType.none,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          case HTLexicon.CONSTRUCT:
            final decl = _parseFuncDeclaration(
              funcType: FunctionType.constructor,
              externType: _curClassType == ClassType.extern
                  ? ExternalFunctionType.externalClassMethod
                  : isExtern
                      ? ExternalFunctionType.externalFunction
                      : ExternalFunctionType.none,
            );
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          case HTLexicon.GET:
            final decl = _parseFuncDeclaration(
                funcType: FunctionType.getter,
                externType: _curClassType == ClassType.extern
                    ? ExternalFunctionType.externalClassMethod
                    : isExtern
                        ? ExternalFunctionType.externalFunction
                        : ExternalFunctionType.none,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          case HTLexicon.SET:
            final decl = _parseFuncDeclaration(
                funcType: FunctionType.setter,
                externType: _curClassType == ClassType.extern
                    ? ExternalFunctionType.externalClassMethod
                    : isExtern
                        ? ExternalFunctionType.externalFunction
                        : ExternalFunctionType.none,
                isStatic: isStatic);
            final id = _readId(decl);
            _curBlock.funcDecls[id] = decl;
            break;
          default:
            throw HTErrorUnexpected(curTok.lexeme);
        }
        break;
    }
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }

    return bytesBuilder.toBytes();
  }

  Uint8List _debugInfo() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.debugInfo);
    final line = Uint8List(2)
      ..buffer.asByteData().setUint16(0, curTok.line, Endian.big);
    bytesBuilder.add(line);
    final column = Uint8List(2)
      ..buffer.asByteData().setUint16(0, curTok.column, Endian.big);
    bytesBuilder.add(column);
    return bytesBuilder.toBytes();
  }

  Uint8List _localNull() {
    final bytesBuilder = BytesBuilder();
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.NULL);
    return bytesBuilder.toBytes();
  }

  Uint8List _localBool(bool value) {
    final bytesBuilder = BytesBuilder();
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.boolean);
    bytesBuilder.addByte(value ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  Uint8List _localConst(int constIndex, int type) {
    final bytesBuilder = BytesBuilder();
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(type);
    bytesBuilder.add(_uint16(constIndex));
    return bytesBuilder.toBytes();
  }

  Uint8List _localSymbol({bool isGetKey = false}) {
    final id = match(HTLexicon.identifier).lexeme;
    final bytesBuilder = BytesBuilder();
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.symbol);
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(isGetKey ? 1 : 0);
    // TODO: 泛型参数应该在这里解析
    // 但需要提前判断是否有右括号
    // 这样才能和小于号区分开
    return bytesBuilder.toBytes();
  }

  Uint8List _localList(List<Uint8List> exprList) {
    final bytesBuilder = BytesBuilder();
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.list);
    bytesBuilder.add(_uint16(exprList.length));
    for (final expr in exprList) {
      bytesBuilder.add(expr);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _localMap(Map<Uint8List, Uint8List> exprMap) {
    final bytesBuilder = BytesBuilder();
    if (_debugMode) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.map);
    bytesBuilder.add(_uint16(exprMap.length));
    for (final key in exprMap.keys) {
      bytesBuilder.add(key);
      bytesBuilder.add(exprMap[key]!);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _localGroup() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.group);
    match(HTLexicon.roundLeft);
    var innerExpr = _parseExpr(endOfExec: true);
    match(HTLexicon.roundRight);
    bytesBuilder.add(innerExpr);
    return bytesBuilder.toBytes();
  }

  Uint8List _localSubValue() {
    // 这里没有判断左括号，因为已经在 operator 那边跳过了
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.tuple);
    var innerExpr = _parseExpr(endOfExec: true);
    match(HTLexicon.squareRight);
    bytesBuilder.add(innerExpr);
    return bytesBuilder.toBytes();
  }

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  ///
  /// 优先级最低的表达式，赋值表达式
  ///
  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  ///
  /// [hasLength]: 是否在表达式开头包含表达式长度信息，这样可以让ip跳过该表达式
  ///
  /// [endOfExec]: 是否在解析完表达式后中断执行，这样可以返回当前表达式的值
  Uint8List _parseExpr({bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    final left = _parserTernaryExpr();
    if (HTLexicon.assignments.contains(curTok.type)) {
      if (!_leftValueLegality) {
        throw HTErrorIllegalLeftValue();
      }
      final op = advance(1).type;
      final right = _parseExpr(); // 右合并：先计算右边
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.assign);
      bytesBuilder.add(left);
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
    } else {
      bytesBuilder.add(left);
    }
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }

    return bytesBuilder.toBytes();
  }

  /// 三目运算符 e1 ? e2 : e3 ，优先级 3，右合并
  Uint8List _parserTernaryExpr() {
    final bytesBuilder = BytesBuilder();
    final condition = _parseLogicalOrExpr();
    bytesBuilder.add(condition);
    if (curTok.type == HTLexicon.condition) {
      advance(1);
      bytesBuilder.addByte(HTOpCode.ifStmt);
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
      final elseBranch = _parserTernaryExpr();
      final thenBranchLength = thenBranch.length + 3;
      final elseBranchLength = elseBranch.length;
      bytesBuilder.add(_uint16(thenBranchLength));
      bytesBuilder.add(thenBranch);
      bytesBuilder.addByte(HTOpCode.goto); // 执行完 then 之后，直接跳过 else block
      bytesBuilder.add(_int16(elseBranchLength));
      bytesBuilder.add(elseBranch);
    }
    return bytesBuilder.toBytes();
  }

  /// 逻辑或 or ，优先级 5，左合并
  Uint8List _parseLogicalOrExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseLogicalAndExpr();
    bytesBuilder.add(left); // 左合并：先计算左边
    if (curTok.type == HTLexicon.logicalOr) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalOr) {
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.orLeft);
        advance(1); // or operator
        final right = _parseLogicalAndExpr();
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.logicalOr);
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 逻辑和 and ，优先级 6，左合并
  Uint8List _parseLogicalAndExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseEqualityExpr();
    bytesBuilder.add(left); // 左合并：先计算左边
    if (curTok.type == HTLexicon.logicalAnd) {
      _leftValueLegality = false;
      while (curTok.type == HTLexicon.logicalAnd) {
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.andLeft);
        advance(1); // and operator
        final right = _parseEqualityExpr();
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.logicalAnd);
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 逻辑相等 ==, !=，优先级 7，不合并
  Uint8List _parseEqualityExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseRelationalExpr();
    bytesBuilder.add(left);
    // 不合并：不循环匹配，只 if 判断一次
    if (HTLexicon.equalitys.contains(curTok.type)) {
      _leftValueLegality = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.equalLeft);
      final op = advance(1).type;
      final right = _parseRelationalExpr();
      bytesBuilder.add(right);
      switch (op) {
        case HTLexicon.equal:
          bytesBuilder.addByte(HTOpCode.equal);
          break;
        case HTLexicon.notEqual:
          bytesBuilder.addByte(HTOpCode.notEqual);
          break;
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 逻辑比较 <, >, <=, >=，is, is! 优先级 8，不合并
  Uint8List _parseRelationalExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseAdditiveExpr();
    bytesBuilder.add(left);
    if (HTLexicon.relationals.contains(curTok.type)) {
      _leftValueLegality = false;
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      final op = advance(1).type;
      switch (op) {
        case HTLexicon.lesser:
          final right = _parseAdditiveExpr();
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.lesser);
          break;
        case HTLexicon.greater:
          final right = _parseAdditiveExpr();
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.greater);
          break;
        case HTLexicon.lesserOrEqual:
          final right = _parseAdditiveExpr();
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.lesserOrEqual);
          break;
        case HTLexicon.greaterOrEqual:
          final right = _parseAdditiveExpr();
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.greaterOrEqual);
          break;
        case HTLexicon.IS:
          final right = _parseTypeId(localValue: true);
          bytesBuilder.add(right);
          final isNot = (peek(1).type == HTLexicon.logicalNot) ? true : false;
          bytesBuilder.addByte(isNot ? HTOpCode.typeIsNot : HTOpCode.typeIs);
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 加法 +, -，优先级 13，左合并
  Uint8List _parseAdditiveExpr() {
    final bytesBuilder = BytesBuilder();
    final left = _parseMultiplicativeExpr();
    bytesBuilder.add(left);
    if (HTLexicon.additives.contains(curTok.type)) {
      _leftValueLegality = false;
      while (HTLexicon.additives.contains(curTok.type)) {
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.addLeft);
        final op = advance(1).type;
        final right = _parseMultiplicativeExpr();
        bytesBuilder.add(right);
        switch (op) {
          case HTLexicon.add:
            bytesBuilder.addByte(HTOpCode.add);
            break;
          case HTLexicon.subtract:
            bytesBuilder.addByte(HTOpCode.subtract);
            break;
        }
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
      _leftValueLegality = false;
      while (HTLexicon.multiplicatives.contains(curTok.type)) {
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.multiplyLeft);
        final op = advance(1).type;
        final right = _parseUnaryPrefixExpr();
        bytesBuilder.add(right);
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
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 前缀 -e, !e，++e, --e, 优先级 15，不合并
  Uint8List _parseUnaryPrefixExpr() {
    final bytesBuilder = BytesBuilder();
    // 因为是前缀所以要先判断操作符
    if (HTLexicon.unaryPrefixs.contains(curTok.type)) {
      _leftValueLegality = false;
      var op = advance(1).type;
      final value = _parseUnaryPostfixExpr();
      bytesBuilder.add(value);
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
    } else {
      final value = _parseUnaryPostfixExpr();
      bytesBuilder.add(value);
    }
    return bytesBuilder.toBytes();
  }

  /// 后缀 e., e[], e(), e++, e-- 优先级 16，左合并
  Uint8List _parseUnaryPostfixExpr() {
    final bytesBuilder = BytesBuilder();
    final object = _parseLocalExpr();
    bytesBuilder.add(object); // object will stay in reg[14]
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.postfixObject);
      final op = advance(1).type;
      switch (op) {
        case HTLexicon.memberGet:
          bytesBuilder
              .addByte(HTOpCode.objectSymbol); // save object symbol name in reg
          final key = _localSymbol(isGetKey: true); // shortUtf8String
          _leftValueLegality = true;
          bytesBuilder.add(key);
          bytesBuilder.addByte(HTOpCode.register);
          bytesBuilder.addByte(HTRegIdx.postfixKey);
          bytesBuilder.addByte(HTOpCode.memberGet);
          break;
        case HTLexicon.subGet:
          final key = _localSubValue();
          _leftValueLegality = true;
          bytesBuilder.add(key); // int
          bytesBuilder.addByte(HTOpCode.register);
          bytesBuilder.addByte(HTRegIdx.postfixKey);
          bytesBuilder.addByte(HTOpCode.subGet);
          break;
        case HTLexicon.call:
          _leftValueLegality = false;
          final positionalArgs = <Uint8List>[];
          final namedArgs = <String, Uint8List>{};
          while ((curTok.type != HTLexicon.roundRight) &&
              (curTok.type != HTLexicon.endOfFile)) {
            if (expect([HTLexicon.identifier, HTLexicon.colon],
                consume: false)) {
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
          _leftValueLegality = false;
          bytesBuilder.addByte(HTOpCode.postIncrement);
          break;
        case HTLexicon.postDecrement:
          _leftValueLegality = false;
          bytesBuilder.addByte(HTOpCode.postDecrement);
          break;
      }
    }
    return bytesBuilder.toBytes();
  }

  /// 优先级最高的表达式
  Uint8List _parseLocalExpr() {
    switch (curTok.type) {
      case HTLexicon.NULL:
        _leftValueLegality = false;
        advance(1);
        return _localNull();
      case HTLexicon.TRUE:
        _leftValueLegality = false;
        advance(1);
        return _localBool(true);
      case HTLexicon.FALSE:
        _leftValueLegality = false;
        advance(1);
        return _localBool(false);
      case HTLexicon.integer:
        _leftValueLegality = false;
        final value = curTok.literal;
        var index = addInt(value);
        advance(1);
        return _localConst(index, HTValueTypeCode.int64);
      case HTLexicon.float:
        _leftValueLegality = false;
        final value = curTok.literal;
        var index = addConstFloat(value);
        advance(1);
        return _localConst(index, HTValueTypeCode.float64);
      case HTLexicon.string:
        _leftValueLegality = false;
        final value = curTok.literal;
        var index = addConstString(value);
        advance(1);
        return _localConst(index, HTValueTypeCode.utf8String);
      case HTLexicon.identifier:
        _leftValueLegality = true;
        // TODO: parse type args
        return _localSymbol();
      case HTLexicon.roundLeft:
        _leftValueLegality = false;
        return _localGroup();
      case HTLexicon.squareLeft:
        _leftValueLegality = false;
        advance(1);
        final exprList = <Uint8List>[];
        while (curTok.type != HTLexicon.squareRight) {
          exprList.add(_parseExpr(endOfExec: true));
          if (curTok.type != HTLexicon.squareRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.squareRight);
        return _localList(exprList);
      case HTLexicon.curlyLeft:
        _leftValueLegality = false;
        advance(1);
        var exprMap = <Uint8List, Uint8List>{};
        while (curTok.type != HTLexicon.curlyRight) {
          var key = _parseExpr(endOfExec: true);
          match(HTLexicon.colon);
          var value = _parseExpr(endOfExec: true);
          exprMap[key] = value;
          if (curTok.type != HTLexicon.curlyRight) {
            match(HTLexicon.comma);
          }
        }
        match(HTLexicon.curlyRight);
        return _localMap(exprMap);
      case HTLexicon.FUN:
        return _parseFuncDeclaration(funcType: FunctionType.literal);
      default:
        throw HTErrorExpected(HTLexicon.expression, curTok.lexeme);
    }
  }

  Uint8List _parseBlock(String id,
      {CodeType codeType = CodeType.block,
      bool createBlock = true,
      bool blockStatement = true,
      bool endOfExec = false}) {
    match(HTLexicon.curlyLeft);
    final bytesBuilder = BytesBuilder();
    final savedDeclBlock = _curBlock;
    if (createBlock) {
      _curBlock = _DeclarationBlock();
    }
    if (blockStatement) {
      bytesBuilder.addByte(HTOpCode.block);
      bytesBuilder.add(_shortUtf8String(id));
    }
    final declsBytesBuilder = BytesBuilder();
    final blockBytesBuilder = BytesBuilder();
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.endOfFile) {
      blockBytesBuilder.add(_parseStmt(codeType: codeType));
    }
    // 添加变量表，总是按照：函数、类、变量这个顺序
    declsBytesBuilder.addByte(HTOpCode.declTable);
    declsBytesBuilder.add(_uint16(_curBlock.enumDecls.length));
    for (var decl in _curBlock.enumDecls.values) {
      declsBytesBuilder.add(decl);
    }
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
    match(HTLexicon.curlyRight);
    bytesBuilder.add(declsBytesBuilder.toBytes());
    bytesBuilder.add(blockBytesBuilder.toBytes());
    _curBlock = savedDeclBlock;
    if (blockStatement) {
      bytesBuilder.addByte(HTOpCode.endOfBlock);
    }
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _parseExprStmt() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseExpr());
    expect([HTLexicon.semicolon], consume: true);
    return bytesBuilder.toBytes();
  }

  Uint8List _parseReturnStmt() {
    advance(1); // keyword

    final bytesBuilder = BytesBuilder();
    if (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.semicolon &&
        curTok.type != HTLexicon.endOfFile) {
      bytesBuilder.add(_parseExpr());
    }
    bytesBuilder.addByte(HTOpCode.endOfFunc);
    expect([HTLexicon.semicolon], consume: true);

    return bytesBuilder.toBytes();
  }

  Uint8List _parseIfStmt() {
    advance(1);
    final bytesBuilder = BytesBuilder();
    match(HTLexicon.roundLeft);
    bytesBuilder.add(_parseExpr()); // bool: condition
    match(HTLexicon.roundRight);
    bytesBuilder.addByte(HTOpCode.ifStmt);
    Uint8List thenBranch;
    if (curTok.type == HTLexicon.curlyLeft) {
      thenBranch = _parseBlock(HTLexicon.thenBranch);
    } else {
      thenBranch = _parseStmt(codeType: CodeType.block);
    }
    Uint8List? elseBranch;
    if (expect([HTLexicon.ELSE], consume: true)) {
      if (curTok.type == HTLexicon.curlyLeft) {
        elseBranch = _parseBlock(HTLexicon.elseBranch);
      } else {
        elseBranch = _parseStmt(codeType: CodeType.block);
      }
    }
    final thenBranchLength = thenBranch.length + 3;
    final elseBranchLength = elseBranch?.length ?? 0;

    bytesBuilder.add(_uint16(thenBranchLength));
    bytesBuilder.add(thenBranch);
    bytesBuilder.addByte(HTOpCode.goto); // 执行完 then 之后，直接跳过 else block
    bytesBuilder.add(_int16(elseBranchLength));
    if (elseBranch != null) {
      bytesBuilder.add(elseBranch);
    }

    return bytesBuilder.toBytes();
  }

  Uint8List _parseWhileStmt() {
    advance(1);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.loopPoint);
    Uint8List? condition;
    if (expect([HTLexicon.roundLeft], consume: true)) {
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    Uint8List loopBody;
    if (curTok.type == HTLexicon.curlyLeft) {
      loopBody = _parseBlock(HTLexicon.whileStmt);
    } else {
      loopBody = _parseStmt(codeType: CodeType.block);
    }
    final loopLength = (condition?.length ?? 0) + loopBody.length + 5;
    bytesBuilder.add(_uint16(0)); // while loop continue ip
    bytesBuilder.add(_uint16(loopLength)); // while loop break ip
    if (condition != null) {
      bytesBuilder.add(condition);
      bytesBuilder.addByte(HTOpCode.whileStmt);
      bytesBuilder.addByte(1); // bool: has condition
    } else {
      bytesBuilder.addByte(HTOpCode.whileStmt);
      bytesBuilder.addByte(0); // bool: has condition
    }
    bytesBuilder.add(loopBody);
    bytesBuilder.addByte(HTOpCode.goto);
    bytesBuilder.add(_int16(-loopLength));
    return bytesBuilder.toBytes();
  }

  Uint8List _parseDoStmt() {
    advance(1);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.loopPoint);
    Uint8List loopBody;
    if (curTok.type == HTLexicon.curlyLeft) {
      loopBody = _parseBlock(HTLexicon.whileStmt);
    } else {
      loopBody = _parseStmt(codeType: CodeType.block);
    }
    match(HTLexicon.WHILE);
    match(HTLexicon.roundLeft);
    final condition = _parseExpr();
    match(HTLexicon.roundRight);
    final loopLength = loopBody.length + condition.length + 1;
    bytesBuilder.add(_uint16(0)); // while loop continue ip
    bytesBuilder.add(_uint16(loopLength)); // while loop break ip
    bytesBuilder.add(loopBody);
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.doStmt);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleLocalConstInt(int value, {bool endOfExec = false}) {
    _leftValueLegality = true;
    final bytesBuilder = BytesBuilder();

    final index = addInt(0);
    final constExpr = _localConst(index, HTValueTypeCode.int64);
    bytesBuilder.add(constExpr);
    if (endOfExec) bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleLocalSymbol(String id, {bool isGetKey = false}) {
    _leftValueLegality = true;
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.symbol);
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(isGetKey ? 1 : 0); // bool: isGetKey
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleMemberGet(Uint8List object, String key,
      {bool endOfExec = false}) {
    _leftValueLegality = true;
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder
        .addByte(HTOpCode.objectSymbol); // save object symbol name in reg
    final keySymbol = _assembleLocalSymbol(key, isGetKey: true);
    bytesBuilder.add(keySymbol);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixKey);
    bytesBuilder.addByte(HTOpCode.memberGet);
    if (endOfExec) bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleVarDecl(String id, [Uint8List? initializer]) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(0); // bool: isDynamic
    bytesBuilder.addByte(0); // bool: isExtern
    bytesBuilder.addByte(0); // bool: isImmutable
    bytesBuilder.addByte(0); // bool: isMember
    bytesBuilder.addByte(0); // bool: isStatic
    bytesBuilder.addByte(0); // bool: hasTypeId

    if (initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      bytesBuilder.add(_uint16(initializer.length));
      bytesBuilder.add(initializer);
    } else {
      bytesBuilder.addByte(0);
    }

    return bytesBuilder.toBytes();
  }

  // for 其实是拼装成的 while 语句
  Uint8List _parseForStmt() {
    advance(1);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.block);
    bytesBuilder.add(_shortUtf8String(HTLexicon.forStmtInit));
    match(HTLexicon.roundLeft);
    final forStmtType = peek(2).lexeme;
    Uint8List? condition;
    Uint8List? assign;
    Uint8List? increment;
    if (forStmtType == HTLexicon.IN) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        throw HTErrorUnexpected(curTok.type);
      }
      final declPos = tokPos;
      // jump over keywrod
      advance(1);
      // get id of var decl and jump over in/of
      final id = advance(2).lexeme;
      final object = _parseExpr();
      // the intializer of the var is a member get expression: object.length
      final iterInit =
          _assembleMemberGet(object, HTLexicon.first, endOfExec: true);
      match(HTLexicon.roundRight);
      final blockStartPos = tokPos;
      // go back to var declaration
      tokPos = declPos;
      final iterDecl = _parseVarStmt(
          isDynamic: curTok.type == HTLexicon.VAR,
          isImmutable: curTok.type == HTLexicon.CONST,
          initializer: iterInit);

      final increId = '__#i';
      final increExprInit = _assembleLocalConstInt(0, endOfExec: true);
      final increDecl = _assembleVarDecl(increId, increExprInit);

      // 添加变量声明，枚举、函数和类的部分是空的
      bytesBuilder.addByte(HTOpCode.declTable);
      bytesBuilder.add(_uint16(0));
      bytesBuilder.add(_uint16(0));
      bytesBuilder.add(_uint16(0));
      bytesBuilder.add(_uint16(2));
      bytesBuilder.add(iterDecl);
      bytesBuilder.add(increDecl);

      // TODO: should be able to tell if it's a iterable (could not be list)
      final conditionBytesBuilder = BytesBuilder();
      final isNotEmptyExpr = _assembleMemberGet(object, HTLexicon.isNotEmpty);
      conditionBytesBuilder.add(isNotEmptyExpr);
      conditionBytesBuilder.addByte(HTOpCode.register);
      conditionBytesBuilder.addByte(HTRegIdx.andLeft);
      final lesserLeftExpr = _assembleLocalSymbol(increId);
      conditionBytesBuilder.add(lesserLeftExpr);
      conditionBytesBuilder.addByte(HTOpCode.register);
      conditionBytesBuilder.addByte(HTRegIdx.relationLeft);
      final iterableLengthExpr = _assembleMemberGet(object, HTLexicon.length);
      conditionBytesBuilder.add(iterableLengthExpr);
      conditionBytesBuilder.addByte(HTOpCode.lesser);
      conditionBytesBuilder.addByte(HTOpCode.logicalAnd);
      condition = conditionBytesBuilder.toBytes();

      final assignBytesBuilder = BytesBuilder();
      final getElemFunc = _assembleMemberGet(object, HTLexicon.elementAt);
      assignBytesBuilder.add(getElemFunc);
      assignBytesBuilder.addByte(HTOpCode.register);
      assignBytesBuilder.addByte(HTRegIdx.postfixObject);
      assignBytesBuilder.addByte(HTOpCode.call);
      assignBytesBuilder.addByte(1); // length of positionalArgs
      final getElemFuncCallArg = _assembleLocalSymbol(increId);
      assignBytesBuilder.add(getElemFuncCallArg);
      assignBytesBuilder.addByte(HTOpCode.endOfExec);
      assignBytesBuilder.addByte(0); // length of namedArgs
      assignBytesBuilder.addByte(HTOpCode.register);
      assignBytesBuilder.addByte(HTRegIdx.assign);
      final assignLeftExpr = _assembleLocalSymbol(id);
      assignBytesBuilder.add(assignLeftExpr);
      assignBytesBuilder.addByte(HTOpCode.assign);
      assign = assignBytesBuilder.toBytes();

      final incrementBytesBuilder = BytesBuilder();
      final preIncreExpr = _assembleLocalSymbol(increId);
      incrementBytesBuilder.add(preIncreExpr);
      incrementBytesBuilder.addByte(HTOpCode.preIncrement);
      increment = incrementBytesBuilder.toBytes();

      // go back to block start
      tokPos = blockStartPos;
    }
    // for (var i = 0; i < length; ++i)
    else {
      if (curTok.type != HTLexicon.semicolon) {
        if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
          throw HTErrorUnexpected(curTok.type);
        }
        final iterDecl = _parseVarStmt(
            isDynamic: curTok.type == HTLexicon.VAR,
            isImmutable: curTok.type == HTLexicon.CONST,
            endOfStatement: true);

        // 添加变量声明，枚举、函数和类的部分是空的
        bytesBuilder.addByte(HTOpCode.declTable);
        bytesBuilder.add(_uint16(0));
        bytesBuilder.add(_uint16(0));
        bytesBuilder.add(_uint16(0));
        bytesBuilder.add(_uint16(1));
        bytesBuilder.add(iterDecl);
      } else {
        advance(1);
      }

      if (curTok.type != HTLexicon.semicolon) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);

      if (curTok.type != HTLexicon.roundRight) {
        increment = _parseExpr();
      }
      match(HTLexicon.roundRight);
    }

    bytesBuilder.addByte(HTOpCode.loopPoint);
    final loop = _parseBlock(HTLexicon.forStmt);
    final continueLength =
        (condition?.length ?? 0) + (assign?.length ?? 0) + loop.length + 2;
    final breakLength = continueLength + (increment?.length ?? 0) + 3;
    bytesBuilder.add(_uint16(continueLength));
    bytesBuilder.add(_uint16(breakLength));
    if (condition != null) bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.whileStmt);
    bytesBuilder.addByte((condition != null) ? 1 : 0); // bool: has condition
    if (assign != null) bytesBuilder.add(assign);
    bytesBuilder.add(loop);
    if (increment != null) bytesBuilder.add(increment);
    bytesBuilder.addByte(HTOpCode.goto);
    bytesBuilder.add(_int16(-breakLength));

    bytesBuilder.addByte(HTOpCode.endOfBlock);
    return bytesBuilder.toBytes();
  }

  Uint8List _parseWhenStmt() {
    advance(1);
    final bytesBuilder = BytesBuilder();
    Uint8List? condition;
    if (expect([HTLexicon.roundLeft], consume: true)) {
      condition = _parseExpr();
      bytesBuilder.add(condition);
      match(HTLexicon.roundRight);
    }
    bytesBuilder.addByte(HTOpCode.whenStmt);
    bytesBuilder.addByte(condition != null ? 1 : 0);
    final cases = <Uint8List>[];
    final branches = <Uint8List>[];
    Uint8List? elseBranch;
    match(HTLexicon.curlyLeft);
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.endOfFile) {
      if (curTok.lexeme == HTLexicon.ELSE) {
        advance(1);
        match(HTLexicon.colon);
        if (curTok.type != HTLexicon.semicolon &&
            curTok.type != HTLexicon.curlyRight) {
          elseBranch = _parseExpr(endOfExec: true);
        }
      } else {
        final caseExpr = _parseExpr(endOfExec: true);
        cases.add(caseExpr);
        match(HTLexicon.colon);
        if (curTok.type == HTLexicon.curlyLeft) {
          final caseBranch = _parseBlock(HTLexicon.whenStmt, endOfExec: true);
          branches.add(caseBranch);
        } else {
          final caseBranch =
              _parseStmt(codeType: CodeType.block, endOfExec: true);
          branches.add(caseBranch);
        }
      }
    }

    match(HTLexicon.curlyRight);

    bytesBuilder.addByte(cases.length);

    var curIp = 0;
    bytesBuilder
        .add(_uint16(0)); // the first ip starts from previous list's last one
    for (var i = 1; i < branches.length; ++i) {
      curIp = curIp + branches[i - 1].length;
      bytesBuilder.add(_uint16(curIp));
    }
    curIp = curIp + branches.last.length;
    if (elseBranch != null) {
      bytesBuilder.add(_uint16(curIp)); // else branch ip
    } else {
      bytesBuilder.add(_uint16(0)); // has no else
    }
    bytesBuilder.add(_uint16(curIp + (elseBranch?.length ?? 0)));

    for (final expr in cases) {
      bytesBuilder.add(expr);
    }
    for (final branch in branches) {
      bytesBuilder.add(branch);
    }

    if (elseBranch != null) {
      bytesBuilder.add(elseBranch);
    }

    return bytesBuilder.toBytes();
  }

  Uint8List _parseTypeId({bool localValue = false}) {
    final id = advance(1).lexeme;

    final bytesBuilder = BytesBuilder();

    if (localValue) {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.typeid);
    }

    bytesBuilder.add(_shortUtf8String(id));

    final typeArgs = <Uint8List>[];
    if (expect([HTLexicon.angleLeft], consume: true)) {
      while ((curTok.type != HTLexicon.angleRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        typeArgs.add(_parseTypeId());
        expect([HTLexicon.comma], consume: true);
      }
      match(HTLexicon.angleRight);
    }

    bytesBuilder.addByte(typeArgs.length); // max 255
    for (final arg in typeArgs) {
      bytesBuilder.add(arg);
    }

    // final isNullable = expect([HTLexicon.nullable], consume: true);
    // bytesBuilder.addByte(isNullable ? 1 : 0); // bool isNullable
    bytesBuilder.addByte(1); // bool isNullable

    return bytesBuilder.toBytes();
  }

  /// 变量声明语句
  Uint8List _parseVarStmt(
      {bool isDynamic = false,
      bool isExtern = false,
      bool isImmutable = false,
      bool isMember = false,
      bool isStatic = false,
      bool endOfStatement = false,
      Uint8List? initializer}) {
    advance(1);
    var id = match(HTLexicon.identifier).lexeme;

    if (_curClassName != null && isExtern) {
      id = '$_curClassName.$id';
    }

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

    if (expect([HTLexicon.colon], consume: true)) {
      bytesBuilder.addByte(1); // bool: has typeid
      bytesBuilder.add(_parseTypeId());
    } else {
      bytesBuilder.addByte(0); // bool: has typeid
    }

    if (expect([HTLexicon.assign], consume: true)) {
      final initializer = _parseExpr(endOfExec: true);
      bytesBuilder.addByte(1); // bool: has initializer
      bytesBuilder.add(_uint16(initializer.length));
      bytesBuilder.add(initializer);
    } else if (initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      bytesBuilder.add(_uint16(initializer.length));
      bytesBuilder.add(initializer);
    } else {
      bytesBuilder.addByte(0);
    }
    // 语句结尾
    if (endOfStatement) {
      match(HTLexicon.semicolon);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    return bytesBuilder.toBytes();
  }

  Uint8List _parseFuncDeclaration(
      {FunctionType funcType = FunctionType.normal,
      ExternalFunctionType externType = ExternalFunctionType.none,
      bool isStatic = false,
      bool isConst = false}) {
    advance(1);

    var hasExternalTypedef = false;
    String? externalTypedef;
    if (expect([HTLexicon.squareLeft], consume: true)) {
      if (externType != ExternalFunctionType.none)
        throw HTErrorUnexpected(peek(-1).lexeme);

      hasExternalTypedef = true;
      externalTypedef = match(HTLexicon.identifier).lexeme;
      match(HTLexicon.squareRight);
    }

    var declId = '';
    late String id;
    if (curTok.type == HTLexicon.identifier) {
      declId = advance(1).lexeme;
    }

    if (externType == ExternalFunctionType.none) {
      switch (funcType) {
        case FunctionType.constructor:
          id = (declId.isEmpty)
              ? HTLexicon.constructor
              : '${HTLexicon.constructor}$declId';
          break;
        case FunctionType.getter:
          if (_curBlock.contains(declId)) {
            throw HTErrorDefinedParser(declId);
          }
          id = HTLexicon.getter + declId;
          break;
        case FunctionType.setter:
          if (_curBlock.contains(declId)) {
            throw HTErrorDefinedParser(declId);
          }
          id = HTLexicon.setter + declId;
          break;
        case FunctionType.literal:
          id = HTLexicon.anonymousFunction +
              (HTFunction.anonymousIndex++).toString();
          break;
        default:
          id = declId;
      }
    } else {
      if (_curClassName != null) {
        id = (declId.isEmpty) ? _curClassName! : '${_curClassName!}.$declId';
      } else {
        if (declId.isEmpty) {
          throw HTErrorExpected(HTLexicon.identifier, peek(-1).lexeme);
        }
        id = declId;
      }
    }

    final funcBytesBuilder = BytesBuilder();
    if (funcType != FunctionType.literal) {
      // funcBytesBuilder.addByte(HTOpCode.funcDecl);
      funcBytesBuilder.add(_shortUtf8String(id));
      funcBytesBuilder.add(_shortUtf8String(declId));

      // if (expect([HTLexicon.angleLeft], consume: true)) {
      //   // 泛型param
      //   super_class_type_args = _parseTypeId();
      //   match(HTLexicon.angleRight);
      // }

      if (hasExternalTypedef) {
        funcBytesBuilder.addByte(1);
        funcBytesBuilder.add(_shortUtf8String(externalTypedef!));
      } else {
        funcBytesBuilder.addByte(0);
      }

      funcBytesBuilder.addByte(funcType.index);
      funcBytesBuilder.addByte(externType.index);
      funcBytesBuilder.addByte(isStatic ? 1 : 0);
      funcBytesBuilder.addByte(isConst ? 1 : 0);
    } else {
      funcBytesBuilder.addByte(HTOpCode.local);
      funcBytesBuilder.addByte(HTValueTypeCode.function);
      funcBytesBuilder.add(_shortUtf8String(id));

      if (hasExternalTypedef) {
        funcBytesBuilder.addByte(1);
        funcBytesBuilder.add(_shortUtf8String(externalTypedef!));
      } else {
        funcBytesBuilder.addByte(0);
      }
    }

    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <Uint8List>[];

    if (funcType != FunctionType.getter &&
        expect([HTLexicon.roundLeft], consume: true)) {
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

        // 参数类型
        if (expect([HTLexicon.colon], consume: true)) {
          paramBytesBuilder.addByte(1); // bool: has type
          paramBytesBuilder.add(_parseTypeId());
        } else {
          paramBytesBuilder.addByte(0); // bool: has type
        }

        Uint8List? initializer;
        //参数默认值
        if ((isOptional || isNamed) &&
            (expect([HTLexicon.assign], consume: true))) {
          initializer = _parseExpr(endOfExec: true);
          paramBytesBuilder.addByte(1); // bool，表示有初始化表达式
          paramBytesBuilder.add(_uint16(initializer.length));
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

    funcBytesBuilder.addByte(minArity);
    funcBytesBuilder.addByte(maxArity);
    funcBytesBuilder.addByte(paramDecls.length); // max 255
    for (var decl in paramDecls) {
      funcBytesBuilder.add(decl);
    }

    // 返回值类型
    if (expect([HTLexicon.colon], consume: true)) {
      funcBytesBuilder.addByte(1); // bool: has return type
      funcBytesBuilder.add(_parseTypeId());
    } else {
      funcBytesBuilder.addByte(0); // bool: has return type
    }

    // 处理函数定义部分的语句块
    if (curTok.type == HTLexicon.curlyLeft) {
      funcBytesBuilder.addByte(1); // bool: has definition
      final body = _parseBlock(HTLexicon.functionCall);
      funcBytesBuilder.add(_uint16(body.length + 1)); // definition bytes length
      funcBytesBuilder.add(body);
      funcBytesBuilder.addByte(HTOpCode.endOfFunc);
    } else if (expect([HTLexicon.ARROW], consume: true)) {
      funcBytesBuilder.addByte(1); // bool: has definition
      final body = _parseExprStmt();
      funcBytesBuilder.add(_uint16(body.length + 1)); // definition bytes length
      funcBytesBuilder.add(body);
      funcBytesBuilder.addByte(HTOpCode.endOfFunc);
      expect([HTLexicon.semicolon], consume: true);
    } else {
      funcBytesBuilder.addByte(0); // bool: has no definition
      expect([HTLexicon.semicolon], consume: true);
    }

    return funcBytesBuilder.toBytes();
  }

  Uint8List _parseClassDeclStmt({ClassType classType = ClassType.normal}) {
    advance(1); // keyword
    final bytesBuilder = BytesBuilder();
    final id = match(HTLexicon.identifier).lexeme;
    bytesBuilder.add(_shortUtf8String(id));

    // if (expect([HTLexicon.angleLeft], consume: true)) {
    //   // 泛型param
    //   super_class_type_args = _parseTypeId();
    //   match(HTLexicon.angleRight);
    // }

    if (_curBlock.contains(id)) {
      throw HTErrorDefinedParser(id);
    }

    final savedClassName = _curClassName;
    _curClassName = id;
    final savedClassType = _curClassType;
    _curClassType = classType;

    bytesBuilder.addByte(classType.index);

    String? superClassId;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      superClassId = advance(1).lexeme;
      if (superClassId == id) {
        throw HTErrorUnexpected(id);
      }

      // else if (!_curBlock.classDecls.containsKey(id)) {
      //   throw HTErrorNotClass(superClassId);
      // }

      bytesBuilder.addByte(1); // bool: has super class
      bytesBuilder.add(_shortUtf8String(superClassId));

      // if (expect([HTLexicon.angleLeft], consume: true)) {
      //   // 泛型arg
      //   super_class_type_args = _parseTypeId();
      //   match(HTLexicon.angleRight);
      // }
    } else {
      bytesBuilder.addByte(0); // bool: has super class
    }

    final classDefinition =
        _parseBlock(id, codeType: CodeType.klass, blockStatement: false);

    bytesBuilder.add(classDefinition);
    bytesBuilder.addByte(HTOpCode.endOfExec);

    _curClassName = savedClassName;
    _curClassType = savedClassType;
    return bytesBuilder.toBytes();
  }

  Uint8List _parseEnumDeclStmt({bool isExtern = false}) {
    advance(1);
    final bytesBuilder = BytesBuilder();
    final id = match(HTLexicon.identifier).lexeme;
    bytesBuilder.add(_shortUtf8String(id));

    bytesBuilder.addByte(isExtern ? 1 : 0);

    if (_curBlock.contains(id)) {
      throw HTErrorDefinedParser(id);
    }

    var enumerations = <String>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while (curTok.type != HTLexicon.curlyRight &&
          curTok.type != HTLexicon.endOfFile) {
        enumerations.add(match(HTLexicon.identifier).lexeme);
        if (curTok.type != HTLexicon.curlyRight) {
          match(HTLexicon.comma);
        }
      }
      match(HTLexicon.curlyRight);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    bytesBuilder.add(_uint16(enumerations.length));
    for (final id in enumerations) {
      bytesBuilder.add(_shortUtf8String(id));
    }

    return bytesBuilder.toBytes();
  }
}
