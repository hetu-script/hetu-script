import 'dart:typed_data';
import 'dart:convert';

import '../source/source_provider.dart';
import '../error/error_handler.dart';
import '../ast/ast.dart';
import '../ast/ast_compilation.dart';
import 'const_table.dart';
// import '../declaration/class/class_declaration.dart';
// import '../declaration/function/function_declaration.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import 'opcode.dart';

// void main() {
//   var bytes = utf8.encode("foobar"); // data being hashed

//   var digest = sha1.convert(bytes);

//   print("Digest as bytes: ${digest.bytes}");
//   print("Digest as hex string: $digest");
// }

class HTRegIdx {
  static const value = 0;
  static const symbol = 1;
  static const leftValue = 2;
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

/// The information of snippet need goto
mixin GotoInfo {
  /// The instructor pointer of the definition's bytecode.
  late final int? definitionIp;
  late final int? definitionLine;
  late final int? definitionColumn;
}

abstract class CompilerConfig {
  bool get lineInfo;
}

class CompilerConfigImpl implements CompilerConfig {
  @override
  final bool lineInfo;

  const CompilerConfigImpl({this.lineInfo = true});
}

class HTCompiler implements AbstractAstVisitor<Uint8List> {
  /// Hetu script bytecode's bytecode signature
  static const hetuSignatureData = [8, 5, 20, 21];

  /// The version of the compiled bytecode,
  /// used to determine compatibility.
  static const hetuVersionData = [0, 1, 0, 0];

  HTErrorHandler errorHandler;
  HTSourceProvider sourceProvider;
  CompilerConfig config;

  final _curConstTable = ConstTable();

  int _curLine = 0;
  int _curColumn = 0;
  int get curLine => _curLine;
  int get curColumn => _curColumn;

  late String _curModuleFullName;
  String get curModuleFullName => _curModuleFullName;

  late String _curLibraryName;
  String get curLibraryName => _curLibraryName;

  // HTClassDeclaration? _curClass;
  // HTFunctionDeclaration? _curFunc;

  final List<Map<String, String>> _markedSymbolsList = [];

  HTCompiler(
      {this.config = const CompilerConfigImpl(),
      HTErrorHandler? errorHandler,
      HTSourceProvider? sourceProvider})
      : errorHandler = errorHandler ?? DefaultErrorHandler(),
        sourceProvider = sourceProvider ?? DefaultSourceProvider();

  Uint8List compile(HTAstCompilation compilation, String libraryName) {
    _curLibraryName = libraryName;

    final mainBytesBuilder = BytesBuilder();
    // 河图字节码标记
    mainBytesBuilder.addByte(HTOpCode.signature);
    mainBytesBuilder.add(hetuSignatureData);
    // 版本号
    mainBytesBuilder.addByte(HTOpCode.version);
    mainBytesBuilder.add(hetuVersionData);

    final bytesBuilder = BytesBuilder();
    for (final module in compilation.modules.values) {
      _curModuleFullName = module.fullName;
      if (module.hasOwnNamespace) {
        bytesBuilder.addByte(HTOpCode.module);
        bytesBuilder.add(_shortUtf8String(_curModuleFullName));
      }
      for (final node in module.nodes) {
        final bytes = visitAstNode(node);
        bytesBuilder.add(bytes);
      }
      bytesBuilder.addByte(HTOpCode.endOfModule);
    }
    final code = bytesBuilder.toBytes();

    // 添加常量表
    mainBytesBuilder.addByte(HTOpCode.constTable);
    mainBytesBuilder.add(_uint16(_curConstTable.intTable.length));
    for (final value in _curConstTable.intTable) {
      mainBytesBuilder.add(_int64(value));
    }
    mainBytesBuilder.add(_uint16(_curConstTable.floatTable.length));
    for (final value in _curConstTable.floatTable) {
      mainBytesBuilder.add(_float64(value));
    }
    mainBytesBuilder.add(_uint16(_curConstTable.stringTable.length));
    for (final value in _curConstTable.stringTable) {
      mainBytesBuilder.add(_utf8String(value));
    }

    mainBytesBuilder.add(code);

    return mainBytesBuilder.toBytes();
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

  Uint8List _lineInfo(int line, int column) {
    _curLine = line;
    _curColumn = column;
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.lineInfo);
    bytesBuilder.add(_uint16(line));
    bytesBuilder.add(_uint16(column));
    return bytesBuilder.toBytes();
  }

  Uint8List _localConst(int constIndex, int type, int line, int column) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(type);
    bytesBuilder.add(_uint16(constIndex));
    return bytesBuilder.toBytes();
  }

