import 'dart:typed_data';
import 'dart:convert';

import '../core/abstract_parser.dart';
import '../core/lexer.dart';
import '../core/const_table.dart';
import '../core/declaration/class_declaration.dart';
import '../grammar/semantic.dart';
import '../grammar/lexicon.dart';
import '../source/source.dart';
import '../error/errors.dart';
import '../source/source_provider.dart';
import 'opcode.dart';
import '../ast/ast.dart' show ImportStmt;

class HTRegIdx {
  static const value = 0;
  static const symbol = 1;
  // static const leftValue = 2;
  static const refType = 3;
  static const typeArgs = 4;
  static const loopCount = 5;
  static const anchor = 6;
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

class BytecodeDeclarationBlock {
  final enumDecls = <String, Uint8List>{};
  final funcDecls = <String, Uint8List>{};
  final classDecls = <String, Uint8List>{};
  final varDecls = <String, Uint8List>{};

  bool contains(String id) =>
      enumDecls.containsKey(id) ||
      funcDecls.containsKey(id) ||
      classDecls.containsKey(id) ||
      varDecls.containsKey(id);
}

/// Utility class that parse a string content into a uint8 list
class HTCompiler extends AbstractParser {
  /// Hetu script bytecode's bytecode signature
  static const hetuSignatureData = [8, 5, 20, 21];

  /// The version of the compiled bytecode,
  /// used to determine compatibility.
  static const hetuVersionData = [0, 1, 0, 0];

  // late BytecodeDeclarationBlock _mainBlock;
  // late BytecodeDeclarationBlock _curBlock;
  // late HTBytecodeCompilation _curCompilation;
  late List<ImportStmt> _curImports;
  late ConstTable _curConstTable;
  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  late String _curLibraryName;
  @override
  String get curLibraryName => _curLibraryName;

  ClassDeclaration? _curClass;
  FunctionCategory? _curFuncType;

  var _leftValueLegality = false;
  final List<Map<String, String>> _markedSymbolsList = [];

