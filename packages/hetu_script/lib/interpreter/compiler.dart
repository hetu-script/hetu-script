import 'dart:typed_data';
import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

import '../ast/ast.dart';
import '../value/const.dart';
import '../parser/parse_result_compilation.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
// import '../source/source.dart';
import '../shared/constants.dart';
import 'const_table.dart';
import '../parser/parse_result.dart';

class HTRegIdx {
  static const value = 0;
  static const identifier = 1;
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

// Execution jump point
mixin GotoInfo {
  late final String fileName;
  late final String moduleName;
  late final int? definitionIp;
  late final int? definitionLine;
  late final int? definitionColumn;
}

abstract class CompilerConfig {
  factory CompilerConfig({bool compileWithLineInfo}) = CompilerConfigImpl;

  bool get compileWithLineInfo;
}

class CompilerConfigImpl implements CompilerConfig {
  @override
  final bool compileWithLineInfo;

  const CompilerConfigImpl({this.compileWithLineInfo = true});
}

class HTCompiler implements AbstractAstVisitor<Uint8List> {
  static final version = Version(0, 3, 9);
  static const constStringLengthLimit = 128;

  /// Hetu script bytecode's bytecode signature
  static const hetuSignatureData = [8, 5, 20, 21];
  static const hetuSignature = 134550549;

  CompilerConfig config;

  final _curConstTable = ConstTable();

  int _curLine = 0;
  int _curColumn = 0;
  int get curLine => _curLine;
  int get curColumn => _curColumn;

  final List<Map<String, String>> _markedSymbolsList = [];

  HTCompiler({CompilerConfig? config})
      : config = config ?? const CompilerConfigImpl();