  Uint8List _parseCallArguments(
      List<AstNode> posArgsNodes, Map<String, AstNode> namedArgsNodes,
      {bool hasLength = false}) {
    // 这里不判断左括号，已经跳过了
    final bytesBuilder = BytesBuilder();
    final positionalArgs = <Uint8List>[];
    final namedArgs = <String, Uint8List>{};
    for (final ast in posArgsNodes) {
      final bytes = visitAstNode(ast, endOfExec: true);
      positionalArgs.add(bytes);
    }
    for (final name in namedArgs.keys) {
      final bytes = visitAstNode(namedArgsNodes[name]!, endOfExec: true);
      namedArgs[name] = bytes;
    }
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

  Uint8List _assembleLocalConstInt(int value, int line, int column,
      {bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    final index = _curConstTable.addInt(value);
    final constExpr =
        _localConst(index, HTValueTypeCode.constInt, line, column);
    bytesBuilder.add(constExpr);
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleLocalSymbol(String id,
      {bool isLocal = true, bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.symbol);
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(isLocal ? 1 : 0); // bool: isLocal
    bytesBuilder.addByte(0); // bool: has type args
    if (endOfExec) bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleMemberGet(Uint8List object, String key,
      {bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    // bytesBuilder.addByte(HTOpCode.leftValue); // save object symbol name in reg
    final keySymbol = _assembleLocalSymbol(key, isLocal: false);
    bytesBuilder.add(keySymbol);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixKey);
    bytesBuilder.addByte(HTOpCode.memberGet);
    if (endOfExec) bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleVarDeclStmt(String id, int line, int column,
      {Uint8List? initializer,
      bool isMutable = true,
      bool lateInitialize = false}) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.varDecl);
    bytesBuilder.add(_shortUtf8String(id));
    bytesBuilder.addByte(0); // bool: hasClassId
    bytesBuilder.addByte(0); // bool: isExternal
    bytesBuilder.addByte(0); // bool: isStatic
    bytesBuilder.addByte(isMutable ? 1 : 0); // bool: isMutable
    bytesBuilder.addByte(0); // bool: isConst
    bytesBuilder.addByte(0); // bool: isExported
    bytesBuilder.addByte(lateInitialize ? 1 : 0); // bool: lateInitialize
    bytesBuilder.addByte(0); // bool: has type decl
    if (initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      if (lateInitialize) {
        bytesBuilder.add(_uint16(line));
        bytesBuilder.add(_uint16(column));
        bytesBuilder.add(_uint16(initializer.length));
      }
      bytesBuilder.add(initializer);
    } else {
      bytesBuilder.addByte(0);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List visitAstNode(AstNode node, {bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    final bytes = node.accept(this);
    bytesBuilder.add(bytes);
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitEmptyExpr(EmptyExpr expr) {
    return Uint8List(0);
  }

  @override
  Uint8List visitCommentExpr(CommentExpr expr) {
    return Uint8List(0);
  }

  @override
  Uint8List visitNullExpr(NullExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
      bytesBuilder.add(_lineInfo(expr.line, expr.column));
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.NULL);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBooleanExpr(BooleanExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
      bytesBuilder.add(_lineInfo(expr.line, expr.column));
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.boolean);
    bytesBuilder.addByte(expr.value ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitConstIntExpr(ConstIntExpr expr) {
    final index = _curConstTable.addInt(expr.value);
    return _localConst(index, HTValueTypeCode.constInt, expr.line, expr.column);
  }

  @override
  Uint8List visitConstFloatExpr(ConstFloatExpr expr) {
    final index = _curConstTable.addFloat(expr.value);
    return _localConst(
        index, HTValueTypeCode.constFloat, expr.line, expr.column);
  }

  @override
  Uint8List visitConstStringExpr(ConstStringExpr expr) {
    var literal = expr.value;
    HTLexicon.stringReplaces.forEach((key, value) {
      literal = expr.value.replaceAll(key, value);
    });
    final index = _curConstTable.addString(literal);
    return _localConst(
        index, HTValueTypeCode.constString, expr.line, expr.column);
  }

  @override
  Uint8List visitStringInterpolationExpr(StringInterpolationExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.stringInterpolation);
    var literal = expr.value;
    HTLexicon.stringReplaces.forEach((key, value) {
      literal = expr.value.replaceAll(key, value);
    });
    bytesBuilder.add(_utf8String(literal));
    bytesBuilder.addByte(expr.interpolation.length);
    for (final node in expr.interpolation) {
      final bytes = visitAstNode(node, endOfExec: true);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitListExpr(ListExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
      bytesBuilder.add(_lineInfo(expr.line, expr.column));
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.list);
    bytesBuilder.add(_uint16(expr.list.length));
    for (final item in expr.list) {
      final bytes = visitAstNode(item, endOfExec: true);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitMapExpr(MapExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (config.lineInfo) {
      bytesBuilder.add(_lineInfo(expr.line, expr.column));
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.map);
    bytesBuilder.add(_uint16(expr.map.length));
    for (final ast in expr.map.keys) {
      final key = visitAstNode(ast, endOfExec: true);
      bytesBuilder.add(key);
      final value = visitAstNode(expr.map[ast]!, endOfExec: true);
      bytesBuilder.add(value);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitGroupExpr(GroupExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.group);
    final innerExpr = visitAstNode(expr.inner, endOfExec: true);
    bytesBuilder.add(innerExpr);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitSymbolExpr(SymbolExpr expr) {
    final bytesBuilder = BytesBuilder();
    var symbolId = expr.id;
    if (_markedSymbolsList.isNotEmpty) {
      final map = _markedSymbolsList.last;
      for (final symbol in map.keys) {
        if (symbolId == symbol) {
          symbolId = map[symbol]!;
          break;
        }
      }
    }
    if (config.lineInfo) {
      bytesBuilder.add(_lineInfo(expr.line, expr.column));
    }
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.symbol);
    bytesBuilder.add(_shortUtf8String(symbolId));
    bytesBuilder.addByte(expr.isLocal ? 1 : 0);
    if (expr.typeArgs.isNotEmpty) {
      bytesBuilder.addByte(1);
      bytesBuilder.addByte(expr.typeArgs.length); // bool: has type args
      for (final ast in expr.typeArgs) {
        final bytes = visitTypeExpr(ast);
        bytesBuilder.add(bytes);
      }
    } else {
      bytesBuilder.addByte(0); // bool: has type args
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitTypeExpr(TypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.isLocal) {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.type);
    }
    bytesBuilder.addByte(TypeType.normal.index); // enum: type type
    bytesBuilder.add(_shortUtf8String(expr.id));
    bytesBuilder.addByte(expr.arguments.length); // max 255
    for (final expr in expr.arguments) {
      final typeArg = visitTypeExpr(expr);
      bytesBuilder.add(typeArg);
    }
    bytesBuilder.addByte(expr.isNullable ? 1 : 0); // bool isNullable
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitParamTypeExpr(ParamTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_shortUtf8String(expr.declType.id));
    bytesBuilder.addByte(expr.declType.arguments.length); // max 255
    for (final expr in expr.declType.arguments) {
      final typeArg = visitTypeExpr(expr);
      bytesBuilder.add(typeArg);
    }
    bytesBuilder.addByte(expr.declType.isNullable ? 1 : 0); // bool isNullable
    bytesBuilder.addByte(expr.isOptional ? 1 : 0);
    if (expr.id != null) {
      bytesBuilder.addByte(1); // bool: isNamed
      bytesBuilder.add(_shortUtf8String(expr.id!));
    } else {
      bytesBuilder.addByte(0); // bool: isNamed
    }
    bytesBuilder.addByte(expr.isVariadic ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitFunctionTypeExpr(FuncTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.isLocal) {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.type);
    }
    bytesBuilder.addByte(TypeType.function.index); // enum: type type
    bytesBuilder
        .addByte(expr.paramTypes.length); // uint8: length of param types
    for (final param in expr.paramTypes) {
      final bytes = visitParamTypeExpr(param);
      bytesBuilder.add(bytes);
    }
    final returnType = visitTypeExpr(expr.returnType);
    bytesBuilder.add(returnType);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    final bytesBuilder = BytesBuilder();
    final value = visitAstNode(expr.value);
    switch (expr.op) {
      case HTLexicon.negative:
        bytesBuilder.add(value);
        bytesBuilder.addByte(HTOpCode.negative);
        break;
      case HTLexicon.logicalNot:
        bytesBuilder.add(value);
        bytesBuilder.addByte(HTOpCode.logicalNot);
        break;
      case HTLexicon.preIncrement:
        final constOne =
            ConstIntExpr(1, expr.line, expr.column, source: expr.source);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final add = BinaryExpr(memberExpr, HTLexicon.add, constOne,
              memberExpr.line, memberExpr.column,
              source: expr.source);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, add,
              memberExpr.line, memberExpr.column,
              source: expr.source);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final add = BinaryExpr(
              subExpr, HTLexicon.add, constOne, subExpr.line, subExpr.column,
              source: expr.source);
          value = SubAssignExpr(
              subExpr.array, subExpr.key, add, subExpr.line, subExpr.column,
              source: expr.source);
        } else {
          final add = BinaryExpr(expr.value, HTLexicon.add, constOne,
              expr.value.line, expr.value.column,
              source: expr.source);
          value = BinaryExpr(expr.value, HTLexicon.assign, add, expr.value.line,
              expr.value.column,
              source: expr.source);
        }
        final group =
            GroupExpr(value, value.line, value.column, source: expr.source);
        final bytes = visitAstNode(group);
        bytesBuilder.add(bytes);
        break;
      case HTLexicon.preDecrement:
        final constOne =
            ConstIntExpr(1, expr.line, expr.column, source: expr.source);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final subtract = BinaryExpr(memberExpr, HTLexicon.subtract, constOne,
              memberExpr.line, memberExpr.column,
              source: expr.source);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, subtract,
              memberExpr.line, memberExpr.column,
              source: expr.source);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final subtract = BinaryExpr(subExpr, HTLexicon.subtract, constOne,
              subExpr.line, subExpr.column,
              source: expr.source);
          value = SubAssignExpr(subExpr.array, subExpr.key, subtract,
              subExpr.line, subExpr.column,
              source: expr.source);
        } else {
          final subtract = BinaryExpr(expr.value, HTLexicon.subtract, constOne,
              expr.value.line, expr.value.column,
              source: expr.source);
          value = BinaryExpr(expr.value, HTLexicon.assign, subtract,
              expr.value.line, expr.value.column,
              source: expr.source);
        }
        final group =
            GroupExpr(value, value.line, value.column, source: expr.source);
        final bytes = visitAstNode(group);
        bytesBuilder.add(bytes);
        break;
      case HTLexicon.TYPEOF:
        bytesBuilder.add(value);
        bytesBuilder.addByte(HTOpCode.typeOf);
        break;
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBinaryExpr(BinaryExpr expr) {
    final bytesBuilder = BytesBuilder();
    final left = visitAstNode(expr.left);
    final right = visitAstNode(expr.right);
    switch (expr.op) {
      case HTLexicon.assign:
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.assign);
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.assign);
        break;
      case HTLexicon.assignAdd:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.addLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.add);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.assign);
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.assign);
        break;
      case HTLexicon.assignSubtract:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.addLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.subtract);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.assign);
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.assign);
        break;
      case HTLexicon.assignMultiply:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.multiplyLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.multiply);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.assign);
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.assign);
        break;
      case HTLexicon.assignDevide:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.multiplyLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.devide);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.assign);
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.assign);
        break;
      case HTLexicon.logicalOr:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.orLeft);
        bytesBuilder.addByte(HTOpCode.logicalOr);
        bytesBuilder.add(_uint16(right.length + 1)); // length of right value
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.endOfExec);
        break;
      case HTLexicon.logicalAnd:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.andLeft);
        bytesBuilder.addByte(HTOpCode.logicalAnd);
        bytesBuilder.add(_uint16(right.length + 1)); // length of right value
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.endOfExec);
        break;
      case HTLexicon.equal:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.equalLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.equal);
        break;
      case HTLexicon.notEqual:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.equalLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.notEqual);
        break;
      case HTLexicon.lesser:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.lesser);
        break;
      case HTLexicon.greater:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.greater);
        break;
      case HTLexicon.lesserOrEqual:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.lesserOrEqual);
        break;
      case HTLexicon.greaterOrEqual:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.greaterOrEqual);
        break;
      case HTLexicon.AS:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        final right = visitAstNode(expr.right);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.typeAs);
        break;
      case HTLexicon.IS:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        final right = visitAstNode(expr.right);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.typeIs);
        break;
      case HTLexicon.ISNOT:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        final right = visitAstNode(expr.right);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.typeIsNot);
        break;
      case HTLexicon.add:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.addLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.add);
        break;
      case HTLexicon.subtract:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.addLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.subtract);
        break;
      case HTLexicon.multiply:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.multiplyLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.multiply);
        break;
      case HTLexicon.devide:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.multiplyLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.devide);
        break;
      case HTLexicon.modulo:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.multiplyLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.modulo);
        break;
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitTernaryExpr(TernaryExpr expr) {
    final bytesBuilder = BytesBuilder();
    final condition = visitAstNode(expr.condition);
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.ifStmt);
    final thenBranch = visitAstNode(expr.thenBranch);
    final elseBranch = visitAstNode(expr.elseBranch);
    final thenBranchLength = thenBranch.length + 3;
    final elseBranchLength = elseBranch.length;
    bytesBuilder.add(_uint16(thenBranchLength));
    bytesBuilder.add(thenBranch);
    bytesBuilder.addByte(HTOpCode.skip); // 执行完 then 之后，直接跳过 else block
    bytesBuilder.add(_int16(elseBranchLength));
    bytesBuilder.add(elseBranch);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    final bytesBuilder = BytesBuilder();
    final value = visitAstNode(expr.value);
    bytesBuilder.add(value);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    switch (expr.op) {
      case HTLexicon.postIncrement:
        final constOne =
            ConstIntExpr(1, expr.line, expr.column, source: expr.source);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final add = BinaryExpr(memberExpr, HTLexicon.add, constOne,
              memberExpr.line, memberExpr.column,
              source: expr.source);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, add,
              memberExpr.line, memberExpr.column,
              source: expr.source);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final add = BinaryExpr(
              subExpr, HTLexicon.add, constOne, subExpr.line, subExpr.column,
              source: expr.source);
          value = SubAssignExpr(
              subExpr.array, subExpr.key, add, subExpr.line, subExpr.column,
              source: expr.source);
        } else {
          final add = BinaryExpr(expr.value, HTLexicon.add, constOne,
              expr.value.line, expr.value.column,
              source: expr.source);
          value = BinaryExpr(expr.value, HTLexicon.assign, add, expr.value.line,
              expr.value.column,
              source: expr.source);
        }
        final group =
            GroupExpr(value, value.line, value.column, source: expr.source);
        final subtract = BinaryExpr(
            group, HTLexicon.subtract, constOne, group.line, group.column,
            source: expr.source);
        final group2 = GroupExpr(subtract, subtract.line, subtract.column,
            source: expr.source);
        final bytes = visitAstNode(group2);
        bytesBuilder.add(bytes);
        break;
      case HTLexicon.postDecrement:
        final constOne =
            ConstIntExpr(1, expr.line, expr.column, source: expr.source);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final subtract = BinaryExpr(memberExpr, HTLexicon.subtract, constOne,
              memberExpr.line, memberExpr.column,
              source: expr.source);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, subtract,
              memberExpr.line, memberExpr.column,
              source: expr.source);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final subtract = BinaryExpr(subExpr, HTLexicon.subtract, constOne,
              subExpr.line, subExpr.column,
              source: expr.source);
          value = SubAssignExpr(subExpr.array, subExpr.key, subtract,
              subExpr.line, subExpr.column,
              source: expr.source);
        } else {
          final subtract = BinaryExpr(expr.value, HTLexicon.subtract, constOne,
              expr.value.line, expr.value.column,
              source: expr.source);
          value = BinaryExpr(expr.value, HTLexicon.assign, subtract,
              expr.value.line, expr.value.column,
              source: expr.source);
        }
        final group =
            GroupExpr(value, value.line, value.column, source: expr.source);
        final add = BinaryExpr(
            group, HTLexicon.add, constOne, group.line, group.column,
            source: expr.source);
        final group2 =
            GroupExpr(add, add.line, add.column, source: expr.source);
        final bytes = visitAstNode(group2);
        bytesBuilder.add(bytes);
        break;
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitMemberExpr(MemberExpr expr) {
    final bytesBuilder = BytesBuilder();
    final object = visitAstNode(expr.object);
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    final key = visitSymbolExpr(expr.key);
    bytesBuilder.add(key);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixKey);
    bytesBuilder.addByte(HTOpCode.memberGet);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitMemberAssignExpr(MemberAssignExpr expr) {
    final bytesBuilder = BytesBuilder();
    final object = visitAstNode(expr.object);
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    final key = visitSymbolExpr(expr.key);
    bytesBuilder.add(key);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixKey);
    final value = visitAstNode(expr.value);
    bytesBuilder.add(value);
    bytesBuilder.addByte(HTOpCode.memberSet);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitSubExpr(SubExpr expr) {
    final bytesBuilder = BytesBuilder();
    final array = visitAstNode(expr.array);
    bytesBuilder.add(array);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    final key = visitAstNode(expr.key, endOfExec: true);
    bytesBuilder.addByte(HTOpCode.subGet);
    // sub get key is after opcode
    // it has to be exec with 'move reg index'
    bytesBuilder.add(key);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitSubAssignExpr(SubAssignExpr expr) {
    final bytesBuilder = BytesBuilder();
    final array = visitAstNode(expr.array);
    bytesBuilder.add(array);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder.addByte(HTOpCode.subSet);
    // sub get key is after opcode
    // it has to be exec with 'move reg index'
    final key = visitAstNode(expr.key, endOfExec: true);
    bytesBuilder.add(key);
    final value = visitAstNode(expr.value, endOfExec: true);
    bytesBuilder.add(value);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitCallExpr(CallExpr expr) {
    final bytesBuilder = BytesBuilder();
    final callee = visitAstNode(expr.callee);
    bytesBuilder.add(callee);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder.addByte(HTOpCode.call);
    final argBytes = _parseCallArguments(expr.positionalArgs, expr.namedArgs);
    bytesBuilder.add(argBytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitExprStmt(ExprStmt stmt) {
    final bytesBuilder = BytesBuilder();
    if (stmt.expr != null) {
      final bytes = visitAstNode(stmt.expr!);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBlockStmt(BlockStmt block) {
    final bytesBuilder = BytesBuilder();
    if (block.hasOwnNamespace) {
      bytesBuilder.addByte(HTOpCode.block);
      if (block.id != null) {
        bytesBuilder.add(_shortUtf8String(block.id!));
      } else {
        bytesBuilder.add(_shortUtf8String(SemanticNames.anonymousBlock));
      }
    }
    for (final stmt in block.statements) {
      final bytes = visitAstNode(stmt);
      bytesBuilder.add(bytes);
    }
    if (block.hasOwnNamespace) {
      bytesBuilder.addByte(HTOpCode.endOfBlock);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitLibraryStmt(LibraryStmt stmt) {
    return Uint8List(0);
  }

  @override
  Uint8List visitImportStmt(ImportStmt stmt) {
    return Uint8List(0);
  }

  @override
  Uint8List visitReturnStmt(ReturnStmt stmt) {
    final bytesBuilder = BytesBuilder();
    if (stmt.value != null) {
      final bytes = visitAstNode(stmt.value!);
      bytesBuilder.add(bytes);
    }
    bytesBuilder.addByte(HTOpCode.endOfFunc);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitIfStmt(IfStmt stmt) {
    final bytesBuilder = BytesBuilder();
    final condition = visitAstNode(stmt.condition);
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.ifStmt);
    final thenBranch = visitBlockStmt(stmt.thenBranch);
    Uint8List? elseBranch;
    if (stmt.elseBranch != null) {
      elseBranch = visitBlockStmt(stmt.elseBranch!);
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

  @override
  Uint8List visitWhileStmt(WhileStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.loopPoint);
    final condition = visitAstNode(stmt.condition);
    final loop = visitAstNode(stmt.loop);
    final loopLength = condition.length + loop.length + 4;
    bytesBuilder.add(_uint16(0)); // while loop continue ip
    bytesBuilder.add(_uint16(loopLength)); // while loop break ip
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.whileStmt);
    bytesBuilder.add(loop);
    bytesBuilder.addByte(HTOpCode.skip);
    bytesBuilder.add(_int16(-loopLength));
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitDoStmt(DoStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.loopPoint);
    final loop = visitAstNode(stmt.loop);
    Uint8List? condition;
    if (stmt.condition != null) {
      condition = visitAstNode(stmt.condition!);
    }
    final loopLength = loop.length + (condition?.length ?? 0) + 1;
    bytesBuilder.add(_uint16(0)); // while loop continue ip
    bytesBuilder.add(_uint16(loopLength)); // while loop break ip
    bytesBuilder.add(loop);
    if (condition != null) {
      bytesBuilder.add(condition);
      bytesBuilder.addByte(HTOpCode.doStmt);
      bytesBuilder.addByte(1); // bool: has condition
    } else {
      bytesBuilder.addByte(HTOpCode.doStmt);
      bytesBuilder.addByte(0); // bool: has condition
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitForStmt(ForStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.block);
    bytesBuilder.add(_shortUtf8String(SemanticNames.forStmtInit));
    late Uint8List condition;
    Uint8List? increment;
    AstNode? capturedDecl;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (stmt.declaration != null) {
      // TODO: 如果有多个变量同时声明?
      final userDecl = stmt.declaration as VarDeclStmt;
      final markedId = '${SemanticNames.internalMarker}${userDecl.id}';
      newSymbolMap[userDecl.id] = markedId;
      Uint8List? initializer;
      if (userDecl.initializer != null) {
        initializer = visitAstNode(userDecl.initializer!, endOfExec: true);
      }
      final initDecl = _assembleVarDeclStmt(
          markedId, userDecl.line, userDecl.column,
          initializer: initializer, isMutable: userDecl.isMutable);
      bytesBuilder.add(initDecl);
      // 这里是为了实现将变量声明移动到for循环语句块内部的效果
      final capturedInit = SymbolExpr(markedId, userDecl.line, userDecl.column,
          source: stmt.source);
      capturedDecl = VarDeclStmt(userDecl.id, userDecl.line, userDecl.column,
          source: stmt.source, initializer: capturedInit);
    }
    if (stmt.condition != null) {
      condition = visitAstNode(stmt.condition!);
    } else {
      final boolExpr =
          BooleanExpr(true, stmt.line, stmt.column, source: stmt.source);
      condition = visitBooleanExpr(boolExpr);
    }
    if (stmt.increment != null) {
      increment = visitAstNode(stmt.increment!);
    }
    if (capturedDecl != null) {
      stmt.loop.statements.insert(0, capturedDecl);
    }
    final loop = visitBlockStmt(stmt.loop);
    final continueLength = condition.length + loop.length + 1;
    final breakLength = continueLength + (increment?.length ?? 0) + 3;
    bytesBuilder.addByte(HTOpCode.loopPoint);
    bytesBuilder.add(_uint16(continueLength));
    bytesBuilder.add(_uint16(breakLength));
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.whileStmt);
    bytesBuilder.add(loop);
    if (increment != null) {
      bytesBuilder.add(increment);
    }
    bytesBuilder.addByte(HTOpCode.skip);
    bytesBuilder.add(_int16(-breakLength));
    _markedSymbolsList.removeLast();
    bytesBuilder.addByte(HTOpCode.endOfBlock);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitForInStmt(ForInStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.block);
    bytesBuilder.add(_shortUtf8String(SemanticNames.forStmtInit));
    Uint8List? condition;
    Uint8List? increment;
    // declare the increment variable
    final increId = SemanticNames.increment;
    final increInit = _assembleLocalConstInt(
        0, stmt.declaration.line, stmt.declaration.column,
        endOfExec: true);
    final increDecl = _assembleVarDeclStmt(
        increId, stmt.declaration.line, stmt.declaration.column,
        initializer: increInit);
    bytesBuilder.add(increDecl);

    final collectionId = SemanticNames.iterable;
    final collectionInit = visitAstNode(stmt.collection, endOfExec: true);
    final collectionDecl = _assembleVarDeclStmt(
        collectionId, stmt.collection.line, stmt.collection.column,
        initializer: collectionInit);
    bytesBuilder.add(collectionDecl);
    final collectionSymbol = SymbolExpr(
        collectionId, stmt.collection.line, stmt.collection.column,
        source: stmt.source);
    final collectionSymbolBytes = visitSymbolExpr(collectionSymbol);

    // assemble the condition expression
    final conditionBytesBuilder = BytesBuilder();
    final isNotEmptyExpr =
        _assembleMemberGet(collectionSymbolBytes, HTLexicon.isNotEmpty);
    conditionBytesBuilder.add(isNotEmptyExpr);
    conditionBytesBuilder.addByte(HTOpCode.register);
    conditionBytesBuilder.addByte(HTRegIdx.andLeft);
    conditionBytesBuilder.addByte(HTOpCode.logicalAnd);
    final lesserLeftExpr = _assembleLocalSymbol(increId);
    final iterableLengthExpr =
        _assembleMemberGet(collectionSymbolBytes, HTLexicon.length);
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

    // assemble the initializer of the captured variable
    final capturedDeclInit = CallExpr(
        MemberExpr(
            stmt.collection,
            SymbolExpr(HTLexicon.elementAt, stmt.collection.line,
                stmt.collection.column,
                source: stmt.source, isLocal: false),
            stmt.collection.line,
            stmt.collection.column,
            source: stmt.source),
        [
          SymbolExpr(increId, stmt.collection.line, stmt.collection.column,
              source: stmt.source)
        ],
        const {},
        stmt.collection.line,
        stmt.collection.column,
        source: stmt.source);
    // declared the captured variable
    final capturedDecl = VarDeclStmt(
        stmt.declaration.id, stmt.declaration.line, stmt.declaration.column,
        source: stmt.source,
        initializer: capturedDeclInit,
        isMutable: stmt.declaration.isMutable);
    final incrementBytesBuilder = BytesBuilder();
    final preIncreExpr = _assembleLocalSymbol(increId);
    incrementBytesBuilder.addByte(HTOpCode.local);
    incrementBytesBuilder.addByte(HTValueTypeCode.group);
    incrementBytesBuilder.add(preIncreExpr);
    incrementBytesBuilder.addByte(HTOpCode.register);
    incrementBytesBuilder.addByte(HTRegIdx.addLeft);
    final valueOne =
        _assembleLocalConstInt(1, capturedDecl.line, capturedDecl.column);
    incrementBytesBuilder.add(valueOne);
    incrementBytesBuilder.addByte(HTOpCode.add);
    incrementBytesBuilder.addByte(HTOpCode.register);
    incrementBytesBuilder.addByte(HTRegIdx.assign);
    incrementBytesBuilder.add(preIncreExpr);
    incrementBytesBuilder.addByte(HTOpCode.assign);
    incrementBytesBuilder.addByte(HTOpCode.endOfExec);
    increment = incrementBytesBuilder.toBytes();

    bytesBuilder.addByte(HTOpCode.loopPoint);
    stmt.loop.statements.insert(0, capturedDecl);
    final loop = visitBlockStmt(stmt.loop);
    final continueLength = condition.length + loop.length + 1;
    final breakLength = continueLength + increment.length + 3;
    bytesBuilder.add(_uint16(continueLength));
    bytesBuilder.add(_uint16(breakLength));
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.whileStmt);
    bytesBuilder.add(loop);
    bytesBuilder.add(increment);
    bytesBuilder.addByte(HTOpCode.skip);
    bytesBuilder.add(_int16(-breakLength));
    bytesBuilder.addByte(HTOpCode.endOfBlock);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitWhenStmt(WhenStmt stmt) {
    final bytesBuilder = BytesBuilder();
    Uint8List? condition;
    if (stmt.condition != null) {
      condition = visitAstNode(stmt.condition!);
    }
    final cases = <Uint8List>[];
    final branches = <Uint8List>[];
    Uint8List? elseBranch;
    if (stmt.elseBranch != null) {
      elseBranch = visitBlockStmt(stmt.elseBranch!);
    }
    for (final ast in stmt.cases.keys) {
      final caseBytes = visitAstNode(ast, endOfExec: true);
      cases.add(caseBytes);
      final branchBytes = visitAstNode(stmt.cases[ast]!);
      branches.add(branchBytes);
    }
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

  @override
  Uint8List visitBreakStmt(BreakStmt stmt) {
    return Uint8List.fromList([HTOpCode.breakLoop]);
  }

  @override
  Uint8List visitContinueStmt(ContinueStmt stmt) {
    return Uint8List.fromList([HTOpCode.continueLoop]);
  }

  @override
  Uint8List visitTypeAliasStmt(TypeAliasDeclStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.typeAliasDecl);
    bytesBuilder.add(_shortUtf8String(stmt.id));
    if (stmt.classId != null) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_shortUtf8String(stmt.classId!));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    bytesBuilder.addByte(stmt.isExported ? 1 : 0);
    // do not use visitTypeExpr here because the value could be a function type
    final bytes = visitAstNode(stmt.value);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitVarDeclStmt(VarDeclStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.varDecl);
    bytesBuilder.add(_shortUtf8String(stmt.id));
    if (stmt.classId != null) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_shortUtf8String(stmt.classId!));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
    bytesBuilder.addByte(stmt.isStatic ? 1 : 0);
    bytesBuilder.addByte(stmt.isMutable ? 1 : 0);
    bytesBuilder.addByte(stmt.isConst ? 1 : 0);
    bytesBuilder.addByte(stmt.isExported ? 1 : 0);
    bytesBuilder.addByte(stmt.lateInitialize ? 1 : 0);
    Uint8List? typeDecl;
    if (stmt.declType != null) {
      typeDecl = visitAstNode(stmt.declType!);
    }
    if (typeDecl != null) {
      bytesBuilder.addByte(1); // bool: has type decl
      bytesBuilder.add(typeDecl);
    } else {
      bytesBuilder.addByte(0); // bool: has type decl
    }
    Uint8List? initializer;
    if (stmt.initializer != null) {
      initializer = visitAstNode(stmt.initializer!, endOfExec: true);
    }
    if (initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      if (stmt.lateInitialize) {
        bytesBuilder.add(_uint16(stmt.initializer!.line));
        bytesBuilder.add(_uint16(stmt.initializer!.column));
        bytesBuilder.add(_uint16(initializer.length));
      }
      bytesBuilder.add(initializer);
    } else {
      bytesBuilder.addByte(0); // bool: has initializer
    }
    bytesBuilder.addByte(HTOpCode.endOfStmt);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitParamDeclStmt(ParamDeclExpr stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_shortUtf8String(stmt.id));
    bytesBuilder.addByte(stmt.isOptional ? 1 : 0);
    bytesBuilder.addByte(stmt.isNamed ? 1 : 0);
    bytesBuilder.addByte(stmt.isVariadic ? 1 : 0);
    Uint8List? typeDecl;
    if (stmt.declType != null) {
      typeDecl = visitAstNode(stmt.declType!);
    }
    if (typeDecl != null) {
      bytesBuilder.addByte(1); // bool: has type decl
      bytesBuilder.add(typeDecl);
    } else {
      bytesBuilder.addByte(0); // bool: has type decl
    }
    Uint8List? initializer;
    if (stmt.initializer != null) {
      initializer = visitAstNode(stmt.initializer!, endOfExec: true);
    }
    if (initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      bytesBuilder.add(_uint16(stmt.initializer!.line));
      bytesBuilder.add(_uint16(stmt.initializer!.column));
      bytesBuilder.add(_uint16(initializer.length));
      bytesBuilder.add(initializer);
    } else {
      bytesBuilder.addByte(0); // bool: has initializer
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitReferConstructorExpr(ReferConstructorExpr stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(stmt.isSuper ? 1 : 0);
    if (stmt.key != null) {
      bytesBuilder.addByte(1); // bool: has constructor name
      bytesBuilder.add(_shortUtf8String(stmt.key!));
    } else {
      bytesBuilder.addByte(0); // bool: has constructor name
    }
    final callArgs = _parseCallArguments(stmt.positionalArgs, stmt.namedArgs,
        hasLength: true);
    bytesBuilder.add(callArgs);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitFuncDeclStmt(FuncDeclExpr stmt) {
    // final savedCurFunc = _curFunc;
    final bytesBuilder = BytesBuilder();
    // TODO: 泛型param
    if (stmt.category != FunctionCategory.literal) {
      bytesBuilder.addByte(HTOpCode.funcDecl);
      // funcBytesBuilder.addByte(HTOpCode.funcDecl);
      bytesBuilder.add(_shortUtf8String(stmt.internalName));
      if (stmt.id != null) {
        bytesBuilder.addByte(1); // bool: hasId
        bytesBuilder.add(_shortUtf8String(stmt.id!));
      } else {
        bytesBuilder.addByte(0); // bool: hasId
      }
      if (stmt.classId != null) {
        bytesBuilder.addByte(1); // bool: hasClassId
        bytesBuilder.add(_shortUtf8String(stmt.classId!));
      } else {
        bytesBuilder.addByte(0); // bool: hasClassId
      }
      if (stmt.externalTypeId != null) {
        bytesBuilder.addByte(1); // bool: hasExternalTypedef
        bytesBuilder.add(_shortUtf8String(stmt.externalTypeId!));
      } else {
        bytesBuilder.addByte(0); // bool: hasExternalTypedef
      }
      bytesBuilder.addByte(stmt.category.index);
      bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
      bytesBuilder.addByte(stmt.isStatic ? 1 : 0);
      bytesBuilder.addByte(stmt.isConst ? 1 : 0);
      bytesBuilder.addByte(stmt.isExported ? 1 : 0);
    } else {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.function);
      bytesBuilder.add(_shortUtf8String(stmt.internalName));
      if (stmt.externalTypeId != null) {
        bytesBuilder.addByte(1);
        bytesBuilder.add(_shortUtf8String(stmt.externalTypeId!));
      } else {
        bytesBuilder.addByte(0);
      }
    }
    bytesBuilder.addByte(stmt.hasParamDecls ? 1 : 0);
    bytesBuilder.addByte(stmt.isVariadic ? 1 : 0);
    bytesBuilder.addByte(stmt.minArity);
    bytesBuilder.addByte(stmt.maxArity);
    bytesBuilder.addByte(stmt.params.length); // max 255
    for (var param in stmt.params) {
      final bytes = visitParamDeclStmt(param);
      bytesBuilder.add(bytes);
    }
    if (stmt.category == FunctionCategory.constructor) {
      // referring to another constructor
      if (stmt.referConstructor != null) {
        bytesBuilder.addByte(1); // bool: hasRefCtor
        final bytes = visitReferConstructorExpr(stmt.referConstructor!);
        bytesBuilder.add(bytes);
      } else {
        bytesBuilder.addByte(0); // bool: hasRefCtor
      }
    }
    // definition body
    if (stmt.definition != null) {
      bytesBuilder.addByte(1); // bool: has definition
      bytesBuilder.add(_uint16(stmt.definition!.line));
      bytesBuilder.add(_uint16(stmt.definition!.column));
      final body = visitAstNode(stmt.definition!);
      bytesBuilder.add(_uint16(body.length + 1)); // definition bytes length
      bytesBuilder.add(body);
      bytesBuilder.addByte(HTOpCode.endOfFunc);
    } else {
      bytesBuilder.addByte(0); // bool: has no definition
    }
    // _curFunc = savedCurFunc;
    if (!stmt.isLiteral) {
      bytesBuilder.addByte(HTOpCode.endOfStmt);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitClassDeclStmt(ClassDeclStmt stmt) {
    // final savedClass = _curClass;
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.classDecl);
    bytesBuilder.add(_shortUtf8String(stmt.id));
    // TODO: 泛型param
    // _curClass = HTClassDeclaration(stmt.id, _curModuleFullName, _curLibraryName,
    //     isExternal: stmt.isExternal, isAbstract: stmt.isAbstract);
    bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
    bytesBuilder.addByte(stmt.isAbstract ? 1 : 0);
    bytesBuilder.addByte(stmt.isExported ? 1 : 0);
    Uint8List? superType;
    if (stmt.superType != null) {
      superType = visitTypeExpr(stmt.superType!);
      bytesBuilder.addByte(1); // bool: has super class
      bytesBuilder.add(superType);
    } else {
      bytesBuilder.addByte(0); // bool: has super class
    }
    // TODO: deal with implements and mixins
    if (stmt.definition != null) {
      bytesBuilder.addByte(1); // bool: hasDefinition
      final classDefinition = visitAstNode(stmt.definition!, endOfExec: true);
      bytesBuilder.add(classDefinition);
    } else {
      bytesBuilder.addByte(0); // bool: hasDefinition
    }
    bytesBuilder.addByte(HTOpCode.endOfStmt);
    // _curClass = savedClass;
    return bytesBuilder.toBytes();
  }

  // TODO: enum should compiled to abstract static class
  @override
  Uint8List visitEnumDeclStmt(EnumDeclStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.enumDecl);
    bytesBuilder.add(_shortUtf8String(stmt.id));
    bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
    bytesBuilder.addByte(stmt.isExported ? 1 : 0);
    bytesBuilder.add(_uint16(stmt.enumerations.length));
    for (final id in stmt.enumerations) {
      bytesBuilder.add(_shortUtf8String(id));
    }
    bytesBuilder.addByte(HTOpCode.endOfStmt);
    return bytesBuilder.toBytes();
  }
}