  /// Compiles a Token list.
  Future<Uint8List> compile(
      String content, SourceProvider sourceProvider, String fullName,
      {ParserConfig config = const ParserConfig()}) async {
    this.config = config;
    _curModuleFullName = fullName;
    // _curBlock = _mainBlock = BytecodeDeclarationBlock();
    _curClass = null;
    _curFuncType = null;
    // _curCompilation = HTBytecodeCompilation();
    _curImports = <ImportStmt>[];
    _curConstTable = ConstTable();

    final tokens = Lexer().lex(content, fullName);
    addTokens(tokens);
    final bytesBuilder = BytesBuilder();
    while (curTok.type != HTLexicon.endOfFile) {
      final exprStmts = _parseStmt(sourceType: config.sourceType);
      bytesBuilder.add(exprStmts);
    }
    final code = bytesBuilder.toBytes();

    for (final importInfo in _curImports) {
      final importedFullName = sourceProvider.resolveFullName(importInfo.key,
          fullName.startsWith(HTLexicon.anonymousScript) ? null : fullName);
      if (!sourceProvider.hasModule(importedFullName)) {
        _curModuleFullName = importedFullName;
        final importedContent = await sourceProvider.getSource(importedFullName,
            curModuleFullName: _curModuleFullName);
        final compiler2 = HTCompiler();
        // TODO: 这里的错误处理需要重新写，因为如果是新的compiler的错误无法捕捉
        final compilation2 = await compiler2.compile(
            importedContent.content, sourceProvider, importedFullName);

        // _curCompilation.join(compilation2);
      }
    }

    final mainBuilder = BytesBuilder();
    // 河图字节码标记
    mainBuilder.addByte(HTOpCode.signature);
    mainBuilder.add(hetuSignatureData);
    // 版本号
    mainBuilder.addByte(HTOpCode.version);
    mainBuilder.add(hetuVersionData);
    // 添加常量表
    mainBuilder.addByte(HTOpCode.constTable);
    mainBuilder.add(_uint16(_curConstTable.intTable.length));
    for (final value in _curConstTable.intTable) {
      mainBuilder.add(_int64(value));
    }
    mainBuilder.add(_uint16(_curConstTable.floatTable.length));
    for (final value in _curConstTable.floatTable) {
      mainBuilder.add(_float64(value));
    }
    mainBuilder.add(_uint16(_curConstTable.stringTable.length));
    for (final value in _curConstTable.stringTable) {
      mainBuilder.add(_utf8String(value));
    }
    // 将变量表前置，总是按照：枚举、函数、类、变量这个顺序
    // for (final decl in _mainBlock.enumDecls.values) {
    //   mainBuilder.add(decl);
    // }
    // for (final decl in _mainBlock.funcDecls.values) {
    //   mainBuilder.add(decl);
    // }
    // for (final decl in _mainBlock.classDecls.values) {
    //   mainBuilder.add(decl);
    // }
    // for (final decl in _mainBlock.varDecls.values) {
    //   mainBuilder.add(decl);
    // }
    // 添加程序本体代码
    mainBuilder.add(code);

    // _curCompilation
    //     .addModule(HTBytecodeModule(fullName, content, mainBuilder.toBytes()));

    // return _curCompilation;
    return mainBuilder.toBytes();
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

  Uint8List _parseStmt(
      {SourceType sourceType = SourceType.function, bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    switch (sourceType) {
      case SourceType.script:
        switch (curTok.type) {
          // 忽略掉注释
          case SemanticType.singleLineComment:
          case SemanticType.multiLineComment:
            advance(1);
            break;
          case HTLexicon.IMPORT:
            _parseImportStmt();
            break;
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.ABSTRACT:
                advance(1);
                if (curTok.type != HTLexicon.CLASS) {
                  throw HTError.unexpected(
                      SemanticType.classDeclaration, curTok.lexeme);
                }
                final decl =
                    _parseClassDeclStmt(isAbstract: true, isExternal: true);
                bytesBuilder.add(decl);
                break;
              case HTLexicon.CLASS:
                final decl = _parseClassDeclStmt(isExternal: true);
                bytesBuilder.add(decl);
                break;
              case HTLexicon.ENUM:
                final decl = _parseEnumDeclStmt(isExternal: true);
                bytesBuilder.add(decl);
                break;
              case HTLexicon.VAR:
              case HTLexicon.LET:
              case HTLexicon.CONST:
                throw HTError.externalVar();
              case HTLexicon.FUNCTION:
                if (!expect([HTLexicon.FUNCTION, SemanticType.identifier])) {
                  throw HTError.unexpected(
                      SemanticType.functionDeclaration, peek(1).lexeme);
                }
                final decl = _parseFuncDeclaration(isExternal: true);
                bytesBuilder.add(decl);
                break;
              default:
                throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
            }
            break;
          case HTLexicon.ABSTRACT:
            advance(1);
            if (curTok.type != HTLexicon.CLASS) {
              throw HTError.unexpected(
                  SemanticType.classDeclaration, curTok.lexeme);
            }
            final decl = _parseClassDeclStmt(isAbstract: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.ENUM:
            final decl = _parseEnumDeclStmt();
            bytesBuilder.add(decl);
            break;
          case HTLexicon.CLASS:
            final decl = _parseClassDeclStmt();
            bytesBuilder.add(decl);
            break;
          case HTLexicon.VAR:
            final decl = _parseVarDeclStmt(); // forwardDeclaration: false);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.LET:
            final decl = _parseVarDeclStmt(
                typeInferrence: true); //, forwardDeclaration: false);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.CONST:
            final decl = _parseVarDeclStmt(
                typeInferrence: true,
                isImmutable: true); //, forwardDeclaration: false);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.FUNCTION:
            if (expect([HTLexicon.FUNCTION, SemanticType.identifier]) ||
                expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  SemanticType.identifier,
                  HTLexicon.squareRight,
                  SemanticType.identifier
                ])) {
              final decl = _parseFuncDeclaration();
              bytesBuilder.add(decl);
            } else {
              final expr = _parseExprStmt();
              bytesBuilder.add(expr);
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
          case HTLexicon.semicolon:
            advance(1);
            break;
          default:
            final expr = _parseExprStmt();
            bytesBuilder.add(expr);
            break;
        }
        break;
      case SourceType.module:
        switch (curTok.type) {
          // 忽略掉注释
          case SemanticType.singleLineComment:
          case SemanticType.multiLineComment:
            advance(1);
            break;
          case HTLexicon.IMPORT:
            _parseImportStmt();
            break;
          case HTLexicon.ABSTRACT:
            advance(1);
            if (curTok.type != HTLexicon.CLASS) {
              throw HTError.unexpected(
                  SemanticType.classDeclaration, curTok.lexeme);
            }
            final decl = _parseClassDeclStmt(isAbstract: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.EXTERNAL:
            advance(1);
            switch (curTok.type) {
              case HTLexicon.ABSTRACT:
                advance(1);
                if (curTok.type != HTLexicon.CLASS) {
                  throw HTError.unexpected(
                      SemanticType.classDeclaration, curTok.lexeme);
                }
                final decl =
                    _parseClassDeclStmt(isAbstract: true, isExternal: true);
                bytesBuilder.add(decl);
                break;
              case HTLexicon.CLASS:
                final decl = _parseClassDeclStmt(isExternal: true);
                bytesBuilder.add(decl);
                break;
              case HTLexicon.ENUM:
                final decl = _parseEnumDeclStmt(isExternal: true);
                bytesBuilder.add(decl);
                break;
              case HTLexicon.FUNCTION:
                final func = _parseFuncDeclaration(isExternal: true);
                bytesBuilder.add(func);
                break;
              case HTLexicon.VAR:
              case HTLexicon.LET:
              case HTLexicon.CONST:
                throw HTError.externalVar();
              default:
                throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
            }
            break;
          case HTLexicon.ENUM:
            final decl = _parseEnumDeclStmt();
            bytesBuilder.add(decl);
            break;
          case HTLexicon.CLASS:
            final decl = _parseClassDeclStmt();
            bytesBuilder.add(decl);
            break;
          case HTLexicon.VAR:
            final decl = _parseVarDeclStmt(lateInitialize: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.LET:
            final decl =
                _parseVarDeclStmt(typeInferrence: true, lateInitialize: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.CONST:
            final decl = _parseVarDeclStmt(
                typeInferrence: true, isImmutable: true, lateInitialize: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.FUNCTION:
            final func = _parseFuncDeclaration();
            bytesBuilder.add(func);
            break;
          default:
            throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
        }
        break;
      case SourceType.function:
        switch (curTok.type) {
          // 忽略掉注释
          case SemanticType.singleLineComment:
          case SemanticType.multiLineComment:
            advance(1);
            break;
          case HTLexicon.VAR:
            final decl = _parseVarDeclStmt(); // forwardDeclaration: false);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.LET:
            final decl = _parseVarDeclStmt(
                typeInferrence: true); //, forwardDeclaration: false);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.CONST:
            final decl = _parseVarDeclStmt(
                typeInferrence: true,
                isImmutable: true); //, forwardDeclaration: false);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.FUNCTION:
            if (expect([HTLexicon.FUNCTION, SemanticType.identifier]) ||
                expect([
                  HTLexicon.FUNCTION,
                  HTLexicon.squareLeft,
                  SemanticType.identifier,
                  HTLexicon.squareRight,
                  SemanticType.identifier
                ])) {
              final decl = _parseFuncDeclaration();
              bytesBuilder.add(decl);
            } else {
              final expr = _parseExprStmt();
              bytesBuilder.add(expr);
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
            if (_curFuncType == FunctionCategory.constructor) {
              throw HTError.outsideReturn();
            }
            final returnStmt = _parseReturnStmt();
            bytesBuilder.add(returnStmt);
            break;
          case HTLexicon.semicolon:
            advance(1);
            break;
          default:
            final expr = _parseExprStmt();
            bytesBuilder.add(expr);
            break;
        }
        break;
      case SourceType.klass:
        final isExternal = expect([HTLexicon.EXTERNAL], consume: true);
        final isStatic = expect([HTLexicon.STATIC], consume: true);
        switch (curTok.type) {
          // 忽略掉注释
          case SemanticType.singleLineComment:
          case SemanticType.multiLineComment:
            advance(1);
            break;
          case HTLexicon.VAR:
            final decl = _parseVarDeclStmt(
                isMember: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic,
                lateInitialize: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.LET:
            final decl = _parseVarDeclStmt(
                isMember: true,
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic,
                lateInitialize: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.CONST:
            final decl = _parseVarDeclStmt(
                isMember: true,
                typeInferrence: true,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isImmutable: true,
                isStatic: isStatic,
                lateInitialize: true);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.FUNCTION:
            final decl = _parseFuncDeclaration(
                category: FunctionCategory.method,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.CONSTRUCT:
            if (isStatic) {
              throw HTError.unexpected(
                  SemanticType.declStmt, HTLexicon.CONSTRUCT);
            }
            final decl = _parseFuncDeclaration(
              category: FunctionCategory.constructor,
              isExternal: isExternal || (_curClass?.isExternal ?? false),
            );
            bytesBuilder.add(decl);
            break;
          case HTLexicon.GET:
            final decl = _parseFuncDeclaration(
                category: FunctionCategory.getter,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
            bytesBuilder.add(decl);
            break;
          case HTLexicon.SET:
            final decl = _parseFuncDeclaration(
                category: FunctionCategory.setter,
                isExternal: isExternal || (_curClass?.isExternal ?? false),
                isStatic: isStatic);
            bytesBuilder.add(decl);
            break;
          default:
            throw HTError.unexpected(SemanticType.declStmt, curTok.lexeme);
        }
        break;
      case SourceType.expression:
        final expr = _parseExpr();
        bytesBuilder.add(expr);
        break;
    }
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }

    return bytesBuilder.toBytes();
  }

  void _parseImportStmt() {
    final keyword = advance(1);
    String key = match(SemanticType.literalString).literal;
    String? alias;
    if (expect([HTLexicon.AS], consume: true)) {
      alias = match(SemanticType.identifier).lexeme;

      if (alias.isEmpty) {
        throw HTError.emptyString();
      }
    }

    final showList = <String>[];
    if (curTok.lexeme == HTLexicon.SHOW) {
      advance(1);
      while (curTok.type == SemanticType.identifier) {
        showList.add(advance(1).lexeme);
        if (curTok.type != HTLexicon.comma) {
          break;
        } else {
          advance(1);
        }
      }
    }

    expect([HTLexicon.semicolon], consume: true);

    final stmt = ImportStmt(key, keyword.line, keyword.column,
        alias: alias, showList: showList);

    _curImports.add(stmt);
  }

  Uint8List _debugInfo() {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.lineInfo);
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
    if (config.lineInfo) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.NULL);
    return bytesBuilder.toBytes();
  }

  Uint8List _localBool(bool value) {
    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.boolean);
    bytesBuilder.addByte(value ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  Uint8List _localConst(int constIndex, int type) {
    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(type);
    bytesBuilder.add(_uint16(constIndex));
    return bytesBuilder.toBytes();
  }

  Uint8List _localSymbol({String? id, bool isGetKey = false}) {
    var symbolId = id ?? match(SemanticType.identifier).lexeme;
    if (_markedSymbolsList.isNotEmpty) {
      final map = _markedSymbolsList.last;
      for (final symbol in map.keys) {
        if (symbolId == symbol) {
          symbolId = map[symbol]!;
          break;
        }
      }
    }

    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
      bytesBuilder.add(_debugInfo());
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.symbol);
    bytesBuilder.add(_shortUtf8String(symbolId));
    bytesBuilder.addByte(isGetKey ? 1 : 0);
    if (expect([
          HTLexicon.angleLeft,
          SemanticType.identifier,
          HTLexicon.angleRight
        ]) ||
        expect([
          HTLexicon.angleLeft,
          SemanticType.identifier,
          HTLexicon.angleLeft
        ]) ||
        expect(
            [HTLexicon.angleLeft, SemanticType.identifier, HTLexicon.comma])) {
      bytesBuilder.addByte(1); // bool: has type args
      advance(1);
      final typeArgs = <Uint8List>[];
      while (curTok.type != HTLexicon.angleRight &&
          curTok.type != HTLexicon.endOfFile) {
        final typeArg = _parseTypeExpr();
        typeArgs.add(typeArg);
      }
      bytesBuilder.addByte(typeArgs.length);
      for (final arg in typeArgs) {
        bytesBuilder.add(arg);
      }
      match(HTLexicon.angleRight);
    } else {
      bytesBuilder.addByte(0); // bool: has type args
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _localList(List<Uint8List> exprList) {
    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
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
    if (config.lineInfo) {
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

  /// 使用递归向下的方法生成表达式，不断调用更底层的，优先级更高的子Parser
  ///
  /// 优先级最低的表达式，赋值表达式
  ///
  /// 赋值 = ，优先级 1，右合并
  ///
  /// 需要判断嵌套赋值、取属性、取下标的叠加
  ///
  /// [endOfExec]: 是否在解析完表达式后中断执行，这样可以返回当前表达式的值
  Uint8List _parseExpr({bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    final left = _parserTernaryExpr();
    if (HTLexicon.assignments.contains(curTok.type)) {
      if (!_leftValueLegality) {
        throw HTError.invalidLeftValue();
      }
      final op = advance(1).type;
      final right = _parseExpr(); // 右合并：先计算右边
      switch (op) {
        case HTLexicon.assign:
          bytesBuilder.add(right);
          break;
        case HTLexicon.assignAdd:
          bytesBuilder.add(left);
          bytesBuilder.addByte(HTOpCode.register);
          bytesBuilder.addByte(HTRegIdx.addLeft);
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.add);
          break;
        case HTLexicon.assignSubtract:
          bytesBuilder.add(left);
          bytesBuilder.addByte(HTOpCode.register);
          bytesBuilder.addByte(HTRegIdx.addLeft);
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.subtract);
          break;
        case HTLexicon.assignMultiply:
          bytesBuilder.add(left);
          bytesBuilder.addByte(HTOpCode.register);
          bytesBuilder.addByte(HTRegIdx.multiplyLeft);
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.multiply);
          break;
        case HTLexicon.assignDevide:
          bytesBuilder.add(left);
          bytesBuilder.addByte(HTOpCode.register);
          bytesBuilder.addByte(HTRegIdx.multiplyLeft);
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.devide);
          break;
      }
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.assign);
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.assign);
    } else {
      bytesBuilder.add(left);
    }
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }

    return bytesBuilder.toBytes();
  }

  /// Ternary expression parser:
  ///
  /// ```
  /// e1 ? e2 : e3
  /// ```
  ///
  /// 优先级 3，右合并
  Uint8List _parserTernaryExpr() {
    final bytesBuilder = BytesBuilder();
    final condition = _parseLogicalOrExpr();
    bytesBuilder.add(condition);
    if (expect([HTLexicon.condition], consume: true)) {
      _leftValueLegality = false;
      bytesBuilder.addByte(HTOpCode.ifStmt);
      // right combination: recursively use this same function on next expr
      final thenBranch = _parserTernaryExpr();
      match(HTLexicon.colon);
      final elseBranch = _parserTernaryExpr();
      final thenBranchLength = thenBranch.length + 3;
      final elseBranchLength = elseBranch.length;
      bytesBuilder.add(_uint16(thenBranchLength));
      bytesBuilder.add(thenBranch);
      bytesBuilder.addByte(HTOpCode.skip); // 执行完 then 之后，直接跳过 else block
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
        advance(1); // and operator
        bytesBuilder.addByte(HTOpCode.logicalOr);
        final right = _parseLogicalAndExpr();
        bytesBuilder.add(_uint16(right.length + 1)); // length of right value
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.endOfExec);
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
        bytesBuilder.addByte(HTOpCode.logicalAnd);
        final right = _parseEqualityExpr();
        bytesBuilder.add(_uint16(right.length + 1)); // length of right value
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.endOfExec);
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

  /// 逻辑比较 <, >, <=, >=，as, is, is! 优先级 8，不合并
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
        case HTLexicon.AS:
          final right = _parseTypeExpr(localValue: true);
          bytesBuilder.add(right);
          bytesBuilder.addByte(HTOpCode.typeAs);
          break;
        case HTLexicon.IS:
          final isNot = expect([HTLexicon.logicalNot], consume: true);
          final right = _parseTypeExpr(localValue: true);
          bytesBuilder.add(right);
          bytesBuilder.addByte(isNot ? HTOpCode.typeIsNot : HTOpCode.typeIs);
          break;
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
    final object = _parsePrimaryExpr();
    bytesBuilder.add(object); // object will stay in reg[14]
    while (HTLexicon.unaryPostfixs.contains(curTok.type)) {
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.postfixObject);
      final op = advance(1).type;
      switch (op) {
        case HTLexicon.memberGet:
          _leftValueLegality = true;
          // bytesBuilder
          //     .addByte(HTOpCode.leftValue); // save left value name in reg
          final key = _localSymbol(isGetKey: true); // shortUtf8String
          bytesBuilder.add(key);
          bytesBuilder.addByte(HTOpCode.register);
          bytesBuilder.addByte(HTRegIdx.postfixKey);
          bytesBuilder.addByte(HTOpCode.member);
          break;
        case HTLexicon.subGet:
          final key = _parseExpr(endOfExec: true);
          _leftValueLegality = true;
          match(HTLexicon.squareRight);
          bytesBuilder.addByte(HTOpCode.subscript);
          // sub get key is after opcode
          // it has to be exec with 'move reg index'
          bytesBuilder.add(key);
          break;
        case HTLexicon.call:
          _leftValueLegality = false;
          bytesBuilder.addByte(HTOpCode.call);
          final callArgs = _parseCallArguments();
          bytesBuilder.add(callArgs);
          break;
        default:
          break;
      }
    }
    return bytesBuilder.toBytes();
  }

  /// Expression without operators
  Uint8List _parsePrimaryExpr() {
    switch (curTok.type) {
      case HTLexicon.NULL:
        _leftValueLegality = false;
        advance(1);
        return _localNull();
      case SemanticType.literalBoolean:
        _leftValueLegality = false;
        return _localBool(advance(1).literal);
      case SemanticType.literalInteger:
        _leftValueLegality = false;
        final value = curTok.literal;
        var index = _curConstTable.addInt(value);
        advance(1);
        return _localConst(index, HTValueTypeCode.constInt);
      case SemanticType.literalFloat:
        _leftValueLegality = false;
        final value = curTok.literal;
        var index = _curConstTable.addFloat(value);
        advance(1);
        return _localConst(index, HTValueTypeCode.constFloat);
      case SemanticType.literalString:
        _leftValueLegality = false;
        final value = curTok.literal;
        var index = _curConstTable.addString(value);
        advance(1);
        return _localConst(index, HTValueTypeCode.constString);
      case HTLexicon.THIS:
        _leftValueLegality = false;
        advance(1);
        return _localSymbol(id: HTLexicon.THIS);
      case HTLexicon.SUPER:
        _leftValueLegality = false;
        advance(1);
        return _localSymbol(id: HTLexicon.SUPER);
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
      // literal function
      case HTLexicon.FUNCTION:
        _leftValueLegality = false;
        return _parseFuncDeclaration(category: FunctionCategory.literal);
      // literal function type
      // case HTLexicon.FUNTYPE:
      //   _leftValueLegality = false;
      //   return _parseFunctionTypeExpr(localValue: true);
      case SemanticType.identifier:
        _leftValueLegality = true;
        return _localSymbol();
      default:
        throw HTError.unexpected(SemanticType.expression, curTok.lexeme);
    }
  }

  Uint8List _parseFunctionTypeExpr({bool localValue = false}) {
    advance(1);
    final bytesBuilder = BytesBuilder();
    if (localValue) {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.type);
    }
    bytesBuilder.addByte(TypeType.function.index); // enum: type type

    // TODO: genericTypeParameters 泛型参数

    match(HTLexicon.roundLeft);

    final paramTypes = <Uint8List>[];

    var isOptional = false;
    var isNamed = false;
    var isVariadic = false;

    while (curTok.type != HTLexicon.roundRight &&
        curTok.type != HTLexicon.endOfFile) {
      final paramBytesBuilder = BytesBuilder();
      if (!isOptional) {
        isOptional = expect([HTLexicon.squareLeft], consume: true);
        if (!isOptional && !isNamed) {
          isNamed = expect([HTLexicon.curlyLeft], consume: true);
        }
      }

      late final paramType;
      String? paramName;
      if (!isNamed) {
        isVariadic = expect([HTLexicon.variadicArgs], consume: true);
      } else {
        paramName = match(SemanticType.identifier).lexeme;
        match(HTLexicon.colon);
      }

      paramType = _parseTypeExpr();

      paramBytesBuilder.add(paramType);
      paramBytesBuilder.addByte(isOptional ? 1 : 0);
      paramBytesBuilder.addByte(isNamed ? 1 : 0);
      if (paramName != null) {
        paramBytesBuilder.add(_shortUtf8String(paramName));
      }
      paramBytesBuilder.addByte(isVariadic ? 1 : 0);

      paramTypes.add(paramBytesBuilder.toBytes());

      if (isOptional && expect([HTLexicon.squareRight], consume: true)) {
        break;
      } else if (isNamed && expect([HTLexicon.curlyRight], consume: true)) {
        break;
      } else if (curTok.type != HTLexicon.roundRight) {
        match(HTLexicon.comma);
      }

      if (isVariadic) {
        break;
      }
    }
    match(HTLexicon.roundRight);

    bytesBuilder.addByte(paramTypes.length); // uint8: length of param types
    for (final paramType in paramTypes) {
      bytesBuilder.add(paramType);
    }

    match(HTLexicon.singleArrow);
    final returnType = _parseTypeExpr();
    bytesBuilder.add(returnType);

    return bytesBuilder.toBytes();
  }

  // TODO: interface type
  Uint8List _parseTypeExpr({bool localValue = false}) {
    if (curTok.type != HTLexicon.FUNCTION) {
      final bytesBuilder = BytesBuilder();
      if (localValue) {
        bytesBuilder.addByte(HTOpCode.local);
        bytesBuilder.addByte(HTValueTypeCode.type);
      }
      final id = match(SemanticType.identifier).lexeme;

      bytesBuilder.add(_shortUtf8String(id));

      final typeArgs = <Uint8List>[];
      if (expect([HTLexicon.angleLeft], consume: true)) {
        if (curTok.type == HTLexicon.angleRight) {
          throw HTError.emptyTypeArgs();
        }
        while ((curTok.type != HTLexicon.angleRight) &&
            (curTok.type != HTLexicon.endOfFile)) {
          typeArgs.add(_parseTypeExpr());
          expect([HTLexicon.comma], consume: true);
        }
        match(HTLexicon.angleRight);
      }

      bytesBuilder.addByte(typeArgs.length); // max 255
      for (final arg in typeArgs) {
        bytesBuilder.add(arg);
      }

      final isNullable = expect([HTLexicon.nullable], consume: true);
      bytesBuilder.addByte(isNullable ? 1 : 0); // bool isNullable

      return bytesBuilder.toBytes();
    } else {
      return _parseFunctionTypeExpr();
    }
  }

  Uint8List _parseBlockStmt(
      {SourceType sourceType = SourceType.function,
      String? id,
      List<Uint8List> additionalVarDecl = const [],
      List<Uint8List> additionalStatements = const [],
      bool createNamespace = true,
      bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    // final savedDeclBlock = _curBlock;
    // _curBlock = BytecodeDeclarationBlock();
    match(HTLexicon.curlyLeft);
    if (createNamespace) {
      bytesBuilder.addByte(HTOpCode.block);
      if (id == null) {
        bytesBuilder.add(_shortUtf8String(HTLexicon.anonymousBlock));
      } else {
        bytesBuilder.add(_shortUtf8String(id));
      }
    }
    // final declsBytesBuilder = BytesBuilder();
    final blockBytesBuilder = BytesBuilder();
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.endOfFile) {
      // Function sourceType will not forwarding declaration
      // Module sourceType will late initialize
      // Class sourceType will use both technique
      final stmt = _parseStmt(sourceType: sourceType);
      blockBytesBuilder.add(stmt);
    }
    match(HTLexicon.curlyRight);
    // 添加前置变量表，总是按照：枚举、函数、类、变量这个顺序
    // for (final decl in _curBlock.enumDecls.values) {
    //   declsBytesBuilder.add(decl);
    // }
    // for (final decl in _curBlock.funcDecls.values) {
    //   declsBytesBuilder.add(decl);
    // }
    // for (final decl in _curBlock.classDecls.values) {
    //   declsBytesBuilder.add(decl);
    // }
    for (final decl in additionalVarDecl) {
      bytesBuilder.add(decl);
    }
    // for (final decl in _curBlock.varDecls.values) {
    //   declsBytesBuilder.add(decl);
    // }
    // bytesBuilder.add(declsBytesBuilder.toBytes());
    for (final stmt in additionalStatements) {
      bytesBuilder.add(stmt);
    }
    bytesBuilder.add(blockBytesBuilder.toBytes());
    // _curBlock = savedDeclBlock;
    if (createNamespace) {
      bytesBuilder.addByte(HTOpCode.endOfBlock);
    }
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _parseCallArguments({bool hasLength = false}) {
    // 这里不判断左括号，已经跳过了
    final bytesBuilder = BytesBuilder();
    final positionalArgs = <Uint8List>[];
    final namedArgs = <String, Uint8List>{};
    var isNamed = false;
    while ((curTok.type != HTLexicon.roundRight) &&
        (curTok.type != HTLexicon.endOfFile)) {
      if ((!isNamed &&
              expect([SemanticType.identifier, HTLexicon.colon],
                  consume: false)) ||
          isNamed) {
        isNamed = true;
        final name = match(SemanticType.identifier).lexeme;
        match(HTLexicon.colon);
        namedArgs[name] = _parseExpr(endOfExec: true);
      } else {
        positionalArgs.add(_parseExpr(endOfExec: true));
      }
      if (curTok.type != HTLexicon.roundRight) {
        match(HTLexicon.comma);
      }
    }
    match(HTLexicon.roundRight);
    bytesBuilder.addByte(positionalArgs.length);
    for (var i = 0; i < positionalArgs.length; ++i) {
      final argExpr = positionalArgs[i];
      if (hasLength) {
        bytesBuilder.add(_uint16(argExpr.length));
      }
      bytesBuilder.add(argExpr);
    }
    bytesBuilder.addByte(namedArgs.length);
    for (final name in namedArgs.keys) {
      final nameExpr = _shortUtf8String(name);
      bytesBuilder.add(nameExpr);
      final argExpr = namedArgs[name]!;
      if (hasLength) {
        bytesBuilder.add(_uint16(argExpr.length));
      }
      bytesBuilder.add(argExpr);
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
      thenBranch = _parseBlockStmt(id: SemanticType.thenBranch);
    } else {
      thenBranch = _parseStmt();
    }
    Uint8List? elseBranch;
    if (expect([HTLexicon.ELSE], consume: true)) {
      if (curTok.type == HTLexicon.curlyLeft) {
        elseBranch = _parseBlockStmt(id: HTLexicon.elseBranch);
      } else {
        elseBranch = _parseStmt();
      }
    }
    final thenBranchLength = thenBranch.length + 3;
    final elseBranchLength = elseBranch?.length ?? 0;

    bytesBuilder.add(_uint16(thenBranchLength));
    bytesBuilder.add(thenBranch);
    bytesBuilder.addByte(HTOpCode.skip); // 执行完 then 之后，直接跳过 else block
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
      loopBody = _parseBlockStmt(id: SemanticType.whileStmt);
    } else {
      loopBody = _parseStmt();
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
    bytesBuilder.addByte(HTOpCode.skip);
    bytesBuilder.add(_int16(-loopLength));
    return bytesBuilder.toBytes();
  }

  Uint8List _parseDoStmt() {
    advance(1);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.loopPoint);
    Uint8List loopBody;
    if (curTok.type == HTLexicon.curlyLeft) {
      loopBody = _parseBlockStmt(id: SemanticType.whileStmt);
    } else {
      loopBody = _parseStmt();
    }
    Uint8List? condition;
    if (expect([HTLexicon.WHILE], consume: true)) {
      match(HTLexicon.roundLeft);
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    final loopLength = loopBody.length + (condition?.length ?? 0) + 1;
    bytesBuilder.add(_uint16(0)); // while loop continue ip
    bytesBuilder.add(_uint16(loopLength)); // while loop break ip
    bytesBuilder.add(loopBody);
    if (condition != null) {
      bytesBuilder.add(condition);
    }
    bytesBuilder.addByte(HTOpCode.doStmt);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleLocalConstInt(int value, {bool endOfExec = false}) {
    _leftValueLegality = true;
    final bytesBuilder = BytesBuilder();

    final index = _curConstTable.addInt(0);
    final constExpr = _localConst(index, HTValueTypeCode.constInt);
    bytesBuilder.add(constExpr);
    if (endOfExec) bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleLocalSymbol(String id,
      {bool isGetKey = false, bool endOfExec = false}) {
    _leftValueLegality = true;
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.symbol);
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(isGetKey ? 1 : 0); // bool: isGetKey
    bytesBuilder.addByte(0); // bool: has type args
    if (endOfExec) bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleMemberGet(Uint8List object, String key,
      {bool endOfExec = false}) {
    _leftValueLegality = true;
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    // bytesBuilder.addByte(HTOpCode.leftValue); // save object symbol name in reg
    final keySymbol = _assembleLocalSymbol(key, isGetKey: true);
    bytesBuilder.add(keySymbol);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixKey);
    bytesBuilder.addByte(HTOpCode.member);
    if (endOfExec) bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleVarDeclStmt(String id,
      {Uint8List? initializer, bool lateInitialize = true}) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.varDecl);
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(0); // bool: hasClassId
    bytesBuilder.addByte(initializer != null ? 1 : 0); // bool: isDynamic
    bytesBuilder.addByte(0); // bool: isExternal
    bytesBuilder.addByte(0); // bool: isImmutable
    bytesBuilder.addByte(0); // bool: isStatic
    bytesBuilder.addByte(lateInitialize ? 1 : 0); // bool: lateInitialize
    bytesBuilder.addByte(0); // bool: hasType

    if (initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      if (lateInitialize) {
        bytesBuilder.add(_uint16(curTok.line));
        bytesBuilder.add(_uint16(curTok.column));
        bytesBuilder.add(_uint16(initializer.length));
      }
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
    bytesBuilder.add(_shortUtf8String(SemanticType.forStmtInit));
    match(HTLexicon.roundLeft);
    final forStmtType = peek(2).lexeme;
    Uint8List? condition;
    Uint8List? increment;
    final additionalVarDecls = <Uint8List>[];
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (forStmtType == HTLexicon.IN) {
      if (!HTLexicon.varDeclKeywords.contains(curTok.type)) {
        throw HTError.unexpected(SemanticType.variableDeclaration, curTok.type);
      }
      final declPos = tokPos;
      // jump over keywrod
      advance(3);
      // get id of var decl and jump over in/of
      final object = _parseExpr();
      final blockStartPos = tokPos;

      final increId = HTLexicon.increment;
      final increInit = _assembleLocalConstInt(0, endOfExec: true);
      final increDecl = _assembleVarDeclStmt(increId, initializer: increInit);
      bytesBuilder.add(increDecl);

      final conditionBytesBuilder = BytesBuilder();
      final isNotEmptyExpr = _assembleMemberGet(object, HTLexicon.isNotEmpty);
      conditionBytesBuilder.add(isNotEmptyExpr);
      conditionBytesBuilder.addByte(HTOpCode.register);
      conditionBytesBuilder.addByte(HTRegIdx.andLeft);
      conditionBytesBuilder.addByte(HTOpCode.logicalAnd);
      final lesserLeftExpr = _assembleLocalSymbol(increId);
      final iterableLengthExpr = _assembleMemberGet(object, HTLexicon.length);
      final logicalAndRightLength =
          lesserLeftExpr.length + iterableLengthExpr.length + 4;
      conditionBytesBuilder.add(_uint16(logicalAndRightLength));
      conditionBytesBuilder.add(lesserLeftExpr);
      conditionBytesBuilder.addByte(HTOpCode.register);
      conditionBytesBuilder.addByte(HTRegIdx.relationLeft);
      conditionBytesBuilder.add(iterableLengthExpr);
      conditionBytesBuilder.addByte(HTOpCode.lesser);
      conditionBytesBuilder.addByte(HTOpCode.endOfExec);
      condition = conditionBytesBuilder.toBytes();

      final initBytesBuilder = BytesBuilder();
      final getElemFunc = _assembleMemberGet(object, HTLexicon.elementAt);
      initBytesBuilder.add(getElemFunc);
      initBytesBuilder.addByte(HTOpCode.register);
      initBytesBuilder.addByte(HTRegIdx.postfixObject);
      initBytesBuilder.addByte(HTOpCode.call);
      initBytesBuilder.addByte(1); // length of positionalArgs
      final getElemFuncCallArg = _assembleLocalSymbol(increId);
      initBytesBuilder.add(getElemFuncCallArg);
      initBytesBuilder.addByte(HTOpCode.endOfExec);
      initBytesBuilder.addByte(0); // length of namedArgs
      initBytesBuilder.addByte(HTOpCode.endOfExec);
      final iterInitializer = initBytesBuilder.toBytes();
      tokPos = declPos;
      // go back to var declaration
      final iterDecl = _parseVarDeclStmt(
          typeInferrence: curTok.type != HTLexicon.VAR,
          isImmutable: curTok.type == HTLexicon.CONST,
          additionalInitializer:
              iterInitializer); //, forwardDeclaration: false);
      tokPos = blockStartPos;
      additionalVarDecls.add(iterDecl);

      final incrementBytesBuilder = BytesBuilder();
      final preIncreExpr = _assembleLocalSymbol(increId);
      incrementBytesBuilder.add(preIncreExpr);
      // incrementBytesBuilder.addByte(HTOpCode.preIncrement);
      increment = incrementBytesBuilder.toBytes();

      match(HTLexicon.roundRight);
    }
    // for (var i = 0; i < length; ++i)
    else {
      if (!expect([HTLexicon.semicolon], consume: false)) {
        // TODO: 如果有多个变量同时声明?
        final initDeclId = peek(1).lexeme;
        final markedId = '${HTLexicon.internalMarker}$initDeclId';
        newSymbolMap[initDeclId] = markedId;
        final initDecl = _parseVarDeclStmt(
            declId: markedId,
            typeInferrence: curTok.type != HTLexicon.VAR,
            isImmutable: curTok.type == HTLexicon.CONST,
            endOfStatement: true); //, forwardDeclaration: false);

        // final increId = HTLexicon.increment;
        // final increInit = _assembleLocalSymbol(initDeclId, endOfExec: true);
        // final increDecl = _assembleVarDeclStmt(increId, initializer: increInit);

        // 添加声明
        bytesBuilder.add(initDecl);
        // bytesBuilder.add(increDecl);

        // TODO: 这里是为了实现闭包效果，之后应该改成真正的闭包
        final capturedInit = _assembleLocalSymbol(markedId, endOfExec: true);
        final capturedDecl = _assembleVarDeclStmt(initDeclId,
            initializer: capturedInit, lateInitialize: false);
        additionalVarDecls.add(capturedDecl);

        // final assignBytesBuilder = BytesBuilder();
        // final assignRightExpr = _assembleLocalSymbol(initDeclId);
        // assignBytesBuilder.add(assignRightExpr);
        // assignBytesBuilder.addByte(HTOpCode.register);
        // assignBytesBuilder.addByte(HTRegIdx.assign);
        // final assignLeftExpr = _assembleLocalSymbol(increId);
        // assignBytesBuilder.add(assignLeftExpr);
        // assignBytesBuilder.addByte(HTOpCode.assign);
        // assign = assignBytesBuilder.toBytes();
      } else {
        match(HTLexicon.semicolon);
      }

      if (!expect([HTLexicon.semicolon], consume: false)) {
        condition = _parseExpr();
      }
      match(HTLexicon.semicolon);

      if (!expect([HTLexicon.roundRight], consume: false)) {
        increment = _parseExpr();
      }
      match(HTLexicon.roundRight);
    }

    bytesBuilder.addByte(HTOpCode.loopPoint);
    final loop = _parseBlockStmt(
        id: SemanticType.forStmt, additionalVarDecl: additionalVarDecls);
    final continueLength = (condition?.length ?? 0) + loop.length + 2;
    final breakLength = continueLength + (increment?.length ?? 0) + 3;
    bytesBuilder.add(_uint16(continueLength));
    bytesBuilder.add(_uint16(breakLength));
    if (condition != null) bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.whileStmt);
    bytesBuilder.addByte((condition != null) ? 1 : 0); // bool: has condition
    bytesBuilder.add(loop);
    if (increment != null) bytesBuilder.add(increment);
    bytesBuilder.addByte(HTOpCode.skip);
    bytesBuilder.add(_int16(-breakLength));

    _markedSymbolsList.removeLast();

    bytesBuilder.addByte(HTOpCode.endOfBlock);
    return bytesBuilder.toBytes();
  }

  Uint8List _parseWhenStmt() {
    advance(1);
    final bytesBuilder = BytesBuilder();
    Uint8List? condition;
    if (expect([HTLexicon.roundLeft], consume: true)) {
      condition = _parseExpr();
      match(HTLexicon.roundRight);
    }
    final cases = <Uint8List>[];
    final branches = <Uint8List>[];
    Uint8List? elseBranch;
    match(HTLexicon.curlyLeft);
    while (curTok.type != HTLexicon.curlyRight &&
        curTok.type != HTLexicon.endOfFile) {
      if (curTok.lexeme == HTLexicon.ELSE) {
        advance(1);
        match(HTLexicon.singleArrow);
        if (curTok.type == HTLexicon.curlyLeft) {
          elseBranch = _parseBlockStmt(id: SemanticType.whenStmt);
        } else {
          elseBranch = _parseStmt();
        }
      } else {
        final caseExpr = _parseExpr(endOfExec: true);
        cases.add(caseExpr);
        match(HTLexicon.singleArrow);
        late final caseBranch;
        if (curTok.type == HTLexicon.curlyLeft) {
          caseBranch = _parseBlockStmt(id: SemanticType.whenStmt);
        } else {
          caseBranch = _parseStmt();
        }
        branches.add(caseBranch);
      }
    }

    match(HTLexicon.curlyRight);

    bytesBuilder.addByte(HTOpCode.anchor);
    if (condition != null) {
      bytesBuilder.add(condition);
    }
    bytesBuilder.addByte(HTOpCode.whenStmt);
    bytesBuilder.addByte(condition != null ? 1 : 0);
    bytesBuilder.addByte(cases.length);

    var curIp = 0;
    // the first ip in the branches list
    bytesBuilder.add(_uint16(0));
    for (var i = 1; i < branches.length; ++i) {
      curIp = curIp + branches[i - 1].length + 3;
      bytesBuilder.add(_uint16(curIp));
    }
    curIp = curIp + branches.last.length + 3;
    if (elseBranch != null) {
      bytesBuilder.add(_uint16(curIp)); // else branch ip
    } else {
      bytesBuilder.add(_uint16(0)); // has no else
    }
    final endIp = curIp + (elseBranch?.length ?? 0);
    bytesBuilder.add(_uint16(endIp));

    // calculate the length of the code, for goto the specific location of branches
    var offsetIp = (condition?.length ?? 0) + 3 + branches.length * 2 + 4;

    for (final expr in cases) {
      bytesBuilder.add(expr);
      offsetIp += expr.length;
    }

    for (var i = 0; i < branches.length; ++i) {
      bytesBuilder.add(branches[i]);
      bytesBuilder.addByte(HTOpCode.goto);
      bytesBuilder.add(_uint16(offsetIp + endIp));
    }

    if (elseBranch != null) {
      bytesBuilder.add(elseBranch);
    }

    return bytesBuilder.toBytes();
  }

  /// 变量声明语句
  Uint8List _parseVarDeclStmt(
      {String? declId,
      bool isMember = false,
      bool typeInferrence = false,
      bool isExternal = false,
      bool isImmutable = false,
      bool isStatic = false,
      bool lateInitialize = false,
      Uint8List? additionalInitializer,
      bool endOfStatement = false
      // , bool forwardDeclaration = true
      }) {
    advance(1);
    var id = match(SemanticType.identifier).lexeme;

    if (isMember && isExternal) {
      if (!(_curClass!.isExternal) && !isStatic) {
        throw HTError.externMember();
      }
      id = '${_curClass!.id}.$id';
    }

    if (declId != null) {
      id = declId;
    }

    // if (_curBlock.contains(id)) {
    //   throw HTError.definedParser(id);
    // }

    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.varDecl);
    bytesBuilder.add(_shortUtf8String(id));
    if (isMember) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_shortUtf8String(_curClass!.id));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    bytesBuilder.addByte(typeInferrence ? 1 : 0);
    bytesBuilder.addByte(isExternal ? 1 : 0);
    bytesBuilder.addByte(isImmutable ? 1 : 0);
    bytesBuilder.addByte(isStatic ? 1 : 0);
    bytesBuilder.addByte(lateInitialize ? 1 : 0);

    if (expect([HTLexicon.colon], consume: true)) {
      bytesBuilder.addByte(1); // bool: has type
      bytesBuilder.add(_parseTypeExpr());
    } else {
      bytesBuilder.addByte(0); // bool: has type
    }

    var initializer = additionalInitializer;
    if (expect([HTLexicon.assign], consume: true)) {
      initializer = _parseExpr(endOfExec: true);
    }

    if (initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      if (lateInitialize) {
        bytesBuilder.add(_uint16(curTok.line));
        bytesBuilder.add(_uint16(curTok.column));
        bytesBuilder.add(_uint16(initializer.length));
      }
      bytesBuilder.add(initializer);
    } else {
      if (isImmutable && !isExternal) {
        throw HTError.constMustInit(id);
      }

      bytesBuilder.addByte(0); // bool: has initializer
    }

    // 语句结尾
    if (endOfStatement) {
      match(HTLexicon.semicolon);
    } else {
      expect([HTLexicon.semicolon], consume: true);
    }

    final bytes = bytesBuilder.toBytes();
    // if (forwardDeclaration) {
    //   _curBlock.varDecls[id] = bytes;
    // }

    return bytes;
  }

  Uint8List _parseFuncDeclaration(
      {FunctionCategory category = FunctionCategory.normal,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false}) {
    final savedCurFuncType = _curFuncType;
    _curFuncType = category;

    advance(1);

    String? externalTypeId;
    if (!isExternal &&
        (isStatic ||
            category == FunctionCategory.normal ||
            category == FunctionCategory.literal)) {
      if (expect([HTLexicon.squareLeft], consume: true)) {
        if (isExternal) {
          throw HTError.internalFuncWithExternalTypeDef();
        }
        externalTypeId = match(SemanticType.identifier).lexeme;
        match(HTLexicon.squareRight);
      }
    }

    var declId = '';
    late String id;

    if (category != FunctionCategory.literal) {
      if (category == FunctionCategory.constructor) {
        if (curTok.type == SemanticType.identifier) {
          declId = advance(1).lexeme;
        }
      } else {
        declId = match(SemanticType.identifier).lexeme;
      }
    }

    // if (!isExternal) {
    switch (category) {
      case FunctionCategory.constructor:
        id = (declId.isEmpty)
            ? HTLexicon.constructor
            : '${HTLexicon.constructor}$declId';
        // if (_curBlock.contains(id)) {
        //   throw HTError.definedParser(declId);
        // }
        break;
      case FunctionCategory.getter:
        id = HTLexicon.getter + declId;
        // if (_curBlock.contains(id)) {
        //   throw HTError.definedParser(declId);
        // }
        break;
      case FunctionCategory.setter:
        id = HTLexicon.setter + declId;
        // if (_curBlock.contains(id)) {
        //   throw HTError.definedParser(declId);
        // }
        break;
      case FunctionCategory.literal:
        id = HTLexicon.anonymousFunction +
            (AbstractParser.anonymousFuncIndex++).toString();
        break;
      default:
        id = declId;
    }
    // } else {
    //   if (_curClass != null) {
    //     if (!(_curClass!.isExternal) && !isStatic) {
    //       throw HTError.externalMember();
    //     }
    //     if (isStatic || (category == FunctionType.constructor)) {
    //       id = (declId.isEmpty) ? _curClass!.id : '${_curClass!.id}.$declId';
    //     } else {
    //       id = declId;
    //     }
    //   } else {
    //     id = declId;
    //   }
    // }

    final bytesBuilder = BytesBuilder();
    if (category != FunctionCategory.literal) {
      bytesBuilder.addByte(HTOpCode.funcDecl);
      // funcBytesBuilder.addByte(HTOpCode.funcDecl);
      bytesBuilder.add(_shortUtf8String(id));
      bytesBuilder.add(_shortUtf8String(declId));

      // if (expect([HTLexicon.angleLeft], consume: true)) {
      //   // 泛型param
      //   super_class_type_args = _parseType();
      //   match(HTLexicon.angleRight);
      // }

      if (externalTypeId != null) {
        bytesBuilder.addByte(1);
        bytesBuilder.add(_shortUtf8String(externalTypeId));
      } else {
        bytesBuilder.addByte(0);
      }

      bytesBuilder.addByte(category.index);
      bytesBuilder.addByte(isExternal ? 1 : 0);
      bytesBuilder.addByte(isStatic ? 1 : 0);
      bytesBuilder.addByte(isConst ? 1 : 0);
    } else {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.function);
      bytesBuilder.add(_shortUtf8String(id));

      if (externalTypeId != null) {
        bytesBuilder.addByte(1);
        bytesBuilder.add(_shortUtf8String(externalTypeId));
      } else {
        bytesBuilder.addByte(0);
      }
    }

    var isFuncVariadic = false;
    var minArity = 0;
    var maxArity = 0;
    var paramDecls = <Uint8List>[];

    if (category != FunctionCategory.getter &&
        expect([HTLexicon.roundLeft], consume: true)) {
      bytesBuilder.addByte(1); // bool: has parameter declarations
      var isOptional = false;
      var isNamed = false;
      var isVariadic = false;
      while ((curTok.type != HTLexicon.roundRight) &&
          (curTok.type != HTLexicon.squareRight) &&
          (curTok.type != HTLexicon.curlyRight) &&
          (curTok.type != HTLexicon.endOfFile)) {
        // 可选参数，根据是否有方括号判断，一旦开始了可选参数，则不再增加 minArity
        if (!isOptional) {
          isOptional = expect([HTLexicon.squareLeft], consume: true);
          if (!isOptional && !isNamed) {
            //命名参数，根据是否有花括号判断
            isNamed = expect([HTLexicon.curlyLeft], consume: true);
          }
        }

        if (!isNamed) {
          isVariadic = expect([HTLexicon.variadicArgs], consume: true);
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
        var paramId = match(SemanticType.identifier).lexeme;
        paramBytesBuilder.add(_shortUtf8String(paramId));
        paramBytesBuilder.addByte(isOptional ? 1 : 0);
        paramBytesBuilder.addByte(isNamed ? 1 : 0);
        paramBytesBuilder.addByte(isVariadic ? 1 : 0);

        // 参数类型
        if (expect([HTLexicon.colon], consume: true)) {
          paramBytesBuilder.addByte(1); // bool: has type
          paramBytesBuilder.add(_parseTypeExpr());
        } else {
          paramBytesBuilder.addByte(0); // bool: has type
        }

        Uint8List? initializer;
        // 参数默认值
        if (expect([HTLexicon.assign], consume: true)) {
          if (isOptional || isNamed) {
            initializer = _parseExpr(endOfExec: true);
            paramBytesBuilder.addByte(1); // bool，hasInitializer
            paramBytesBuilder.add(_uint16(initializer.length));
            paramBytesBuilder.add(initializer);
          } else {
            throw HTError.argInit(); // bool，hasInitializer
          }
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

      // setter can only have one parameter
      if ((category == FunctionCategory.setter) && (minArity != 1)) {
        throw HTError.setterArity();
      }
    } else {
      bytesBuilder.addByte(0); // bool: has parameter declarations
    }

    bytesBuilder.addByte(isFuncVariadic ? 1 : 0);

    bytesBuilder.addByte(minArity);
    bytesBuilder.addByte(maxArity);
    bytesBuilder.addByte(paramDecls.length); // max 255
    for (var decl in paramDecls) {
      bytesBuilder.add(decl);
    }

    // the return value type declaration
    if (expect([HTLexicon.singleArrow], consume: true)) {
      if (category == FunctionCategory.constructor) {
        throw HTError.ctorReturn();
      }
      bytesBuilder.addByte(FunctionAppendixType
          .type.index); // enum: return type or super constructor
      bytesBuilder.add(_parseTypeExpr());
    }
    // referring to another constructor
    else if (expect([HTLexicon.colon], consume: true)) {
      if (category != FunctionCategory.constructor) {
        throw HTError.nonCotrWithReferCtor();
      }
      if (isExternal) {
        throw HTError.externalCtorWithReferCtor();
      }

      final ctorId = advance(1).lexeme;
      if (!HTLexicon.constructorCall.contains(ctorId)) {
        throw HTError.unexpected(SemanticType.ctorCallExpr, curTok.lexeme);
      }

      bytesBuilder.addByte(FunctionAppendixType
          .referConstructor.index); // enum: return type or super constructor
      if (expect([HTLexicon.memberGet], consume: true)) {
        bytesBuilder.addByte(1); // bool: has super constructor name
        final superCtorId = match(SemanticType.identifier).lexeme;
        bytesBuilder.add(_shortUtf8String(superCtorId));
        match(HTLexicon.roundLeft);
      } else {
        match(HTLexicon.roundLeft);
        bytesBuilder.addByte(0); // bool: has super constructor name
      }

      final callArgs = _parseCallArguments(hasLength: true);
      bytesBuilder.add(callArgs);
    } else {
      bytesBuilder.addByte(FunctionAppendixType.none.index);
    }

    // 处理函数定义部分的语句块
    if (curTok.type == HTLexicon.curlyLeft) {
      bytesBuilder.addByte(1); // bool: has definition
      bytesBuilder.add(_uint16(curTok.line));
      bytesBuilder.add(_uint16(curTok.column));
      final body = _parseBlockStmt(id: HTLexicon.functionCall);
      bytesBuilder.add(_uint16(body.length + 1)); // definition bytes length
      bytesBuilder.add(body);
      bytesBuilder.addByte(HTOpCode.endOfFunc);
    } else {
      if (category != FunctionCategory.constructor &&
          category != FunctionCategory.literal &&
          !isExternal &&
          !(_curClass?.isAbstract ?? false)) {
        throw HTError.missingFuncBody(id);
      }
      bytesBuilder.addByte(0); // bool: has no definition
      expect([HTLexicon.semicolon], consume: true);
    }

    _curFuncType = savedCurFuncType;

    return bytesBuilder.toBytes();
  }

  Uint8List _parseClassDeclStmt(
      {bool isExternal = false, bool isAbstract = false}) {
    advance(1); // keyword
    final bytesBuilder = BytesBuilder();
    final id = match(SemanticType.identifier).lexeme;
    bytesBuilder.addByte(HTOpCode.classDecl);
    bytesBuilder.add(_shortUtf8String(id));

    // if (expect([HTLexicon.angleLeft], consume: true)) {
    //   // 泛型param
    //   super_class_type_args = _parseType();
    //   match(HTLexicon.angleRight);
    // }

    // if (_curBlock.contains(id)) {
    //   throw HTError.definedParser(id);
    // }

    final savedClass = _curClass;

    _curClass = ClassDeclaration(id, _curModuleFullName, _curLibraryName,
        isExternal: isExternal, isAbstract: isAbstract);

    bytesBuilder.addByte(isExternal ? 1 : 0);
    bytesBuilder.addByte(isAbstract ? 1 : 0);

    Uint8List? superClassType;
    if (expect([HTLexicon.EXTENDS], consume: true)) {
      if (curTok.lexeme == id) {
        throw HTError.extendsSelf();
      }

      superClassType = _parseTypeExpr();

      // else if (!_curBlock.classDecls.containsKey(id)) {
      //   throw HTError.notClass(superClassId);
      // }

      bytesBuilder.addByte(1); // bool: has super class
      bytesBuilder.add(superClassType);

      // if (expect([HTLexicon.angleLeft], consume: true)) {
      //   // 泛型arg
      //   super_class_type_args = _parseType();
      //   match(HTLexicon.angleRight);
      // }
    } else {
      bytesBuilder.addByte(0); // bool: has super class
    }

    // TODO: deal with implements and mixins

    if (curTok.type == HTLexicon.curlyLeft) {
      bytesBuilder.addByte(1); // bool: has body
      final classDefinition = _parseBlockStmt(
          id: id, sourceType: SourceType.klass, createNamespace: false);

      bytesBuilder.add(classDefinition);
      bytesBuilder.addByte(HTOpCode.endOfExec);
    } else {
      bytesBuilder.addByte(0); // bool: has body
    }

    _curClass = savedClass;

    // _curBlock.classDecls[id] = bytesBuilder.toBytes();

    return bytesBuilder.toBytes();
  }

  Uint8List _parseEnumDeclStmt({bool isExternal = false}) {
    advance(1);
    final bytesBuilder = BytesBuilder();
    final id = match(SemanticType.identifier).lexeme;
    bytesBuilder.addByte(HTOpCode.enumDecl);
    bytesBuilder.add(_shortUtf8String(id));

    bytesBuilder.addByte(isExternal ? 1 : 0);

    // if (_curBlock.contains(id)) {
    //   throw HTError.definedParser(id);
    // }

    var enumerations = <String>[];
    if (expect([HTLexicon.curlyLeft], consume: true)) {
      while (curTok.type != HTLexicon.curlyRight &&
          curTok.type != HTLexicon.endOfFile) {
        enumerations.add(match(SemanticType.identifier).lexeme);
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

    // _curBlock.enumDecls[id] = bytesBuilder.toBytes();

    return bytesBuilder.toBytes();
  }
}