  Uint8List compile(HTModuleParseResult compilation) {
    final mainBytesBuilder = BytesBuilder();
    // hetu bytecode signature
    mainBytesBuilder.add(hetuSignatureData);
    // hetu bytecode version
    mainBytesBuilder.addByte(version.major);
    mainBytesBuilder.addByte(version.minor);
    mainBytesBuilder.add(_uint16(version.patch));
    // index: ResourceType
    mainBytesBuilder.addByte(compilation.type.index);
    final bytesBuilder = BytesBuilder();

    void compileSource(HTSourceParseResult result) {
      bytesBuilder.addByte(HTOpCode.file);
      bytesBuilder.add(_identifierString(result.fullName));
      bytesBuilder.addByte(result.type.index);
      for (final node in result.nodes) {
        final bytes = compileAst(node);
        bytesBuilder.add(bytes);
      }
      bytesBuilder.addByte(HTOpCode.endOfFile);
    }

    for (final value in compilation.values.values) {
      compileSource(value);
    }
    for (final value in compilation.sources.values) {
      compileSource(value);
    }
    final code = bytesBuilder.toBytes();
    // const table
    mainBytesBuilder.addByte(HTOpCode.constTable);
    mainBytesBuilder.add(_uint16(_curConstTable.intTable.length));
    for (final value in _curConstTable.intTable) {
      mainBytesBuilder.add(_int32(value));
      // mainBytesBuilder.add(_int64(value));
    }
    mainBytesBuilder.add(_uint16(_curConstTable.floatTable.length));
    for (final value in _curConstTable.floatTable) {
      mainBytesBuilder.add(_float32(value));
      // mainBytesBuilder.add(_float64(value));
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

  /// -2,147,483,648 to 2,147,483,647
  Uint8List _int32(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

  Uint8List _float32(double value) =>
      Uint8List(4)..buffer.asByteData().setFloat32(0, value, Endian.big);

  /// -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
  // Uint8List _int64(int value) =>
  //     Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);

  // Uint8List _float64(double value) =>
  //     Uint8List(4)..buffer.asByteData().setFloat64(0, value, Endian.big);

  // Uint8List _string(String value) {
  //   final bytesBuilder = BytesBuilder();
  //   final stringData = utf8.encoder.convert(value);
  //   bytesBuilder.addByte(stringData.length);
  //   bytesBuilder.add(stringData);
  //   return bytesBuilder.toBytes();
  // }

  Uint8List _lineInfo(int line, int column) {
    final bytesBuilder = BytesBuilder();
    if (config.compileWithLineInfo) {
      _curLine = line;
      _curColumn = column;
      bytesBuilder.addByte(HTOpCode.lineInfo);
      bytesBuilder.add(_uint16(line));
      bytesBuilder.add(_uint16(column));
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _localConst(int type, int constIndex, int line, int column) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(type);
    bytesBuilder.add(_uint16(constIndex));
    return bytesBuilder.toBytes();
  }

  Uint8List _utf8String(String value) {
    final bytesBuilder = BytesBuilder();
    final stringData = utf8.encoder.convert(value);
    bytesBuilder.add(_uint16(stringData.length));
    bytesBuilder.add(stringData);
    return bytesBuilder.toBytes();
  }

  Uint8List _identifierString(String value) {
    final bytesBuilder = BytesBuilder();
    if (value.length > constStringLengthLimit) {
      bytesBuilder.addByte(1); // bool: isLocal
      final bytes = _utf8String(value);
      bytesBuilder.add(bytes);
    } else {
      bytesBuilder.addByte(0); // bool: isLocal
      final index = _curConstTable.addString(value);
      bytesBuilder.add(_uint16(index));
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _parseCallArguments(
      List<AstNode> posArgsNodes, Map<String, AstNode> namedArgsNodes,
      {bool hasLength = false}) {
    // 这里不判断左括号，已经跳过了
    final bytesBuilder = BytesBuilder();
    final positionalArgBytesList = <Uint8List>[];
    final namedArgBytesList = <String, Uint8List>{};
    for (final ast in posArgsNodes) {
      final argBytesBuilder = BytesBuilder();
      final bytes = compileAst(ast, endOfExec: true);
      if (ast is! SpreadExpr) {
        // bool: is not spread
        // spread AST will add the bool so we only add 0 for other ASTs.
        argBytesBuilder.addByte(0);
      }
      argBytesBuilder.add(bytes);
      positionalArgBytesList.add(argBytesBuilder.toBytes());
    }
    for (final name in namedArgsNodes.keys) {
      final bytes = compileAst(namedArgsNodes[name]!, endOfExec: true);
      namedArgBytesList[name] = bytes;
    }
    bytesBuilder.addByte(positionalArgBytesList.length);
    for (var i = 0; i < positionalArgBytesList.length; ++i) {
      final argBytes = positionalArgBytesList[i];
      if (hasLength) {
        bytesBuilder.add(_uint16(argBytes.length));
      }
      bytesBuilder.add(argBytes);
    }
    bytesBuilder.addByte(namedArgBytesList.length);
    for (final name in namedArgBytesList.keys) {
      final nameExpr = _identifierString(name);
      bytesBuilder.add(nameExpr);
      final argExpr = namedArgBytesList[name]!;
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
        _localConst(HTValueTypeCode.constInt, index, line, column);
    bytesBuilder.add(constExpr);
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleLocalIdentifier(String id,
      {bool isLocal = true, bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.identifier);
    bytesBuilder.add(_identifierString(id));
    bytesBuilder.addByte(isLocal ? 1 : 0); // bool: isLocal
    // bytesBuilder.addByte(0); // bool: has type args
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleVarDeclStmt(String id, int line, int column,
      {Uint8List? initializer,
      bool isMutable = true,
      bool lateInitialize = false}) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.varDecl);
    bytesBuilder.add(_identifierString(id));
    bytesBuilder.addByte(0); // bool: hasClassId
    bytesBuilder.addByte(0);
    bytesBuilder.addByte(0); // bool: isExternal
    bytesBuilder.addByte(0); // bool: isStatic
    bytesBuilder.addByte(isMutable ? 1 : 0); // bool: isMutable
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

  Uint8List compileAst(AstNode node, {bool endOfExec = false}) {
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
  Uint8List visitNullExpr(NullExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.nullValue);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBooleanExpr(BooleanExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.boolean);
    bytesBuilder.addByte(expr.value ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitIntLiteralExpr(IntLiteralExpr expr) {
    final index = _curConstTable.addInt(expr.value);
    return _localConst(HTValueTypeCode.constInt, index, expr.line, expr.column);
  }

  @override
  Uint8List visitFloatLiteralExpr(FloatLiteralExpr expr) {
    final index = _curConstTable.addFloat(expr.value);
    return _localConst(
        HTValueTypeCode.constFloat, index, expr.line, expr.column);
  }

  @override
  Uint8List visitStringLiteralExpr(StringLiteralExpr expr) {
    var literal = expr.value;
    HTLexicon.stringEscapes.forEach((key, value) {
      literal = literal.replaceAll(key, value);
    });
    if (literal.length > constStringLengthLimit) {
      final bytesBuilder = BytesBuilder();
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.string);
      bytesBuilder.add(_utf8String(literal));
      return bytesBuilder.toBytes();
    } else {
      final index = _curConstTable.addString(literal);
      return _localConst(
          HTValueTypeCode.constString, index, expr.line, expr.column);
    }
  }

  @override
  Uint8List visitStringInterpolationExpr(StringInterpolationExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.stringInterpolation);
    var literal = expr.value;
    HTLexicon.stringEscapes.forEach((key, value) {
      literal = literal.replaceAll(key, value);
    });
    bytesBuilder.add(_utf8String(literal));
    bytesBuilder.addByte(expr.interpolation.length);
    for (final node in expr.interpolation) {
      final bytes = compileAst(node, endOfExec: true);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitSpreadExpr(SpreadExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(1); // bool: isSpread
    final bytes = compileAst(expr.value);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitListExpr(ListExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.list);
    bytesBuilder.add(_uint16(expr.list.length));
    for (final item in expr.list) {
      if (item is! SpreadExpr) {
        bytesBuilder.addByte(0); // bool: isSpread
      }
      final bytes = compileAst(item, endOfExec: true);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitStructObjField(StructObjField field) {
    final bytesBuilder = BytesBuilder();
    if (field.key != null) {
      bytesBuilder
          .addByte(StructObjFieldTypeCode.normal); // normal key: value field
      bytesBuilder.add(_identifierString(field.key!));
      final valueBytes = compileAst(field.value!, endOfExec: true);
      bytesBuilder.add(valueBytes);
    } else if (field.isSpread) {
      bytesBuilder
          .addByte(StructObjFieldTypeCode.spread); // spread another object
      final valueBytes = compileAst(field.value!, endOfExec: true);
      bytesBuilder.add(valueBytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitStructObjExpr(StructObjExpr obj) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.struct);
    if (obj.id != null) {
      bytesBuilder.addByte(1); // bool: has id
      bytesBuilder.add(_identifierString(obj.id!));
    } else {
      bytesBuilder.addByte(0); // bool: has id
    }
    if (obj.prototypeId != null) {
      bytesBuilder.addByte(1); // bool: has prototype
      bytesBuilder.add(_identifierString(obj.prototypeId!.id));
    } else {
      bytesBuilder.addByte(0); // bool: has prototype
    }
    final fields = obj.fields.where((field) => field.value != null);
    bytesBuilder.addByte(fields.length);
    for (final field in fields) {
      final bytes = visitStructObjField(field);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  // @override
  // Uint8List visitMapExpr(MapExpr expr) {
  //   final bytesBuilder = BytesBuilder();
  //   bytesBuilder.add(_lineInfo(expr.line, expr.column));
  //   bytesBuilder.addByte(HTOpCode.local);
  //   bytesBuilder.addByte(HTValueTypeCode.map);
  //   bytesBuilder.add(_uint16(expr.map.length));
  //   for (final ast in expr.map.keys) {
  //     final key = compileAst(ast, endOfExec: true);
  //     bytesBuilder.add(key);
  //     final value = compileAst(expr.map[ast]!, endOfExec: true);
  //     bytesBuilder.add(value);
  //   }
  //   return bytesBuilder.toBytes();
  // }

  @override
  Uint8List visitGroupExpr(GroupExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.group);
    final innerExpr = compileAst(expr.inner, endOfExec: true);
    bytesBuilder.add(innerExpr);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitIdentifierExpr(IdentifierExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(expr.line, expr.column));
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
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.identifier);
    bytesBuilder.add(_identifierString(symbolId));
    bytesBuilder.addByte(expr.isLocal ? 1 : 0);
    // if (expr.typeArgs.isNotEmpty) {
    //   bytesBuilder.addByte(1);
    //   bytesBuilder.addByte(expr.typeArgs.length); // bool: has type args
    //   for (final ast in expr.typeArgs) {
    //     final bytes = visitTypeExpr(ast);
    //     bytesBuilder.add(bytes);
    //   }
    // } else {
    //   bytesBuilder.addByte(0); // bool: has type args
    // }
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
    bytesBuilder.add(_identifierString(expr.id!.id));
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
    // could be function type so use visit ast node instead of visit type expr
    final declTypeBytes = compileAst(expr.declType);
    bytesBuilder.add(declTypeBytes);
    bytesBuilder.addByte(expr.isOptional ? 1 : 0);
    bytesBuilder.addByte(expr.isVariadic ? 1 : 0);
    if (expr.id != null) {
      bytesBuilder.addByte(1); // bool: isNamed
      bytesBuilder.add(_identifierString(expr.id!.id));
    } else {
      bytesBuilder.addByte(0); // bool: isNamed
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {
    final bytesBuilder = BytesBuilder();
    // TODO: generic type params
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
    final value = compileAst(expr.value);
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
        final constOne = IntLiteralExpr(1);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final add = BinaryExpr(memberExpr, HTLexicon.add, constOne);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, add);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final add = BinaryExpr(subExpr, HTLexicon.add, constOne);
          value = SubAssignExpr(subExpr.object, subExpr.key, add);
        } else {
          final add = BinaryExpr(expr.value, HTLexicon.add, constOne);
          value = BinaryExpr(expr.value, HTLexicon.assign, add);
        }
        final group = GroupExpr(value);
        final bytes = compileAst(group);
        bytesBuilder.add(bytes);
        break;
      case HTLexicon.preDecrement:
        final constOne = IntLiteralExpr(1);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final subtract = BinaryExpr(memberExpr, HTLexicon.subtract, constOne);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, subtract);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final subtract = BinaryExpr(subExpr, HTLexicon.subtract, constOne);
          value = SubAssignExpr(subExpr.object, subExpr.key, subtract);
        } else {
          final subtract = BinaryExpr(expr.value, HTLexicon.subtract, constOne);
          value = BinaryExpr(expr.value, HTLexicon.assign, subtract);
        }
        final group = GroupExpr(value);
        final bytes = compileAst(group);
        bytesBuilder.add(bytes);
        break;
      case HTLexicon.kTypeof:
        bytesBuilder.add(value);
        bytesBuilder.addByte(HTOpCode.typeOf);
        break;
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBinaryExpr(BinaryExpr expr) {
    final bytesBuilder = BytesBuilder();
    final left = compileAst(expr.left);
    final right = compileAst(expr.right);
    switch (expr.op) {
      case HTLexicon.assign:
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.assign);
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.assign);
        break;
      case HTLexicon.ifNull:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.orLeft);
        bytesBuilder.addByte(HTOpCode.ifNull);
        bytesBuilder.add(_uint16(right.length + 1)); // length of right value
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.endOfExec);
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
      case HTLexicon.kAs:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        final right = compileAst(expr.right);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.typeAs);
        break;
      case HTLexicon.kIs:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        final right = compileAst(expr.right);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.typeIs);
        break;
      case HTLexicon.kIsNot:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.relationLeft);
        final right = compileAst(expr.right);
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
      case HTLexicon.truncatingDevide:
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.multiplyLeft);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.truncatingDevide);
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
    final condition = compileAst(expr.condition);
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.ifStmt);
    final thenBranch = compileAst(expr.thenBranch);
    final elseBranch = compileAst(expr.elseBranch);
    bytesBuilder.add(_uint16(thenBranch.length + 3));
    bytesBuilder.add(thenBranch);
    bytesBuilder.addByte(HTOpCode.skip); // 执行完 then 之后，直接跳过 else block
    bytesBuilder.add(_int16(elseBranch.length));
    bytesBuilder.add(elseBranch);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitUnaryPostfixExpr(UnaryPostfixExpr expr) {
    final bytesBuilder = BytesBuilder();
    final value = compileAst(expr.value);
    bytesBuilder.add(value);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    switch (expr.op) {
      case HTLexicon.postIncrement:
        final constOne = IntLiteralExpr(1);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final add = BinaryExpr(memberExpr, HTLexicon.add, constOne);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, add);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final add = BinaryExpr(subExpr, HTLexicon.add, constOne);
          value = SubAssignExpr(subExpr.object, subExpr.key, add);
        } else {
          final add = BinaryExpr(expr.value, HTLexicon.add, constOne);
          value = BinaryExpr(expr.value, HTLexicon.assign, add);
        }
        final group = GroupExpr(value);
        final subtract = BinaryExpr(group, HTLexicon.subtract, constOne);
        final group2 = GroupExpr(subtract);
        final bytes = compileAst(group2);
        bytesBuilder.add(bytes);
        break;
      case HTLexicon.postDecrement:
        final constOne = IntLiteralExpr(1);
        late final AstNode value;
        if (expr.value is MemberExpr) {
          final memberExpr = expr.value as MemberExpr;
          final subtract = BinaryExpr(memberExpr, HTLexicon.subtract, constOne);
          value = MemberAssignExpr(memberExpr.object, memberExpr.key, subtract);
        } else if (expr.value is SubExpr) {
          final subExpr = expr.value as SubExpr;
          final subtract = BinaryExpr(subExpr, HTLexicon.subtract, constOne);
          value = SubAssignExpr(subExpr.object, subExpr.key, subtract);
        } else {
          final subtract = BinaryExpr(expr.value, HTLexicon.subtract, constOne);
          value = BinaryExpr(expr.value, HTLexicon.assign, subtract);
        }
        final group = GroupExpr(value);
        final add = BinaryExpr(group, HTLexicon.add, constOne);
        final group2 = GroupExpr(add);
        final bytes = compileAst(group2);
        bytesBuilder.add(bytes);
        break;
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitMemberExpr(MemberExpr expr) {
    final bytesBuilder = BytesBuilder();
    final object = compileAst(expr.object);
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder.addByte(HTOpCode.memberGet);
    bytesBuilder.addByte(expr.isNullable ? 1 : 0);
    final key = compileAst(expr.key, endOfExec: true);
    bytesBuilder.add(_uint16(key.length));
    bytesBuilder.add(key);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitMemberAssignExpr(MemberAssignExpr expr) {
    final bytesBuilder = BytesBuilder();
    final object = compileAst(expr.object);
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    final key = visitIdentifierExpr(expr.key);
    bytesBuilder.add(key);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixKey);
    bytesBuilder.addByte(HTOpCode.memberSet);
    final value = compileAst(expr.value, endOfExec: true);
    bytesBuilder.add(value);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitSubExpr(SubExpr expr) {
    final bytesBuilder = BytesBuilder();
    final array = compileAst(expr.object);
    bytesBuilder.add(array);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    final key = compileAst(expr.key, endOfExec: true);
    bytesBuilder.addByte(HTOpCode.subGet);
    bytesBuilder.addByte(expr.isNullable ? 1 : 0);
    bytesBuilder.add(_uint16(key.length));
    bytesBuilder.add(key);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitSubAssignExpr(SubAssignExpr expr) {
    final bytesBuilder = BytesBuilder();
    final array = compileAst(expr.array);
    bytesBuilder.add(array);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder.addByte(HTOpCode.subSet);
    // sub get key is after opcode
    // it has to be exec with 'move reg index'
    final key = compileAst(expr.key, endOfExec: true);
    bytesBuilder.add(key);
    final value = compileAst(expr.value, endOfExec: true);
    bytesBuilder.add(value);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitCallExpr(CallExpr expr) {
    final bytesBuilder = BytesBuilder();
    final callee = compileAst(expr.callee);
    bytesBuilder.add(callee);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder.addByte(HTOpCode.call);
    bytesBuilder.addByte(expr.isNullable ? 1 : 0);
    final argBytes = _parseCallArguments(expr.positionalArgs, expr.namedArgs);
    bytesBuilder.add(_uint16(argBytes.length));
    bytesBuilder.add(argBytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitAssertStmt(AssertStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.assertion);
    final source = stmt.source!;
    final text = source.content.substring(stmt.expr.offset, stmt.expr.end);
    bytesBuilder.add(_identifierString(text.trim()));
    final bytes = compileAst(stmt.expr, endOfExec: true);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitExprStmt(ExprStmt stmt) {
    final bytesBuilder = BytesBuilder();
    final bytes = compileAst(stmt.expr);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBlockStmt(BlockStmt block) {
    final bytesBuilder = BytesBuilder();
    if (block.hasOwnNamespace) {
      bytesBuilder.addByte(HTOpCode.block);
      if (block.id != null) {
        bytesBuilder.add(_identifierString(block.id!));
      } else {
        bytesBuilder.add(_identifierString(Semantic.anonymousBlock));
      }
    }
    for (final stmt in block.statements) {
      final bytes = compileAst(stmt);
      bytesBuilder.add(bytes);
    }
    if (block.hasOwnNamespace) {
      bytesBuilder.addByte(HTOpCode.endOfBlock);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitReturnStmt(ReturnStmt stmt) {
    final bytesBuilder = BytesBuilder();
    if (stmt.value != null) {
      final bytes = compileAst(stmt.value!);
      bytesBuilder.add(bytes);
    }
    bytesBuilder.addByte(HTOpCode.endOfFunc);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitIfStmt(IfStmt stmt) {
    final bytesBuilder = BytesBuilder();
    final condition = compileAst(stmt.condition);
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.ifStmt);
    final thenBranch = compileAst(stmt.thenBranch);
    Uint8List? elseBranch;
    if (stmt.elseBranch != null) {
      elseBranch = compileAst(stmt.elseBranch!);
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
    final condition = compileAst(stmt.condition);
    final loop = compileAst(stmt.loop);
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
    final loop = compileAst(stmt.loop);
    Uint8List? condition;
    if (stmt.condition != null) {
      condition = compileAst(stmt.condition!);
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
    bytesBuilder.add(_identifierString(Semantic.forStmtInit));
    late Uint8List condition;
    Uint8List? increment;
    AstNode? capturedDecl;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (stmt.init != null) {
      // TODO: 如果有多个变量同时声明?
      final userDecl = stmt.init as VarDecl;
      final markedId = '${HTLexicon.internalMarker}${userDecl.id}';
      newSymbolMap[userDecl.id.id] = markedId;
      Uint8List? initializer;
      if (userDecl.initializer != null) {
        initializer = compileAst(userDecl.initializer!, endOfExec: true);
      }
      final initDecl = _assembleVarDeclStmt(
          markedId, userDecl.line, userDecl.column,
          initializer: initializer, isMutable: userDecl.isMutable);
      bytesBuilder.add(initDecl);
      // 这里是为了实现将变量声明移动到for循环语句块内部的效果
      final capturedInit = IdentifierExpr(markedId);
      capturedDecl = VarDecl(userDecl.id, initializer: capturedInit);
    }
    if (stmt.condition != null) {
      condition = compileAst(stmt.condition!);
    } else {
      final boolExpr = BooleanExpr(true);
      condition = visitBooleanExpr(boolExpr);
    }
    if (stmt.increment != null) {
      increment = compileAst(stmt.increment!);
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
  Uint8List visitForRangeStmt(ForRangeStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.block);
    bytesBuilder.add(_identifierString(Semantic.forStmtInit));
    Uint8List? condition;
    Uint8List? increment;
    // declare the increment variable
    final increId = Semantic.increment;
    final increInit = _assembleLocalConstInt(
        0, stmt.iterator.line, stmt.iterator.column,
        endOfExec: true);
    final increDecl = _assembleVarDeclStmt(
        increId, stmt.iterator.line, stmt.iterator.column,
        initializer: increInit);
    bytesBuilder.add(increDecl);
    // assemble the condition expression
    final conditionBytesBuilder = BytesBuilder();
    final collectionId = Semantic.collection;
    final collectionExpr = stmt.iterateValue
        ? MemberExpr(
            stmt.collection, IdentifierExpr(HTLexicon.values, isLocal: false))
        : stmt.collection;
    final collectionInit = compileAst(collectionExpr, endOfExec: true);
    final collectionDecl = _assembleVarDeclStmt(
        collectionId, stmt.collection.line, stmt.collection.column,
        initializer: collectionInit);
    bytesBuilder.add(collectionDecl);
    final isNotEmptyExpr = MemberExpr(IdentifierExpr(collectionId),
        IdentifierExpr(HTLexicon.isNotEmpty, isLocal: false));
    final isNotEmptyByte = compileAst(isNotEmptyExpr);
    conditionBytesBuilder.add(isNotEmptyByte);
    conditionBytesBuilder.addByte(HTOpCode.register);
    conditionBytesBuilder.addByte(HTRegIdx.andLeft);
    conditionBytesBuilder.addByte(HTOpCode.logicalAnd);
    final lesserLeftExpr = _assembleLocalIdentifier(increId);
    final lengthExpr = MemberExpr(IdentifierExpr(collectionId),
        IdentifierExpr(HTLexicon.length, isLocal: false));
    final lengthByte = compileAst(lengthExpr);
    final logicalAndRightLength = lesserLeftExpr.length + lengthByte.length + 4;
    conditionBytesBuilder.add(_uint16(logicalAndRightLength));
    conditionBytesBuilder.add(lesserLeftExpr);
    conditionBytesBuilder.addByte(HTOpCode.register);
    conditionBytesBuilder.addByte(HTRegIdx.relationLeft);
    conditionBytesBuilder.add(lengthByte);
    conditionBytesBuilder.addByte(HTOpCode.lesser);
    conditionBytesBuilder.addByte(HTOpCode.endOfExec);
    condition = conditionBytesBuilder.toBytes();

    // assemble the initializer of the captured variable
    final capturedDeclInit = CallExpr(
        MemberExpr(collectionExpr,
            IdentifierExpr(HTLexicon.elementAt, isLocal: false)),
        [IdentifierExpr(increId)],
        const {});
    // declared the captured variable
    final capturedDecl = VarDecl(stmt.iterator.id,
        initializer: capturedDeclInit, isMutable: stmt.iterator.isMutable);
    final incrementBytesBuilder = BytesBuilder();
    final preIncreExpr = _assembleLocalIdentifier(increId);
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
      condition = compileAst(stmt.condition!);
    }
    final cases = <Uint8List>[];
    final branches = <Uint8List>[];
    Uint8List? elseBranch;
    if (stmt.elseBranch != null) {
      elseBranch = compileAst(stmt.elseBranch!);
    }
    for (final ast in stmt.cases.keys) {
      final caseBytes = compileAst(ast, endOfExec: true);
      cases.add(caseBytes);
      final branchBytes = compileAst(stmt.cases[ast]!);
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
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.breakLoop);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitContinueStmt(ContinueStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.continueLoop);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitDeleteStmt(DeleteStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.delete);
    bytesBuilder.addByte(DeletingTypeCode.local);
    bytesBuilder.add(_identifierString(stmt.symbol));
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitDeleteMemberStmt(DeleteMemberStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.delete);
    bytesBuilder.addByte(DeletingTypeCode.member);
    final objectBytes = compileAst(stmt.object, endOfExec: true);
    bytesBuilder.add(objectBytes);
    bytesBuilder.add(_identifierString(stmt.key));
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitDeleteSubStmt(DeleteSubStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.delete);
    bytesBuilder.addByte(DeletingTypeCode.sub);
    final objectBytes = compileAst(stmt.object, endOfExec: true);
    bytesBuilder.add(objectBytes);
    final keyBytes = compileAst(stmt.key, endOfExec: true);
    bytesBuilder.add(keyBytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitImportExportDecl(ImportExportDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.importExportDecl);
    bytesBuilder.addByte(stmt.isExported ? 1 : 0); // bool: isExported
    bytesBuilder.addByte(stmt.showList.length);
    for (final id in stmt.showList) {
      bytesBuilder.add(_identifierString(id.id));
    }
    if (stmt.fromPath != null) {
      bytesBuilder.addByte(1); // bool: hasFromPath
      // use the normalized absolute name here instead of the key
      bytesBuilder.add(_identifierString(stmt.fullName!));
    } else {
      bytesBuilder.addByte(0); // bool: hasFromPath
    }
    if (stmt.alias != null) {
      bytesBuilder.addByte(1); // bool: has alias id
      bytesBuilder.add(_identifierString(stmt.alias!.id));
    } else {
      bytesBuilder.addByte(0); // bool: has alias id
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitNamespaceDecl(NamespaceDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.namespaceDecl);
    bytesBuilder.add(_identifierString(stmt.id.id));
    // if (stmt.id != null) {
    //   bytesBuilder.addByte(1); // bool: has id
    //   bytesBuilder.add(_identifierString(stmt.id!.id));
    // } else {
    //   bytesBuilder.addByte(0); // bool: has class id
    // }
    // if (stmt.classId != null) {
    //   bytesBuilder.addByte(1); // bool: has class id
    //   bytesBuilder.add(_identifierString(stmt.classId!));
    // } else {
    //   bytesBuilder.addByte(0); // bool: has class id
    // }
    final bytes = visitBlockStmt(stmt.definition);
    bytesBuilder.add(bytes);
    bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitTypeAliasDecl(TypeAliasDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.typeAliasDecl);
    bytesBuilder.add(_identifierString(stmt.id.id));
    if (stmt.classId != null) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_identifierString(stmt.classId!));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    // do not use visitTypeExpr here because the value could be a function type
    final bytes = compileAst(stmt.value);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitConstDecl(ConstDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.constDecl);
    bytesBuilder.add(_identifierString(stmt.id.id));
    if (stmt.classId != null) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_identifierString(stmt.classId!));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    bytesBuilder.addByte(stmt.isStatic ? 1 : 0); // bool: isStatic
    late int type, index;
    if (stmt.constExpr is IntLiteralExpr) {
      type = ConstType.intValue.index;
      index = _curConstTable.addInt((stmt.constExpr as IntLiteralExpr).value);
    } else if (stmt.constExpr is FloatLiteralExpr) {
      type = ConstType.floatValue.index;
      index =
          _curConstTable.addFloat((stmt.constExpr as FloatLiteralExpr).value);
    } else if (stmt.constExpr is StringLiteralExpr) {
      type = ConstType.stringValue.index;
      index =
          _curConstTable.addString((stmt.constExpr as StringLiteralExpr).value);
    }
    bytesBuilder.addByte(type);
    bytesBuilder.add(_uint16(index));
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitVarDecl(VarDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.varDecl);
    bytesBuilder.add(_identifierString(stmt.id.id));
    if (stmt.classId != null) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_identifierString(stmt.classId!));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    bytesBuilder.addByte(stmt.isField ? 1 : 0);
    bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
    bytesBuilder.addByte(stmt.isStatic ? 1 : 0);
    bytesBuilder.addByte(stmt.isMutable ? 1 : 0);
    bytesBuilder.addByte(stmt.lateInitialize ? 1 : 0);
    if (stmt.declType != null) {
      bytesBuilder.addByte(1); // bool: has type decl
      final typeDecl = compileAst(stmt.declType!);
      bytesBuilder.add(typeDecl);
    } else {
      bytesBuilder.addByte(0); // bool: has type decl
    }
    if (stmt.initializer != null) {
      bytesBuilder.addByte(1); // bool: has initializer
      final initializer = compileAst(stmt.initializer!, endOfExec: true);
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
  Uint8List visitParamDecl(ParamDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_identifierString(stmt.id.id));
    bytesBuilder.addByte(stmt.isOptional ? 1 : 0);
    bytesBuilder.addByte(stmt.isVariadic ? 1 : 0);
    bytesBuilder.addByte(stmt.isNamed ? 1 : 0);
    Uint8List? typeDecl;
    if (stmt.declType != null) {
      typeDecl = compileAst(stmt.declType!);
    }
    if (typeDecl != null) {
      bytesBuilder.addByte(1); // bool: has type decl
      bytesBuilder.add(typeDecl);
    } else {
      bytesBuilder.addByte(0); // bool: has type decl
    }
    Uint8List? initializer;
    if (stmt.initializer != null) {
      initializer = compileAst(stmt.initializer!, endOfExec: true);
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
  Uint8List visitReferConstructCallExpr(RedirectingConstructorCallExpr stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_identifierString(stmt.callee.id));
    if (stmt.key != null) {
      bytesBuilder.addByte(1); // bool: has constructor name
      bytesBuilder.add(_identifierString(stmt.key!.id));
    } else {
      bytesBuilder.addByte(0); // bool: has constructor name
    }
    final callArgs = _parseCallArguments(stmt.positionalArgs, stmt.namedArgs,
        hasLength: true);
    bytesBuilder.add(callArgs);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitFuncDecl(FuncDecl stmt) {
    // final savedCurFunc = _curFunc;
    final bytesBuilder = BytesBuilder();
    // TODO: 泛型param
    if (stmt.category != FunctionCategory.literal) {
      bytesBuilder.addByte(HTOpCode.funcDecl);
      // funcBytesBuilder.addByte(HTOpCode.funcDecl);
      bytesBuilder.add(_identifierString(stmt.internalName));
      if (stmt.id != null) {
        bytesBuilder.addByte(1); // bool: hasId
        bytesBuilder.add(_identifierString(stmt.id!.id));
      } else {
        bytesBuilder.addByte(0); // bool: hasId
      }
      if (stmt.classId != null) {
        bytesBuilder.addByte(1); // bool: hasClassId
        bytesBuilder.add(_identifierString(stmt.classId!));
      } else {
        bytesBuilder.addByte(0); // bool: hasClassId
      }
      if (stmt.externalTypeId != null) {
        bytesBuilder.addByte(1); // bool: hasExternalTypedef
        bytesBuilder.add(_identifierString(stmt.externalTypeId!));
      } else {
        bytesBuilder.addByte(0); // bool: hasExternalTypedef
      }
      bytesBuilder.addByte(stmt.category.index);
      bytesBuilder.addByte(stmt.isField ? 1 : 0);
      bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
      bytesBuilder.addByte(stmt.isStatic ? 1 : 0);
      bytesBuilder.addByte(stmt.isConst ? 1 : 0);
    } else {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.function);
      bytesBuilder.add(_identifierString(stmt.internalName));
      if (stmt.externalTypeId != null) {
        bytesBuilder.addByte(1);
        bytesBuilder.add(_identifierString(stmt.externalTypeId!));
      } else {
        bytesBuilder.addByte(0);
      }
    }
    bytesBuilder.addByte(stmt.hasParamDecls ? 1 : 0);
    bytesBuilder.addByte(stmt.isVariadic ? 1 : 0);
    bytesBuilder.addByte(stmt.minArity);
    bytesBuilder.addByte(stmt.maxArity);
    bytesBuilder.addByte(stmt.paramDecls.length); // max 255
    for (var param in stmt.paramDecls) {
      final bytes = visitParamDecl(param);
      bytesBuilder.add(bytes);
    }
    if (stmt.category == FunctionCategory.constructor) {
      // referring to another constructor
      if (stmt.redirectingCtorCallExpr != null) {
        bytesBuilder.addByte(1); // bool: hasRefCtor
        final bytes =
            visitReferConstructCallExpr(stmt.redirectingCtorCallExpr!);
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
      final body = compileAst(stmt.definition!);
      bytesBuilder.add(_uint16(body.length + 1)); // definition bytes length
      bytesBuilder.add(body);
      bytesBuilder.addByte(HTOpCode.endOfFunc);
    } else {
      bytesBuilder.addByte(0); // bool: has no definition
    }
    // _curFunc = savedCurFunc;
    if (stmt.category != FunctionCategory.literal && !stmt.isField) {
      bytesBuilder.addByte(HTOpCode.endOfStmt);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitClassDecl(ClassDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.classDecl);
    bytesBuilder.add(_identifierString(stmt.id.id));
    // TODO: 泛型param
    bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
    bytesBuilder.addByte(stmt.isAbstract ? 1 : 0);
    bytesBuilder.addByte(stmt.hasUserDefinedConstructor ? 1 : 0);
    Uint8List? superType;
    if (stmt.superType != null) {
      superType = visitTypeExpr(stmt.superType!);
      bytesBuilder.addByte(1); // bool: has super class
      bytesBuilder.add(superType);
    } else {
      bytesBuilder.addByte(0); // bool: has super class
    }
    bytesBuilder.addByte(0); // bool: is enum
    // TODO: deal with implements and mixins
    final classDefinition = visitBlockStmt(stmt.definition);
    bytesBuilder.add(classDefinition);
    bytesBuilder.addByte(HTOpCode.endOfExec);
    bytesBuilder.addByte(HTOpCode.endOfStmt);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitEnumDecl(EnumDecl stmt) {
    final bytesBuilder = BytesBuilder();

    // Script enum are compiled to a class with static members
    // and a private constructor.
    //
    // For example:
    // ```dart
    // enum ENUM {
    //   value1,
    //   value2,
    //   value3
    // }
    // ```
    //
    // are compiled into:
    // ```dart
    // class ENUM {
    //   final $name;
    //   ENUM._(name) {
    //     $name = name;
    //   }
    //   fun toString = 'ENUM.${_name}'
    //   static final value1 = ENUM._('value1')
    //   static final value2 = ENUM._('value2')
    //   static final value3 = ENUM._('value3')
    //   static final values = [value1, value2, value3]
    // }
    // ```
    if (!stmt.isExternal) {
      bytesBuilder.addByte(HTOpCode.classDecl);
      bytesBuilder.add(_identifierString(stmt.id.id));
      bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
      bytesBuilder.addByte(0); // bool: is abstract
      bytesBuilder.addByte(1); // bool: has user defined constructor
      bytesBuilder.addByte(0); // bool: has super class
      bytesBuilder.addByte(1); // bool: is enum

      final valueId = '${HTLexicon.privatePrefix}${Semantic.name}';
      final value = VarDecl(IdentifierExpr(valueId), classId: stmt.id.id);
      final valueBytes = visitVarDecl(value);
      bytesBuilder.add(valueBytes);

      final ctorParam = ParamDecl(IdentifierExpr(Semantic.name));
      final ctorDef = BinaryExpr(IdentifierExpr(valueId), HTLexicon.assign,
          IdentifierExpr(Semantic.name));
      final constructor = FuncDecl(
          '${Semantic.constructor}${HTLexicon.privatePrefix}', [ctorParam],
          id: IdentifierExpr(HTLexicon.privatePrefix),
          classId: stmt.id.id,
          minArity: 1,
          maxArity: 1,
          definition: ctorDef,
          category: FunctionCategory.constructor);
      final ctorBytes = visitFuncDecl(constructor);
      bytesBuilder.add(ctorBytes);

      final toStringDef = StringInterpolationExpr(
          '${stmt.id.id}${HTLexicon.memberGet}${HTLexicon.bracesLeft}0${HTLexicon.bracesRight}',
          HTLexicon.apostropheLeft,
          HTLexicon.apostropheRight,
          [IdentifierExpr(valueId)]);
      final toStringFunc = FuncDecl(HTLexicon.tostring, [],
          id: IdentifierExpr(HTLexicon.tostring),
          classId: stmt.id.id,
          returnType: TypeExpr(id: IdentifierExpr(HTLexicon.str)),
          hasParamDecls: true,
          definition: toStringDef);
      final toStringBytes = visitFuncDecl(toStringFunc);
      bytesBuilder.add(toStringBytes);

      final itemList = <AstNode>[];
      for (final item in stmt.enumerations) {
        itemList.add(item);
        final itemInit = CallExpr(
            MemberExpr(stmt.id,
                IdentifierExpr(HTLexicon.privatePrefix, isLocal: false)),
            [
              StringLiteralExpr(
                  item.id, HTLexicon.apostropheLeft, HTLexicon.apostropheRight)
            ],
            const {});
        final itemDecl = VarDecl(item,
            classId: stmt.classId,
            initializer: itemInit,
            isStatic: true,
            lateInitialize: true);
        final itemBytes = visitVarDecl(itemDecl);
        bytesBuilder.add(itemBytes);
      }

      final valuesInit = ListExpr(itemList);
      final valuesDecl = VarDecl(IdentifierExpr(HTLexicon.values),
          classId: stmt.classId,
          initializer: valuesInit,
          isStatic: true,
          lateInitialize: true);
      final valuesBytes = visitVarDecl(valuesDecl);
      bytesBuilder.add(valuesBytes);

      bytesBuilder.addByte(HTOpCode.endOfExec);
      bytesBuilder.addByte(HTOpCode.endOfStmt);
    } else {
      bytesBuilder.addByte(HTOpCode.externalEnumDecl);
      bytesBuilder.add(_identifierString(stmt.id.id));
    }

    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitStructDecl(StructDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.structDecl);
    bytesBuilder.add(_identifierString(stmt.id.id));
    if (stmt.prototypeId != null) {
      bytesBuilder.addByte(1); // bool: hasPrototypeId
      bytesBuilder.add(_identifierString(stmt.prototypeId!.id));
    } else {
      bytesBuilder.addByte(0); // bool: hasPrototypeId
    }
    bytesBuilder.addByte(stmt.lateInitialize ? 1 : 0);
    final staticFields = <StructObjField>[];
    final fields = <StructObjField>[];
    // TODO: deal with comments
    for (final node in stmt.definition) {
      AstNode initializer;
      if (node is VarDecl) {
        initializer = node.initializer ?? NullExpr();
        final field = StructObjField(key: node.id.id, value: initializer);
        node.isStatic ? staticFields.add(field) : fields.add(field);
      } else if (node is FuncDecl) {
        FuncDecl initializer = node;
        final field =
            StructObjField(key: initializer.internalName, value: initializer);
        node.isStatic ? staticFields.add(field) : fields.add(field);
      }
      // Other node type is ignored.
    }
    final staticBytes =
        compileAst(StructObjExpr(staticFields), endOfExec: true);
    final structBytes = compileAst(
        StructObjExpr(fields, id: stmt.id.id, prototypeId: stmt.prototypeId),
        endOfExec: true);
    bytesBuilder.add(_uint16(staticBytes.length));
    bytesBuilder.add(staticBytes);
    bytesBuilder.add(_uint16(structBytes.length));
    bytesBuilder.add(structBytes);

    bytesBuilder.addByte(HTOpCode.endOfStmt);
    return bytesBuilder.toBytes();
  }
}
