import 'dart:typed_data';
import 'dart:convert';

import '../ast/ast.dart';
import '../lexer/lexicon.dart';
import '../lexer/lexicon_default_impl.dart';
import '../grammar/constant.dart';
import '../shared/constants.dart';
import '../constant/global_constant_table.dart';
import '../version.dart';
// import '../parser/parser.dart';

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

class CompilerConfig {
  bool compileWithoutLineInfo;

  CompilerConfig({this.compileWithoutLineInfo = false});
}

/// Compiles source code into bytecode.
///
/// DON'T USE THIS CLASS DIRECTLY!
///
/// Rather, use interpreter or
/// command line tools to compile,
/// they would use analyzer to try to find errors,
/// and compute constant values,
/// before actual compilation.
class HTCompiler implements AbstractASTVisitor<Uint8List> {
  static const constStringLengthLimit = 128;

  /// Hetu script bytecode's bytecode signature
  static const hetuSignatureData = [8, 5, 20, 21];
  static const hetuSignature = 134550549;

  static var iterIndex = 0;
  static var awaitedValueIndex = 0;

  CompilerConfig config;

  late final HTLexicon _lexicon;

  late HTGlobalConstantTable _currentConstantTable;

  int _curLine = 0;
  int _curColumn = 0;
  int get curLine => _curLine;
  int get curColumn => _curColumn;

  // Replace user defined identifiers with internal ones, used in for statement.
  final List<Map<String, String>> _markedSymbolsList = [];

  // Stored all awaited values and those internal identifiers replaces them.
  // key is the stmt astnode itself
  // Map<String, ASTNode> _curStmtAwaitedExprs = {};
  // Map<ASTNode, Map<String, ASTNode>> _awaitedExprsInStmts = {};

  HTCompiler({
    CompilerConfig? config,
    HTLexicon? lexicon,
  })  : config = config ?? CompilerConfig(),
        _lexicon = lexicon ?? HTDefaultLexicon();

  Uint8List compile(
    ASTCompilation compilation, {
    bool debugPerformance = false,
  }) {
    final tik = DateTime.now().millisecondsSinceEpoch;
    final bytes = compilation.accept(this);
    final tok = DateTime.now().millisecondsSinceEpoch;
    if (debugPerformance) {
      print('hetu: ${tok - tik}ms\tto compile\t[${compilation.entryFullname}]');
    }
    return bytes;
  }

  /// -32768 to 32767
  Uint8List _int16(int value) =>
      Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.big);

  /// 0 to 65,535
  Uint8List _uint16(int value) =>
      Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);

  /// 0 to 4,294,967,295
  Uint8List _uint32(int value) =>
      Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

  /// -2,147,483,648 to 2,147,483,647
  // Uint8List _int32(int value) =>
  //     Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);

  // Uint8List _float32(double value) =>
  //     Uint8List(4)..buffer.asByteData().setFloat32(0, value, Endian.big);

  /// -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
  // Uint8List _int64(int value) {
  //     Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);
  // }

  // Uint8List _float64(double value) {
  //     Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);
  // }

  /// -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
  /// Because Dart on web does not support ByteData.setInt64,
  /// This function uses another way to store any number as 64bit,
  /// However this method will occupied more spaces if it's a small number.
  // Uint8List _int64(int number) {
  //   var isNegative = 0;
  //   if (number < 0) {
  //     isNegative = 1;
  //     number = -number - 1;
  //   }
  //   final sign = isNegative << 31;
  //   final bigEnd = number >>> 32;
  //   final littleEnd = (number << 32) >>> 32;
  //   final bytes = Uint8List(8);
  //   bytes.buffer.asByteData().setUint32(0, sign + bigEnd, Endian.big);
  //   bytes.buffer.asByteData().setUint32(4, littleEnd, Endian.big);
  //   return bytes;
  // }

  /// -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
  /// This method store any integer number as utf8string,
  /// will occupied more spaces if it's a big number, which is rare.
  Uint8List _int64(int value) {
    return _utf8String(value.toString());
  }

  /// This method store any float number as utf8string,
  Uint8List _float64(double value) {
    return _utf8String(value.toString());
  }

  Uint8List _utf8String(String value) {
    final bytesBuilder = BytesBuilder();
    final stringData = utf8.encoder.convert(value);
    bytesBuilder.add(_uint32(stringData.length));
    bytesBuilder.add(stringData);
    return bytesBuilder.toBytes();
  }

  Uint8List _parseIdentifier(String value) {
    final bytesBuilder = BytesBuilder();
    final index = _currentConstantTable.addGlobalConstant<String>(value);
    bytesBuilder.add(_uint16(index));
    return bytesBuilder.toBytes();
  }

  Uint8List _lineInfo(int line, int column) {
    final bytesBuilder = BytesBuilder();
    if (!config.compileWithoutLineInfo) {
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

  Uint8List _parseCallArguments(
      List<ASTNode> posArgsNodes, Map<String, ASTNode> namedArgsNodes,
      {bool hasLength = false}) {
    final bytesBuilder = BytesBuilder();
    final positionalArgBytesList = <Uint8List>[];
    final namedArgBytesList = <String, Uint8List>{};
    for (final ast in posArgsNodes) {
      final argBytesBuilder = BytesBuilder();
      final bytes = compileAST(ast, endOfExec: true);
      if (ast is! SpreadExpr) {
        // bool: is not spread
        // spread AST will add the bool so we only add 0 for other ASTs.
        argBytesBuilder.addByte(0);
      }
      argBytesBuilder.add(bytes);
      positionalArgBytesList.add(argBytesBuilder.toBytes());
    }
    for (final name in namedArgsNodes.keys) {
      final bytes = compileAST(namedArgsNodes[name]!, endOfExec: true);
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
      final nameExpr = _parseIdentifier(name);
      bytesBuilder.add(nameExpr);
      final argExpr = namedArgBytesList[name]!;
      if (hasLength) {
        bytesBuilder.add(_uint16(argExpr.length));
      }
      bytesBuilder.add(argExpr);
    }
    return bytesBuilder.toBytes();
  }

  Uint8List _assembleVarDeclStmt(String id, int line, int column,
      {Uint8List? initializer,
      bool isMutable = true,
      bool lateInitialize = false}) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.varDecl);
    bytesBuilder.add(_parseIdentifier(id));
    bytesBuilder.addByte(0); // bool: hasClassId
    bytesBuilder.addByte(0);
    bytesBuilder.addByte(0); // bool: isExternal
    bytesBuilder.addByte(0); // bool: isStatic
    bytesBuilder.addByte(isMutable ? 1 : 0); // bool: isMutable
    bytesBuilder.addByte(0); // bool: isTopLevel
    bytesBuilder.addByte(0); // bool: lateFinalize
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

  // If necessary, transform a statement with await keyword into a callback form.
  // for example, statement like this:
  //
  //   final c = await a() + await b()
  //
  // will be turned into this in bytecode:
  //
  //   a().then((_$awaited_a) {
  //     b().then((_$awaited_b) {
  //       final c = _$awaited_a + _$awaited_b
  //     })
  //   })
  // ASTNode? _convertPossibleAwaitedExpressionToCallBack(ASTNode node,
  //     [List<ASTNode> restSyncCode = const []]) {
  //   if (_curStmtAwaitedExprs.isNotEmpty) {
  //     ASTNode awaitedStmt = node;
  //     for (final id in _curStmtAwaitedExprs.keys.toList().reversed) {
  //       final value = _curStmtAwaitedExprs[id]!;
  //       awaitedStmt = CallExpr(
  //           MemberExpr(GroupExpr(value), IdentifierExpr(_lexicon.idThen)),
  //           positionalArgs: [
  //             FuncDecl(
  //               '${InternalIdentifier.anonymousFunction}${HTParser.anonymousFunctionIndex++}',
  //               category: FunctionCategory.literal,
  //               paramDecls: [ParamDecl(IdentifierExpr(id))],
  //               definition: BlockStmt([node, ...restSyncCode],
  //                   id: Semantic.functionCall),
  //             )
  //           ]);
  //     }
  //     return awaitedStmt;
  //   } else {
  //     return null;
  //   }
  // }

  Uint8List compileAST(ASTNode node, {bool endOfExec = false}) {
    final bytesBuilder = BytesBuilder();
    Uint8List bytes;
    bytes = node.accept(this);
    bytesBuilder.add(bytes);
    if (endOfExec) {
      bytesBuilder.addByte(HTOpCode.endOfExec);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitCompilation(ASTCompilation compilation) {
    _currentConstantTable = HTGlobalConstantTable();

    final mainBytesBuilder = BytesBuilder();
    // hetu bytecode signature
    mainBytesBuilder.add(hetuSignatureData);
    // hetu bytecode version
    mainBytesBuilder.addByte(kHetuVersion.major);
    mainBytesBuilder.addByte(kHetuVersion.minor);
    mainBytesBuilder.add(_uint16(kHetuVersion.patch));
    // entry file name
    mainBytesBuilder.add(_utf8String(compilation.entryFullname));
    // index: ResourceType
    mainBytesBuilder.addByte(compilation.entryResourceType.index);
    final sourceBytesBuilder = BytesBuilder();
    for (final value in compilation.values.values) {
      final bytes = value.accept(this);
      sourceBytesBuilder.add(bytes);
    }
    for (final value in compilation.sources.values) {
      final bytes = value.accept(this);
      sourceBytesBuilder.add(bytes);
    }
    final code = sourceBytesBuilder.toBytes();
    // const tables
    for (final type in _currentConstantTable.constants.keys) {
      final table = _currentConstantTable.constants[type]!;
      if (type == int) {
        mainBytesBuilder.addByte(HTOpCode.constIntTable);
        mainBytesBuilder.add(_uint16(table.length));
        for (final value in table) {
          mainBytesBuilder.add(_int64(value));
        }
      } else if (type == double) {
        mainBytesBuilder.addByte(HTOpCode.constFloatTable);
        mainBytesBuilder.add(_uint16(table.length));
        for (final value in table) {
          mainBytesBuilder.add(_float64(value));
        }
      } else if (type == String) {
        mainBytesBuilder.addByte(HTOpCode.constStringTable);
        mainBytesBuilder.add(_uint16(table.length));
        for (final value in table) {
          mainBytesBuilder.add(_utf8String(value));
        }
      } else {
        continue;
      }
    }
    mainBytesBuilder.add(code);
    return mainBytesBuilder.toBytes();
  }

  @override
  Uint8List visitSource(ASTSource unit) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.file);
    // if the relativeName is null then it is the entry file of this module.
    bytesBuilder.add(_parseIdentifier(unit.fullName));
    bytesBuilder.addByte(unit.resourceType.index);
    // final convertedNodes = _convertPossibleAwaitedBlockToCallBack(unit.nodes);
    // for (final node in convertedNodes) {
    for (final node in unit.nodes) {
      final bytes = compileAST(node);
      bytesBuilder.add(bytes);
    }
    bytesBuilder.addByte(HTOpCode.endOfFile);

    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitComment(ASTComment expr) {
    return Uint8List(0);
  }

  @override
  Uint8List visitEmptyLine(ASTEmptyLine expr) {
    return Uint8List(0);
  }

  @override
  Uint8List visitEmptyExpr(ASTEmpty expr) {
    return Uint8List(0);
  }

  @override
  Uint8List visitNullExpr(ASTLiteralNull expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.nullValue);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBooleanExpr(ASTLiteralBoolean expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.boolean);
    bytesBuilder.addByte(expr.value ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitIntLiteralExpr(ASTLiteralInteger expr) {
    final index = _currentConstantTable.addGlobalConstant<int>(expr.value);
    return _localConst(HTValueTypeCode.constInt, index, expr.line, expr.column);
  }

  @override
  Uint8List visitFloatLiteralExpr(ASTLiteralFloat expr) {
    final index = _currentConstantTable.addGlobalConstant<double>(expr.value);
    return _localConst(
        HTValueTypeCode.constFloat, index, expr.line, expr.column);
  }

  @override
  Uint8List visitStringLiteralExpr(ASTLiteralString expr) {
    var literal = expr.value;
    _lexicon.escapeCharacters.forEach((key, value) {
      literal = literal.replaceAll(key, value);
    });
    if (literal.length > constStringLengthLimit) {
      final bytesBuilder = BytesBuilder();
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.string);
      bytesBuilder.add(_utf8String(literal));
      return bytesBuilder.toBytes();
    } else {
      final index = _currentConstantTable.addGlobalConstant<String>(literal);
      return _localConst(
          HTValueTypeCode.constString, index, expr.line, expr.column);
    }
  }

  @override
  Uint8List visitStringInterpolationExpr(ASTStringInterpolation expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.stringInterpolation);
    var literal = expr.text;
    _lexicon.escapeCharacters.forEach((key, value) {
      literal = literal.replaceAll(key, value);
    });
    bytesBuilder.add(_utf8String(literal));
    bytesBuilder.addByte(expr.interpolations.length);
    for (final node in expr.interpolations) {
      final bytes = compileAST(node, endOfExec: true);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitSpreadExpr(SpreadExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(1); // bool: isSpread
    final bytes = compileAST(expr.collection);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitCommaExpr(CommaExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.isLocal) {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.tuple);
    }
    bytesBuilder.addByte(expr.list.length);
    for (final item in expr.list) {
      final bytes = compileAST(item, endOfExec: true);
      bytesBuilder.add(bytes);
    }
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
      final bytes = compileAST(item, endOfExec: true);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitStructObjField(StructObjField field) {
    final bytesBuilder = BytesBuilder();
    if (field.isSpread) {
      bytesBuilder.addByte(1); // bool: has isSpread
      // spread another object
    } else {
      bytesBuilder.addByte(0); // bool: has isSpread
      // normal key: value field
      bytesBuilder.add(_parseIdentifier(field.key!.id));
    }
    final valueBytes = compileAST(field.fieldValue, endOfExec: true);
    bytesBuilder.add(valueBytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitStructObjExpr(StructObjExpr obj) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.struct);
    if (obj.id != null) {
      bytesBuilder.addByte(1); // bool: has id
      bytesBuilder.add(_parseIdentifier(obj.id!.id));
    } else {
      bytesBuilder.addByte(0); // bool: has id
    }
    if (obj.prototypeId != null) {
      bytesBuilder.addByte(1); // bool: has prototype
      bytesBuilder.add(_parseIdentifier(obj.prototypeId!.id));
    } else {
      bytesBuilder.addByte(0); // bool: has prototype
    }
    bytesBuilder.addByte(obj.fields.length);
    for (final field in obj.fields) {
      final bytes = visitStructObjField(field);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitInOfExpr(InOfExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(expr.valueOf ? 1 : 0); // bool: in is 0, of is 1
    final collectionExpr = compileAST(expr.collection, endOfExec: true);
    bytesBuilder.add(collectionExpr);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitGroupExpr(GroupExpr expr) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.local);
    bytesBuilder.addByte(HTValueTypeCode.group);
    final innerExpr = compileAST(expr.inner, endOfExec: true);
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
    bytesBuilder.add(_parseIdentifier(symbolId));
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
  Uint8List visitIntrinsicTypeExpr(IntrinsicTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.isLocal) {
      bytesBuilder.addByte(HTOpCode.local);
    }
    bytesBuilder.addByte(HTValueTypeCode.intrinsicType);
    bytesBuilder.add(_parseIdentifier(expr.id.id));
    bytesBuilder.addByte(expr.isTop ? 1 : 0);
    bytesBuilder.addByte(expr.isBottom ? 1 : 0);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitNominalTypeExpr(NominalTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.isLocal) {
      bytesBuilder.addByte(HTOpCode.local);
    }
    bytesBuilder.addByte(HTValueTypeCode.nominalType);
    bytesBuilder.add(_parseIdentifier(expr.id.id));
    bytesBuilder.addByte(expr.arguments.length); // max 255
    for (final expr in expr.arguments) {
      final typeArg = compileAST(expr); // dont' need end of exec mark here
      bytesBuilder.add(typeArg);
    }
    bytesBuilder.addByte(expr.isNullable ? 1 : 0); // bool isNullable
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitParamTypeExpr(ParamTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    // could be function type so use visit ast node instead of visit type expr
    final declTypeBytes = compileAST(expr.declType);
    bytesBuilder.add(declTypeBytes);
    bytesBuilder.addByte(expr.isOptionalPositional ? 1 : 0);
    bytesBuilder.addByte(expr.isVariadic ? 1 : 0);
    if (expr.id != null) {
      bytesBuilder.addByte(1); // bool: isNamed
      bytesBuilder.add(_parseIdentifier(expr.id!.id));
    } else {
      bytesBuilder.addByte(0); // bool: isNamed
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitFunctionTypeExpr(FuncTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.isLocal) {
      bytesBuilder.addByte(HTOpCode.local);
    }
    bytesBuilder.addByte(HTValueTypeCode.functionType);
    bytesBuilder
        .addByte(expr.paramTypes.length); // uint8: length of param types
    for (final param in expr.paramTypes) {
      final bytes = visitParamTypeExpr(param);
      bytesBuilder.add(bytes);
    }
    final returnType = compileAST(expr.returnType);
    bytesBuilder.add(returnType);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitFieldTypeExpr(FieldTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    final idBytes = _parseIdentifier(expr.id);
    bytesBuilder.add(idBytes);
    Uint8List typeBytes;
    if (expr.fieldType is FuncTypeExpr) {
      typeBytes = visitFunctionTypeExpr(expr.fieldType as FuncTypeExpr);
    } else {
      typeBytes = compileAST(expr.fieldType);
    }
    bytesBuilder.add(typeBytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitStructuralTypeExpr(StructuralTypeExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.isLocal) {
      bytesBuilder.addByte(HTOpCode.local);
    }
    bytesBuilder.addByte(HTValueTypeCode.structuralType);
    bytesBuilder
        .add(_uint16(expr.fieldTypes.length)); // uint8: length of param types
    for (final field in expr.fieldTypes) {
      final bytes = visitFieldTypeExpr(field);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitGenericTypeParamExpr(GenericTypeParameterExpr expr) {
    final bytesBuilder = BytesBuilder();
    final idBytes = visitIdentifierExpr(expr.id);
    bytesBuilder.add(idBytes);
    if (expr.superType != null) {
      bytesBuilder.addByte(1); // bool: hasSuperType
      final superTypeBytes = visitNominalTypeExpr(expr.superType!);
      bytesBuilder.add(superTypeBytes);
    } else {
      bytesBuilder.addByte(0); // bool: hasSuperType
    }
    return bytesBuilder.toBytes();
  }

  /// -e, !e，++e, --e
  @override
  Uint8List visitUnaryPrefixExpr(UnaryPrefixExpr expr) {
    final bytesBuilder = BytesBuilder();
    final value = compileAST(expr.object);
    if (expr.op == _lexicon.negative) {
      bytesBuilder.add(value);
      bytesBuilder.addByte(HTOpCode.negative);
    } else if (expr.op == _lexicon.logicalNot) {
      bytesBuilder.add(value);
      bytesBuilder.addByte(HTOpCode.logicalNot);
    } else if (expr.op == _lexicon.preIncrement) {
      final constOne = ASTLiteralInteger(1);
      late final ASTNode value;
      final add = BinaryExpr(expr.object, _lexicon.add, constOne);
      value = AssignExpr(expr.object, _lexicon.assign, add);
      final group = GroupExpr(value);
      final bytes = compileAST(group);
      bytesBuilder.add(bytes);
    } else if (expr.op == _lexicon.preDecrement) {
      final constOne = ASTLiteralInteger(1);
      late final ASTNode value;
      final subtract = BinaryExpr(expr.object, _lexicon.subtract, constOne);
      value = AssignExpr(expr.object, _lexicon.assign, subtract);
      final group = GroupExpr(value);
      final bytes = compileAST(group);
      bytesBuilder.add(bytes);
    } else if (expr.op == _lexicon.kTypeof) {
      bytesBuilder.add(value);
      bytesBuilder.addByte(HTOpCode.typeOf);
    } else if (expr.op == _lexicon.kAwait) {
      bytesBuilder.add(value);
      bytesBuilder.addByte(HTOpCode.await);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBinaryExpr(BinaryExpr expr) {
    final bytesBuilder = BytesBuilder();
    final left = compileAST(expr.left);
    final right = compileAST(expr.right);
    if (expr.op == _lexicon.ifNull) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.orLeft);
      bytesBuilder.addByte(HTOpCode.ifNull);
      bytesBuilder.add(_uint16(right.length + 1)); // length of right value
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.endOfExec);
    } else if (expr.op == _lexicon.logicalOr) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.orLeft);
      bytesBuilder.addByte(HTOpCode.logicalOr);
      bytesBuilder.add(_uint16(right.length + 1)); // length of right value
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.endOfExec);
    } else if (expr.op == _lexicon.logicalAnd) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.andLeft);
      bytesBuilder.addByte(HTOpCode.logicalAnd);
      bytesBuilder.add(_uint16(right.length + 1)); // length of right value
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.endOfExec);
    } else if (expr.op == _lexicon.equal) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.equalLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.equal);
    } else if (expr.op == _lexicon.notEqual) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.equalLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.notEqual);
    } else if (expr.op == _lexicon.lesser) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.lesser);
    } else if (expr.op == _lexicon.greater) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.greater);
    } else if (expr.op == _lexicon.lesserOrEqual) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.lesserOrEqual);
    } else if (expr.op == _lexicon.greaterOrEqual) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.greaterOrEqual);
    } else if (expr.op == _lexicon.kAs) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      final right = compileAST(expr.right);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.typeAs);
    } else if (expr.op == _lexicon.kIs) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      final right = compileAST(expr.right);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.typeIs);
    } else if (expr.op == _lexicon.kIsNot) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.relationLeft);
      final right = compileAST(expr.right);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.typeIsNot);
    } else if (expr.op == _lexicon.add) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.addLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.add);
    } else if (expr.op == _lexicon.subtract) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.addLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.subtract);
    } else if (expr.op == _lexicon.multiply) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.multiplyLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.multiply);
    } else if (expr.op == _lexicon.devide) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.multiplyLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.devide);
    } else if (expr.op == _lexicon.truncatingDevide) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.multiplyLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.truncatingDevide);
    } else if (expr.op == _lexicon.modulo) {
      bytesBuilder.add(left);
      bytesBuilder.addByte(HTOpCode.register);
      bytesBuilder.addByte(HTRegIdx.multiplyLeft);
      bytesBuilder.add(right);
      bytesBuilder.addByte(HTOpCode.modulo);
    } else if (expr.op == _lexicon.kIn) {
      final containsCallExpr = CallExpr(
          MemberExpr(expr.right,
              IdentifierExpr(_lexicon.idCollectionContains, isLocal: false)),
          positionalArgs: [expr.left]);
      final containsCallExprBytes = visitCallExpr(containsCallExpr);
      bytesBuilder.add(containsCallExprBytes);
    } else if (expr.op == _lexicon.kNotIn) {
      final containsCallExpr = CallExpr(
          MemberExpr(expr.right,
              IdentifierExpr(_lexicon.idCollectionContains, isLocal: false)),
          positionalArgs: [expr.left]);
      final containsCallExprBytes = visitCallExpr(containsCallExpr);
      bytesBuilder.add(containsCallExprBytes);
      bytesBuilder.addByte(HTOpCode.logicalNot);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitTernaryExpr(TernaryExpr expr) {
    final bytesBuilder = BytesBuilder();
    final condition = compileAST(expr.condition);
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.ifStmt);
    final thenBranch = compileAST(expr.thenBranch);
    final elseBranch = compileAST(expr.elseBranch);
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
    final value = compileAST(expr.object);
    bytesBuilder.add(value);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    if (expr.op == _lexicon.postIncrement) {
      final constOne = ASTLiteralInteger(1);
      late final ASTNode value;
      final add = BinaryExpr(expr.object, _lexicon.add, constOne);
      value = AssignExpr(expr.object, _lexicon.assign, add);
      final group = GroupExpr(value);
      final subtract = BinaryExpr(group, _lexicon.subtract, constOne);
      final group2 = GroupExpr(subtract);
      final bytes = compileAST(group2);
      bytesBuilder.add(bytes);
    } else if (expr.op == _lexicon.postDecrement) {
      final constOne = ASTLiteralInteger(1);
      late final ASTNode value;
      final subtract = BinaryExpr(expr.object, _lexicon.subtract, constOne);
      value = AssignExpr(expr.object, _lexicon.assign, subtract);
      final group = GroupExpr(value);
      final add = BinaryExpr(group, _lexicon.add, constOne);
      final group2 = GroupExpr(add);
      final bytes = compileAST(group2);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitAssignExpr(AssignExpr expr) {
    final bytesBuilder = BytesBuilder();
    if (expr.op == _lexicon.assign) {
      if (expr.left is MemberExpr) {
        final memberExpr = expr.left as MemberExpr;
        final object = compileAST(memberExpr.object);
        bytesBuilder.add(object);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.postfixObject);
        final key = visitIdentifierExpr(memberExpr.key);
        bytesBuilder.add(key);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.postfixKey);
        bytesBuilder.addByte(HTOpCode.memberSet);
        bytesBuilder.addByte(memberExpr.isNullable ? 1 : 0);
        final value = compileAST(expr.right, endOfExec: true);
        bytesBuilder.add(_uint16(value.length));
        bytesBuilder.add(value);
      } else if (expr.left is SubExpr) {
        final subExpr = expr.left as SubExpr;
        final array = compileAST(subExpr.object);
        bytesBuilder.add(array);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.postfixObject);
        bytesBuilder.addByte(HTOpCode.subSet);
        bytesBuilder.addByte(subExpr.isNullable ? 1 : 0);
        // sub get key is after opcode
        // it has to be exec with 'move reg index'
        final key = compileAST(subExpr.key, endOfExec: true);
        final value = compileAST(expr.right, endOfExec: true);
        bytesBuilder.add(_uint16(key.length + value.length));
        bytesBuilder.add(key);
        bytesBuilder.add(value);
      } else {
        final left = compileAST(expr.left);
        final right = compileAST(expr.right);
        bytesBuilder.add(right);
        bytesBuilder.addByte(HTOpCode.register);
        bytesBuilder.addByte(HTRegIdx.assign);
        bytesBuilder.add(left);
        bytesBuilder.addByte(HTOpCode.assign);
      }
    } else if (expr.op == _lexicon.assignIfNull) {
      final ifStmt = IfStmt(
        BinaryExpr(
          expr.left,
          _lexicon.equal,
          ASTLiteralNull(),
        ),
        AssignExpr(
          expr.left,
          _lexicon.assign,
          expr.right,
          source: expr.source,
          line: expr.line,
          column: expr.column,
        ),
      );
      final bytes = visitIf(ifStmt);
      bytesBuilder.add(bytes);
    } else {
      final spreaded = AssignExpr(
          expr.left,
          _lexicon.assign,
          BinaryExpr(
              expr.left, expr.op.substring(0, expr.op.length - 1), expr.right),
          source: expr.source,
          line: expr.line,
          column: expr.column);
      final bytes = visitAssignExpr(spreaded);
      bytesBuilder.add(bytes);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitMemberExpr(MemberExpr expr) {
    final bytesBuilder = BytesBuilder();
    final object = compileAST(expr.object);
    bytesBuilder.add(object);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder.addByte(HTOpCode.memberGet);
    bytesBuilder.addByte(expr.isNullable ? 1 : 0);
    final key = compileAST(expr.key, endOfExec: true);
    bytesBuilder.add(_uint16(key.length));
    bytesBuilder.add(key);
    return bytesBuilder.toBytes();
  }

  // @override
  // Uint8List visitMemberAssignExpr(MemberAssignExpr expr) {
  //   final bytesBuilder = BytesBuilder();
  //   final object = compileAst(expr.object);
  //   bytesBuilder.add(object);
  //   bytesBuilder.addByte(HTOpCode.register);
  //   bytesBuilder.addByte(HTRegIdx.postfixObject);
  //   final key = visitIdentifierExpr(expr.key);
  //   bytesBuilder.add(key);
  //   bytesBuilder.addByte(HTOpCode.register);
  //   bytesBuilder.addByte(HTRegIdx.postfixKey);
  //   bytesBuilder.addByte(HTOpCode.memberSet);
  //   final value = compileAst(expr.assignValue, endOfExec: true);
  //   bytesBuilder.add(value);
  //   return bytesBuilder.toBytes();
  // }

  @override
  Uint8List visitSubExpr(SubExpr expr) {
    final bytesBuilder = BytesBuilder();
    final array = compileAST(expr.object);
    bytesBuilder.add(array);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    final key = compileAST(expr.key, endOfExec: true);
    bytesBuilder.addByte(HTOpCode.subGet);
    bytesBuilder.addByte(expr.isNullable ? 1 : 0);
    bytesBuilder.add(_uint16(key.length));
    bytesBuilder.add(key);
    return bytesBuilder.toBytes();
  }

  // @override
  // Uint8List visitSubAssignExpr(SubAssignExpr expr) {
  //   final bytesBuilder = BytesBuilder();
  //   final array = compileAst(expr.array);
  //   bytesBuilder.add(array);
  //   bytesBuilder.addByte(HTOpCode.register);
  //   bytesBuilder.addByte(HTRegIdx.postfixObject);
  //   bytesBuilder.addByte(HTOpCode.subSet);
  //   // sub get key is after opcode
  //   // it has to be exec with 'move reg index'
  //   final key = compileAst(expr.key, endOfExec: true);
  //   bytesBuilder.add(key);
  //   final value = compileAst(expr.assignValue, endOfExec: true);
  //   bytesBuilder.add(value);
  //   return bytesBuilder.toBytes();
  // }

  @override
  Uint8List visitCallExpr(CallExpr expr) {
    final bytesBuilder = BytesBuilder();
    final callee = compileAST(expr.callee);
    bytesBuilder.add(callee);
    bytesBuilder.addByte(HTOpCode.register);
    bytesBuilder.addByte(HTRegIdx.postfixObject);
    bytesBuilder.addByte(HTOpCode.call);
    bytesBuilder.addByte(expr.isNullable ? 1 : 0);
    bytesBuilder.addByte(expr.hasNewOperator ? 1 : 0);
    final argBytes = _parseCallArguments(expr.positionalArgs, expr.namedArgs);
    bytesBuilder.add(_uint16(argBytes.length));
    bytesBuilder.add(argBytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitAssertStmt(AssertStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.assertion);
    final content = stmt.source!.content;
    final text = content.substring(stmt.expr.offset, stmt.expr.end);
    bytesBuilder.add(_parseIdentifier(text.trim()));
    final bytes = compileAST(stmt.expr, endOfExec: true);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitThrowStmt(ThrowStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    final messageBytes = compileAST(stmt.message);
    bytesBuilder.add(messageBytes);
    bytesBuilder.addByte(HTOpCode.throws);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitExprStmt(ExprStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    final bytes = compileAST(stmt.expr);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitBlockStmt(BlockStmt block) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(block.line, block.column));
    if (block.hasOwnNamespace) {
      bytesBuilder.addByte(HTOpCode.block);
      if (block.id != null) {
        bytesBuilder.add(_parseIdentifier(block.id!));
      } else {
        bytesBuilder.add(_parseIdentifier(InternalIdentifier.anonymousBlock));
      }
    }
    for (final stmt in block.statements) {
      final bytes = compileAST(stmt);
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
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    if (stmt.returnValue != null) {
      final bytes = compileAST(stmt.returnValue!);
      bytesBuilder.add(bytes);
    } else {
      bytesBuilder.addByte(HTOpCode.endOfStmt);
    }
    bytesBuilder.addByte(HTOpCode.endOfFunc);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitIf(IfStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    final condition = compileAST(stmt.condition);
    // The else branch of if stmt is optional, so just check stmt.value is not safe,
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.ifStmt);
    final thenBranch = compileAST(stmt.thenBranch);
    Uint8List? elseBranch;
    if (stmt.elseBranch != null) {
      elseBranch = compileAST(stmt.elseBranch!);
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
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.loopPoint);
    final condition = compileAST(stmt.condition);
    final loop = compileAST(stmt.loop);
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
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.loopPoint);
    final loop = compileAST(stmt.loop);
    Uint8List? condition;
    if (stmt.condition != null) {
      condition = compileAST(stmt.condition!);
    }
    final loopLength = loop.length + (condition?.length ?? 0) + 2;
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
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.block);
    bytesBuilder.add(_parseIdentifier(Semantic.forStmtInit));
    late Uint8List condition;
    Uint8List? increment;
    ASTNode? capturedDecl;
    final newSymbolMap = <String, String>{};
    _markedSymbolsList.add(newSymbolMap);
    if (stmt.init != null) {
      final userDecl = stmt.init as VarDecl;
      final markedId = '${_lexicon.internalPrefix}${userDecl.id.id}';
      newSymbolMap[userDecl.id.id] = markedId;
      Uint8List? initializer;
      if (userDecl.initializer != null) {
        initializer = compileAST(userDecl.initializer!, endOfExec: true);
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
      condition = compileAST(stmt.condition!);
    } else {
      final boolExpr = ASTLiteralBoolean(true);
      condition = visitBooleanExpr(boolExpr);
    }
    if (stmt.increment != null) {
      increment = compileAST(stmt.increment!);
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
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.block);
    bytesBuilder.add(_parseIdentifier(Semantic.forStmtInit));

    final collection = stmt.iterateValue
        ? MemberExpr(stmt.collection,
            IdentifierExpr(_lexicon.idCollectionValues, isLocal: false))
        : stmt.collection;

    // declare the iterator
    final iterInit = MemberExpr(collection,
        IdentifierExpr(_lexicon.idIterableIterator, isLocal: false));
    final iterInitBytes = compileAST(iterInit, endOfExec: true);
    final iterId = '__iter${iterIndex++}';
    final iterDecl = _assembleVarDeclStmt(
        iterId, stmt.iterator.line, stmt.iterator.column,
        initializer: iterInitBytes);
    bytesBuilder.add(iterDecl);

    // update iter move result
    // calls iterator.moveNext()
    final moveIter = CallExpr(MemberExpr(IdentifierExpr(iterId),
        IdentifierExpr(_lexicon.idIterableIteratorMoveNext, isLocal: false)));
    final moveIterBytes = visitCallExpr(moveIter);
    final condition = moveIterBytes;

    // get current item value
    stmt.iterator.initializer = MemberExpr(IdentifierExpr(iterId),
        IdentifierExpr(_lexicon.idIterableIteratorCurrent, isLocal: false));
    stmt.loop.statements.insert(0, stmt.iterator);
    final loop = visitBlockStmt(stmt.loop);

    bytesBuilder.addByte(HTOpCode.loopPoint);
    final continueLength = condition.length + 1 + loop.length;
    final loopLength = condition.length + 1 + loop.length + 3;
    bytesBuilder.add(_uint16(continueLength));
    bytesBuilder.add(_uint16(loopLength));
    bytesBuilder.add(condition);
    bytesBuilder.addByte(HTOpCode.whileStmt);
    bytesBuilder.add(loop);
    bytesBuilder.addByte(HTOpCode.skip);
    bytesBuilder.add(_int16(-loopLength));
    bytesBuilder.addByte(HTOpCode.endOfBlock);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitWhen(WhenStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    Uint8List? condition;
    if (stmt.condition != null) {
      condition = compileAST(stmt.condition!);
    }
    final cases = <Uint8List>[];
    final branches = <Uint8List>[];
    Uint8List? elseBranch;
    if (stmt.elseBranch != null) {
      elseBranch = compileAST(stmt.elseBranch!);
    }
    for (final ast in stmt.cases.keys) {
      final caseBytesBuilder = BytesBuilder();
      if (condition != null) {
        if (ast is CommaExpr) {
          caseBytesBuilder.addByte(WhenCaseTypeCode.eigherEquals);
          final bytes = visitCommaExpr(ast);
          caseBytesBuilder.add(bytes);
        } else if (ast is InOfExpr) {
          caseBytesBuilder.addByte(WhenCaseTypeCode.elementIn);
          Uint8List bytes;
          if (ast.valueOf) {
            final getValues = MemberExpr(ast.collection,
                IdentifierExpr(_lexicon.idCollectionValues, isLocal: false));
            bytes = compileAST(getValues, endOfExec: true);
          } else {
            bytes = compileAST(ast.collection, endOfExec: true);
          }
          caseBytesBuilder.add(bytes);
        } else {
          caseBytesBuilder.addByte(WhenCaseTypeCode.equals);
          final bytes = compileAST(ast, endOfExec: true);
          caseBytesBuilder.add(bytes);
        }
      } else {
        caseBytesBuilder.addByte(WhenCaseTypeCode.equals);
        final bytes = compileAST(ast, endOfExec: true);
        caseBytesBuilder.add(bytes);
      }
      cases.add(caseBytesBuilder.toBytes());
      final branchBytes = compileAST(stmt.cases[ast]!);
      branches.add(branchBytes);
    }
    bytesBuilder.addByte(HTOpCode.anchor);
    if (condition != null) {
      bytesBuilder.add(condition);
    }
    bytesBuilder.addByte(HTOpCode.whenStmt);
    bytesBuilder.addByte(condition != null ? 1 : 0);
    bytesBuilder.addByte(cases.length);
    var curBranchIp = 0;
    var caseJumpIps = List.filled(branches.length, 0);
    for (var i = 1; i < branches.length; ++i) {
      curBranchIp += branches[i - 1].length + 3;
      caseJumpIps[i] = curBranchIp;
    }
    curBranchIp += branches.last.length + 3;
    final endIp = curBranchIp + (elseBranch?.length ?? 0);
    // calculate the length of the code since the anchor,
    // for goto the specific location of branches.
    var offsetIp = (condition?.length ?? 0) + 3;
    // calculate the length of all cases end else jump code first
    for (final expr in cases) {
      offsetIp += expr.length + 3;
    }
    offsetIp += 3;
    // for each case, if true, will jump to a certain branch.
    for (var i = 0; i < cases.length; ++i) {
      final expr = cases[i];
      bytesBuilder.add(expr);
      bytesBuilder.addByte(HTOpCode.goto);
      bytesBuilder.add(_uint16(offsetIp + caseJumpIps[i]));
    }
    bytesBuilder.addByte(HTOpCode.goto);
    bytesBuilder.add(_uint16(offsetIp + curBranchIp));
    // for each branch, after execution, will jump to end of statement.
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
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.delete);
    bytesBuilder.addByte(DeletingTypeCode.local);
    bytesBuilder.add(_parseIdentifier(stmt.symbol));
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitDeleteMemberStmt(DeleteMemberStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.delete);
    bytesBuilder.addByte(DeletingTypeCode.member);
    final objectBytes = compileAST(stmt.object, endOfExec: true);
    bytesBuilder.add(objectBytes);
    bytesBuilder.add(_parseIdentifier(stmt.key));
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitDeleteSubStmt(DeleteSubStmt stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.delete);
    bytesBuilder.addByte(DeletingTypeCode.sub);
    final objectBytes = compileAST(stmt.object, endOfExec: true);
    bytesBuilder.add(objectBytes);
    final keyBytes = compileAST(stmt.key, endOfExec: true);
    bytesBuilder.add(keyBytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitImportExportDecl(ImportExportDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_lineInfo(stmt.line, stmt.column));
    bytesBuilder.addByte(HTOpCode.importExportDecl);
    bytesBuilder.addByte(stmt.isExport ? 1 : 0); // bool: isExport
    bytesBuilder
        .addByte(stmt.isPreloadedModule ? 1 : 0); // bool: isPreloadedModule
    bytesBuilder.addByte(stmt.showList.length);
    for (final id in stmt.showList) {
      bytesBuilder.add(_parseIdentifier(id.id));
    }
    if (stmt.fromPath != null) {
      bytesBuilder.addByte(1); // bool: hasFromPath
      // use the normalized absolute name here instead of relative path
      bytesBuilder.add(_parseIdentifier(stmt.fullFromPath!));
    } else {
      bytesBuilder.addByte(0); // bool: hasFromPath
    }
    if (stmt.alias != null) {
      bytesBuilder.addByte(1); // bool: has alias id
      bytesBuilder.add(_parseIdentifier(stmt.alias!.id));
    } else {
      bytesBuilder.addByte(0); // bool: has alias id
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitNamespaceDecl(NamespaceDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.namespaceDecl);
    bytesBuilder.add(_parseIdentifier(stmt.id.id));
    if (stmt.classId != null) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_parseIdentifier(stmt.classId!));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
    final bytes = visitBlockStmt(stmt.definition);
    bytesBuilder.add(bytes);
    bytesBuilder.addByte(HTOpCode.endOfExec);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitTypeAliasDecl(TypeAliasDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.typeAliasDecl);
    bytesBuilder.add(_parseIdentifier(stmt.id.id));
    if (stmt.classId != null) {
      bytesBuilder.addByte(1); // bool: has class id
      bytesBuilder.add(_parseIdentifier(stmt.classId!));
    } else {
      bytesBuilder.addByte(0); // bool: has class id
    }
    bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
    // do not use visitTypeExpr here because the value could be a function type
    final bytes = compileAST(stmt.typeValue);
    bytesBuilder.add(bytes);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitVarDecl(VarDecl stmt) {
    final bytesBuilder = BytesBuilder();
    // Only const declaration with a const expression as initializer
    // can be compiled into a const declaration,
    // otherwise will be compiled as a normal variable declaration,
    // with a static warning output.
    if (stmt.isConstValue) {
      bytesBuilder.addByte(HTOpCode.constDecl);
      bytesBuilder.add(_parseIdentifier(stmt.id.id));
      if (stmt.classId != null) {
        bytesBuilder.addByte(1); // bool: has class id
        bytesBuilder.add(_parseIdentifier(stmt.classId!));
      } else {
        bytesBuilder.addByte(0); // bool: has class id
      }
      bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
      late int type, index;
      if (stmt.value is bool) {
        type = HTConstantType.boolean.index;
        index = _currentConstantTable.addGlobalConstant<bool>(stmt.value);
      } else if (stmt.value is int) {
        type = HTConstantType.integer.index;
        index = _currentConstantTable.addGlobalConstant<int>(stmt.value);
      } else if (stmt.value is double) {
        type = HTConstantType.float.index;
        index = _currentConstantTable.addGlobalConstant<double>(stmt.value);
      } else if (stmt.value is String) {
        type = HTConstantType.string.index;
        index = _currentConstantTable.addGlobalConstant<String>(stmt.value);
      }
      bytesBuilder.addByte(type);
      bytesBuilder.add(_uint16(index));
    } else {
      bytesBuilder.addByte(HTOpCode.varDecl);
      bytesBuilder.add(_parseIdentifier(stmt.id.id));
      if (stmt.classId != null) {
        bytesBuilder.addByte(1); // bool: has class id
        bytesBuilder.add(_parseIdentifier(stmt.classId!));
      } else {
        bytesBuilder.addByte(0); // bool: has class id
      }
      bytesBuilder.addByte(stmt.isField ? 1 : 0);
      bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
      bytesBuilder.addByte(stmt.isStatic ? 1 : 0);
      bytesBuilder.addByte(stmt.isMutable ? 1 : 0);
      bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
      bytesBuilder.addByte(stmt.lateFinalize ? 1 : 0);
      bytesBuilder.addByte(stmt.lateInitialize ? 1 : 0);
      if (stmt.declType != null) {
        bytesBuilder.addByte(1); // bool: has type decl
        final typeDecl = compileAST(stmt.declType!);
        bytesBuilder.add(typeDecl);
      } else {
        bytesBuilder.addByte(0); // bool: has type decl
      }
      if (stmt.initializer != null) {
        bytesBuilder.addByte(1); // bool: has initializer
        final initializer = compileAST(stmt.initializer!, endOfExec: true);
        if (stmt.lateInitialize) {
          bytesBuilder.add(_uint16(stmt.initializer!.line));
          bytesBuilder.add(_uint16(stmt.initializer!.column));
          bytesBuilder.add(_uint16(initializer.length));
        }
        bytesBuilder.add(initializer);
      } else {
        bytesBuilder.addByte(0); // bool: has initializer
      }
    }
    if (stmt.hasEndOfStmtMark) {
      bytesBuilder.addByte(HTOpCode.endOfStmt);
    }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitDestructuringDecl(DestructuringDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.destructuringDecl);
    bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
    bytesBuilder.addByte(stmt.ids.length);
    for (final id in stmt.ids.keys) {
      bytesBuilder.add(_parseIdentifier(id.id));
      final typeExpr = stmt.ids[id];
      if (typeExpr != null) {
        bytesBuilder.addByte(1); // bool: has type decl
        final typeDecl = compileAST(typeExpr);
        bytesBuilder.add(typeDecl);
      } else {
        bytesBuilder.addByte(0); // bool: has type decl
      }
    }
    bytesBuilder.addByte(stmt.isVector ? 1 : 0);
    bytesBuilder.addByte(stmt.isMutable ? 1 : 0);
    final initializer = compileAST(stmt.initializer, endOfExec: true);
    bytesBuilder.add(initializer);
    bytesBuilder.addByte(HTOpCode.endOfStmt);
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitParamDecl(ParamDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(_parseIdentifier(stmt.id.id));
    bytesBuilder.addByte(stmt.isOptional ? 1 : 0);
    bytesBuilder.addByte(stmt.isVariadic ? 1 : 0);
    bytesBuilder.addByte(stmt.isNamed ? 1 : 0);
    Uint8List? typeDecl;
    if (stmt.declType != null) {
      typeDecl = compileAST(stmt.declType!);
    }
    if (typeDecl != null) {
      bytesBuilder.addByte(1); // bool: has type decl
      bytesBuilder.add(typeDecl);
    } else {
      bytesBuilder.addByte(0); // bool: has type decl
    }
    Uint8List? initializer;
    if (stmt.initializer != null) {
      initializer = compileAST(stmt.initializer!, endOfExec: true);
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
    bytesBuilder.add(_parseIdentifier(stmt.callee.id));
    if (stmt.key != null) {
      bytesBuilder.addByte(1); // bool: has constructor name
      bytesBuilder.add(_parseIdentifier(stmt.key!.id));
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
    // TODO: generic param
    if (stmt.category != FunctionCategory.literal) {
      bytesBuilder.addByte(HTOpCode.funcDecl);
      // funcBytesBuilder.addByte(HTOpCode.funcDecl);
      bytesBuilder.add(_parseIdentifier(stmt.internalName));
      if (stmt.id != null) {
        bytesBuilder.addByte(1); // bool: hasId
        bytesBuilder.add(_parseIdentifier(stmt.id!.id));
      } else {
        bytesBuilder.addByte(0); // bool: hasId
      }
      if (stmt.classId != null) {
        bytesBuilder.addByte(1); // bool: hasClassId
        bytesBuilder.add(_parseIdentifier(stmt.classId!));
      } else {
        bytesBuilder.addByte(0); // bool: hasClassId
      }
      if (stmt.externalTypeId != null) {
        bytesBuilder.addByte(1); // bool: hasExternalTypedef
        bytesBuilder.add(_parseIdentifier(stmt.externalTypeId!));
      } else {
        bytesBuilder.addByte(0); // bool: hasExternalTypedef
      }
      bytesBuilder.addByte(stmt.category.index);
      bytesBuilder.addByte(stmt.isAsync ? 1 : 0);
      bytesBuilder.addByte(stmt.isField ? 1 : 0);
      bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
      bytesBuilder.addByte(stmt.isStatic ? 1 : 0);
      bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
      bytesBuilder.addByte(stmt.isConstValue ? 1 : 0);
    } else {
      bytesBuilder.addByte(HTOpCode.local);
      bytesBuilder.addByte(HTValueTypeCode.function);
      bytesBuilder.add(_parseIdentifier(stmt.internalName));
      if (stmt.externalTypeId != null) {
        bytesBuilder.addByte(1);
        bytesBuilder.add(_parseIdentifier(stmt.externalTypeId!));
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
    if (stmt.returnType != null) {
      bytesBuilder.addByte(1); // bool: hasReturnType
      // use compileAst here because there are multiple types of typeExpr
      final bytes = compileAST(stmt.returnType!);
      bytesBuilder.add(bytes);
    } else {
      bytesBuilder.addByte(0); // bool: hasReturnType
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
      final body = compileAST(stmt.definition!);
      bytesBuilder.add(_uint16(body.length + 1)); // definition bytes length
      bytesBuilder.add(body);
      bytesBuilder.addByte(HTOpCode.endOfFunc);
    } else {
      bytesBuilder.addByte(0); // bool: has no definition
    }
    // if (stmt.category != FunctionCategory.literal && !stmt.isField) {
    //   bytesBuilder.addByte(HTOpCode.endOfStmt);
    // }
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitClassDecl(ClassDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.classDecl);
    bytesBuilder.add(_parseIdentifier(stmt.id.id));
    // TODO: generic param
    bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
    bytesBuilder.addByte(stmt.isAbstract ? 1 : 0);
    bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
    bytesBuilder.addByte(stmt.hasUserDefinedConstructor ? 1 : 0);
    Uint8List? superType;
    if (stmt.superType != null) {
      superType = compileAST(stmt.superType!);
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
    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitEnumDecl(EnumDecl stmt) {
    final bytesBuilder = BytesBuilder();
    if (!stmt.isExternal) {
      bytesBuilder.addByte(HTOpCode.classDecl);
      bytesBuilder.add(_parseIdentifier(stmt.id.id));
      bytesBuilder.addByte(stmt.isExternal ? 1 : 0);
      bytesBuilder.addByte(0); // bool: is abstract
      bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
      bytesBuilder.addByte(1); // bool: has user defined constructor
      bytesBuilder.addByte(0); // bool: has super class
      bytesBuilder.addByte(1); // bool: is enum

      final valueId = '${_lexicon.privatePrefix}${Semantic.name}';
      final value = VarDecl(IdentifierExpr(valueId), classId: stmt.id.id);
      final valueBytes = visitVarDecl(value);
      bytesBuilder.add(valueBytes);

      final ctorParam = ParamDecl(IdentifierExpr(Semantic.name));
      final ctorDef = AssignExpr(IdentifierExpr(valueId), _lexicon.assign,
          IdentifierExpr(Semantic.name));
      final constructor = FuncDecl(
          '${InternalIdentifier.namedConstructorPrefix}${_lexicon.privatePrefix}',
          id: IdentifierExpr(_lexicon.privatePrefix),
          classId: stmt.id.id,
          paramDecls: [ctorParam],
          minArity: 1,
          maxArity: 1,
          definition: ctorDef,
          category: FunctionCategory.constructor);
      final ctorBytes = visitFuncDecl(constructor);
      bytesBuilder.add(ctorBytes);

      final toStringDef = ASTStringInterpolation(
          '${stmt.id.id}${_lexicon.memberGet}${_lexicon.stringInterpolationStart}0${_lexicon.stringInterpolationEnd}',
          _lexicon.stringStart1,
          _lexicon.stringEnd1,
          [IdentifierExpr(valueId)]);
      final toStringFunc = FuncDecl(_lexicon.idToString,
          id: IdentifierExpr(_lexicon.idToString),
          classId: stmt.id.id,
          hasParamDecls: true,
          paramDecls: [],
          definition: toStringDef);
      final toStringBytes = visitFuncDecl(toStringFunc);
      bytesBuilder.add(toStringBytes);

      final itemList = <ASTNode>[];
      for (final item in stmt.enumerations) {
        itemList.add(item);
        final itemInit = CallExpr(
            MemberExpr(stmt.id,
                IdentifierExpr(_lexicon.privatePrefix, isLocal: false)),
            positionalArgs: [
              ASTLiteralString(
                  item.id, _lexicon.stringStart1, _lexicon.stringEnd1)
            ]);
        final itemDecl = VarDecl(item,
            classId: stmt.classId,
            initializer: itemInit,
            isStatic: true,
            lateInitialize: true);
        final itemBytes = visitVarDecl(itemDecl);
        bytesBuilder.add(itemBytes);
      }

      final valuesInit = ListExpr(itemList);
      final valuesDecl = VarDecl(IdentifierExpr(_lexicon.idCollectionValues),
          classId: stmt.classId,
          initializer: valuesInit,
          isStatic: true,
          lateInitialize: true);
      final valuesBytes = visitVarDecl(valuesDecl);
      bytesBuilder.add(valuesBytes);

      bytesBuilder.addByte(HTOpCode.endOfExec);
    } else {
      bytesBuilder.addByte(HTOpCode.externalEnumDecl);
      bytesBuilder.add(_parseIdentifier(stmt.id.id));
      bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
    }

    return bytesBuilder.toBytes();
  }

  @override
  Uint8List visitStructDecl(StructDecl stmt) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.addByte(HTOpCode.structDecl);
    bytesBuilder.add(_parseIdentifier(stmt.id.id));
    bytesBuilder.addByte(stmt.isTopLevel ? 1 : 0);
    if (stmt.prototypeId != null) {
      bytesBuilder.addByte(1); // bool: hasPrototypeId
      bytesBuilder.add(_parseIdentifier(stmt.prototypeId!.id));
    } else {
      bytesBuilder.addByte(0); // bool: hasPrototypeId
    }
    // bytesBuilder.addByte(stmt.lateInitialize ? 1 : 0);
    final staticFields = <StructObjField>[];
    final fields = <StructObjField>[];
    for (final node in stmt.definition) {
      ASTNode initializer;
      if (node is FuncDecl) {
        FuncDecl initializer = node;
        final field = StructObjField(
            key: IdentifierExpr(
              initializer.internalName,
              isLocal: false,
            ),
            fieldValue: initializer);
        node.isStatic ? staticFields.add(field) : fields.add(field);
      } else if (node is VarDecl) {
        initializer = node.initializer ?? ASTLiteralNull();
        final field = StructObjField(
            key: IdentifierExpr(
              node.id.id,
              isLocal: false,
            ),
            fieldValue: initializer);
        node.isStatic ? staticFields.add(field) : fields.add(field);
      }
      // Other node type is ignored.
    }
    final staticBytes =
        compileAST(StructObjExpr(staticFields), endOfExec: true);
    final structBytes = compileAST(
        StructObjExpr(fields,
            id: IdentifierExpr(
              stmt.id.id,
              isLocal: false,
            ),
            prototypeId: stmt.prototypeId),
        endOfExec: true);
    bytesBuilder.add(_uint16(staticBytes.length));
    bytesBuilder.add(staticBytes);
    bytesBuilder.add(_uint16(structBytes.length));
    bytesBuilder.add(structBytes);
    return bytesBuilder.toBytes();
  }
}
