import 'dart:typed_data';

import 'compiler.dart';
import 'opcode.dart';
import 'bytes_reader.dart';
import 'bytes_declaration.dart';
import 'bytes_funciton.dart';
import '../interpreter.dart';
import '../type.dart';
import '../common.dart';
import '../lexicon.dart';
import '../lexer.dart';
import '../errors.dart';
import '../namespace.dart';
import '../declaration.dart';
import '../class.dart';
import '../extern_object.dart';
import '../object.dart';
import '../enum.dart';
import '../function.dart';
import '../plugin/moduleHandler.dart';
import '../plugin/errorHandler.dart';

mixin HetuRef {
  late final Hetu interpreter;
}

class LoopInfo {
  final int startIp;
  final int endIp;
  final HTNamespace namespace;
  LoopInfo(this.startIp, this.endIp, this.namespace);
}

class Hetu extends Interpreter {
  static var _anonymousScriptIndex = 0;

  final modules = <String, BytesReader>{};

  late BytesReader curCode;

  dynamic _curValue; // local value
  String? _curSymbol;
  String? _curClassName;

  final _register = List<dynamic>.filled(24, null, growable: false);

  var _curRefType = ReferrenceType.normal;

  /// break 指令将会跳回最近的一个loop point
  final _loops = <LoopInfo>[];

  Hetu({HTErrorHandler? errorHandler, HTModuleHandler? moduleHandler})
      : super(errorHandler: errorHandler, moduleHandler: moduleHandler);

  @override
  Future<dynamic> eval(
    String content, {
    String? fileName,
    ParseStyle style = ParseStyle.module,
    bool debugMode = true,
    HTNamespace? namespace,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) async {
    if (content.isEmpty) throw HTErrorEmpty(fileName ?? '');

    curModuleName = fileName ?? (HTLexicon.anonymousScript + (_anonymousScriptIndex++).toString());
    curNamespace = namespace ?? global;
    final compiler = Compiler();

    try {
      final tokens = Lexer().lex(content, curModuleName);
      final bytes = await compiler.compile(tokens, this, curModuleName, style: style, debugMode: debugMode);
      curCode = modules[curModuleName] = BytesReader(bytes);

      var result = execute(closure: curNamespace);
      if (style == ParseStyle.module && invokeFunc != null) {
        result = invoke(invokeFunc, positionalArgs: positionalArgs, namedArgs: namedArgs, errorHandled: true);
      }
      return result;
    } catch (e, stack) {
      var sb = StringBuffer();
      for (var funcName in HTFunction.callStack) {
        sb.writeln('  $funcName');
      }
      sb.writeln('\n$stack');
      var callStack = sb.toString();

      if (e is! HTInterpreterError) {
        HTInterpreterError newErr;
        if (e is HTParserError) {
          newErr = HTInterpreterError('${e.message}\nHetu call stack:\n$callStack', e.type, compiler.curModuleName,
              compiler.curLine, compiler.curColumn);
        } else if (e is HTError) {
          newErr = HTInterpreterError(
              '${e.message}\nHetu call stack:\n$callStack', e.type, curModuleName, curLine, curColumn);
        } else {
          newErr = HTInterpreterError(
              '$e\nHetu call stack:\n$callStack', HTErrorType.other, curModuleName, curLine, curColumn);
        }

        errorHandler.handle(newErr);
      } else {
        errorHandler.handle(e);
      }
    }
  }

  Future<Uint8List> compile(String content, String moduleName,
      {ParseStyle style = ParseStyle.module, bool debugMode = true}) async {
    final compiler = Compiler();
    final bytesBuilder = BytesBuilder();

    try {
      final tokens = Lexer().lex(content, curModuleName);
      final bytes = await compiler.compile(tokens, this, moduleName, style: style, debugMode: debugMode);

      bytesBuilder.add(bytes);
    } catch (e, stack) {
      var sb = StringBuffer();
      for (var funcName in HTFunction.callStack) {
        sb.writeln('  $funcName');
      }
      sb.writeln('\n$stack');
      var callStack = sb.toString();

      if (e is! HTInterpreterError) {
        HTInterpreterError newErr;
        if (e is HTParserError) {
          newErr = HTInterpreterError('${e.message}\nHetu call stack:\n$callStack', e.type, compiler.curModuleName,
              compiler.curLine, compiler.curColumn);
        } else if (e is HTError) {
          newErr = HTInterpreterError(
              '${e.message}\nHetu call stack:\n$callStack', e.type, curModuleName, curLine, curColumn);
        } else {
          newErr = HTInterpreterError(
              '$e\nHetu call stack:\n$callStack', HTErrorType.other, curModuleName, curLine, curColumn);
        }

        errorHandler.handle(newErr);
      } else {
        errorHandler.handle(e);
      }
    } finally {
      return bytesBuilder.toBytes();
    }
  }

  dynamic run(Uint8List code) {}

  /// 从 [ip] 位置开始解释，遇到 OP.endOfExec 后返回当前值。
  /// 返回时，指针会回到执行前的 ip 位置。并且会回到之前的命名空间。
  dynamic execute({int? ip, HTNamespace? closure}) {
    final savedIp = curCode.ip;
    final savedNamespace = curNamespace;

    if (ip != null) {
      curCode.ip = ip;
    }
    if (closure != null) {
      curNamespace = closure;
    }

    final result = _execute();

    if (ip != null) {
      curCode.ip = savedIp;
    }
    if (closure != null) {
      curNamespace = savedNamespace;
    }

    return result;
  }

  dynamic _execute() {
    var instruction = curCode.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          curCode.readUint32();
          break;
        case HTOpCode.version:
          final major = curCode.read();
          final minor = curCode.read();
          final patch = curCode.readUint16();
          scriptVersion = HTVersion(major, minor, patch);
          break;
        case HTOpCode.debug:
          debugMode = curCode.read() == 0 ? false : true;
          break;
        case HTOpCode.debugInfo:
          curLine = curCode.readUint16();
          curColumn = curCode.readUint16();
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          _storeRegister(curCode.read(), _curValue);
          break;
        case HTOpCode.goto:
          final distance = curCode.readInt16();
          curCode.ip += distance;
          break;
        // 循环开始，记录断点
        case HTOpCode.loopPoint:
          final endDistance = curCode.readUint16();
          _loops.add(LoopInfo(curCode.ip, curCode.ip + endDistance, curNamespace));
          break;
        case HTOpCode.breakLoop:
          curCode.ip = _loops.last.endIp;
          curNamespace = _loops.last.namespace;
          _loops.removeLast();
          break;
        case HTOpCode.continueLoop:
          curCode.ip = _loops.last.startIp;
          curNamespace = _loops.last.namespace;
          break;
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = curCode.readShortUtf8String();
          curNamespace = HTNamespace(this, id: id, closure: curNamespace);
          break;
        case HTOpCode.endOfBlock:
          curNamespace = curNamespace.closure!;
          break;
        // 语句结束
        case HTOpCode.endOfStmt:
          _curSymbol = null;
          break;
        case HTOpCode.endOfExec:
          return _curValue;
        case HTOpCode.constTable:
          final int64Length = curCode.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            curCode.consts.intTable.add(curCode.readInt64());
          }
          final float64Length = curCode.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            curCode.consts.floatTable.add(curCode.readFloat64());
          }
          final utf8StringLength = curCode.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            curCode.consts.stringTable.add(curCode.readUtf8String());
          }
          break;
        // 变量表
        case HTOpCode.declTable:
          var enumDeclLength = curCode.readUint16();
          for (var i = 0; i < enumDeclLength; ++i) {
            _handleEnumDecl();
          }
          var funcDeclLength = curCode.readUint16();
          for (var i = 0; i < funcDeclLength; ++i) {
            _handleFuncDecl();
          }
          var classDeclLength = curCode.readUint16();
          for (var i = 0; i < classDeclLength; ++i) {
            _handleClassDecl();
          }
          var varDeclLength = curCode.readUint16();
          for (var i = 0; i < varDeclLength; ++i) {
            _handleVarDecl();
          }
          break;
        case HTOpCode.ifStmt:
          bool condition = _curValue;
          final thenBranchLength = curCode.readUint16();
          if (!condition) {
            curCode.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          final hasCondition = curCode.readBool();
          if (hasCondition && !_curValue) {
            curCode.ip = _loops.last.endIp;
            _loops.removeLast();
          }
          break;
        case HTOpCode.doStmt:
          if (_curValue) {
            curCode.ip = _loops.last.startIp;
          }
          break;
        case HTOpCode.forStmt:
          _handleForStmt();
          break;
        case HTOpCode.whenStmt:
          _handleWhenStmt();
          break;
        case HTOpCode.assign:
        case HTOpCode.assignMultiply:
        case HTOpCode.assignDevide:
        case HTOpCode.assignAdd:
        case HTOpCode.assignSubtract:
          _handleAssignOp(instruction);
          break;
        case HTOpCode.logicalOr:
        case HTOpCode.logicalAnd:
        case HTOpCode.equal:
        case HTOpCode.notEqual:
        case HTOpCode.lesser:
        case HTOpCode.greater:
        case HTOpCode.lesserOrEqual:
        case HTOpCode.greaterOrEqual:
        case HTOpCode.typeIs:
        case HTOpCode.typeIsNot:
        case HTOpCode.add:
        case HTOpCode.subtract:
        case HTOpCode.multiply:
        case HTOpCode.devide:
        case HTOpCode.modulo:
          _handleBinaryOp(instruction);
          break;
        case HTOpCode.negative:
        case HTOpCode.logicalNot:
        case HTOpCode.preIncrement:
        case HTOpCode.preDecrement:
          _handleUnaryPrefixOp(instruction);
          break;
        case HTOpCode.memberGet:
        case HTOpCode.subGet:
        case HTOpCode.call:
        case HTOpCode.postIncrement:
        case HTOpCode.postDecrement:
          _handleUnaryPostfixOp(instruction);
          break;
        default:
          print('Unknown opcode: $instruction');
          break;
      }

      instruction = curCode.read();
    }
  }

  // void _resolve() {}

  void _storeLocal() {
    final valueType = curCode.read();
    switch (valueType) {
      case HTValueTypeCode.NULL:
        _curValue = null;
        break;
      case HTValueTypeCode.boolean:
        (curCode.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTValueTypeCode.int64:
        final index = curCode.readUint16();
        _curValue = curCode.consts.getInt64(index);
        break;
      case HTValueTypeCode.float64:
        final index = curCode.readUint16();
        _curValue = curCode.consts.getFloat64(index);
        break;
      case HTValueTypeCode.utf8String:
        final index = curCode.readUint16();
        _curValue = curCode.consts.getUtf8String(index);
        break;
      case HTValueTypeCode.symbol:
        _curSymbol = curCode.readShortUtf8String();
        final isGetKey = curCode.readBool();
        if (!isGetKey) {
          _curRefType = ReferrenceType.normal;
          _curValue = curNamespace.memberGet(_curSymbol!, from: curNamespace.fullName);
        } else {
          _curRefType = ReferrenceType.member;
          // reg[13] 是 object，reg[14] 是 key
          _curValue = _curSymbol;
        }
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = curCode.readUint16();
        for (var i = 0; i < length; ++i) {
          final listItem = execute();
          list.add(listItem);
        }
        _curValue = list;
        break;
      case HTValueTypeCode.map:
        final map = {};
        final length = curCode.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute();
          final value = execute();
          map[key] = value;
        }
        _curValue = map;
        break;
      case HTValueTypeCode.function:
        final id = curCode.readShortUtf8String();

        final hasExternalTypedef = curCode.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = curCode.readShortUtf8String();
        }

        final funcType = FunctionType.literal;
        final isVariadic = curCode.readBool();
        final minArity = curCode.read();
        final maxArity = curCode.read();
        final paramDecls = _getParams(curCode.read());

        HTTypeId? returnType;
        final hasType = curCode.readBool();
        if (hasType) {
          returnType = _getTypeId();
        }

        int? definitionIp;
        final hasDefinition = curCode.readBool();
        if (hasDefinition) {
          final length = curCode.readUint16();
          definitionIp = curCode.ip;
          curCode.skip(length);
        }

        _curValue = HTBytesFunction(id, this, curModuleName,
            className: _curClassName,
            funcType: funcType,
            externalTypedef: externalTypedef,
            paramDecls: paramDecls,
            returnType: returnType,
            definitionIp: definitionIp,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            context: curNamespace);
        break;
      case HTValueTypeCode.typeid:
        _curValue = _getTypeId();
        break;
      default:
        throw HTErrorUnkownValueType(valueType);
    }
  }

  void _storeRegister(int index, dynamic value) {
    // if (index > _register.length) {
    //   _register.length = index + 8;
    // }

    _register[index] = value;
  }

  void _assignCurRef(dynamic value) {
    switch (_curRefType) {
      case ReferrenceType.normal:
        curNamespace.memberSet(_curSymbol!, value, from: curNamespace.fullName);
        break;
      case ReferrenceType.member:
        final object = _register[HTRegIndex.unaryPostObject]!;
        final key = _register[HTRegIndex.unaryPostKey]!;
        // 如果是 Hetu 对象
        if (object is HTObject) {
          object.memberSet(key, value, from: curNamespace.fullName);
        }
        // 如果是 Dart 对象
        else {
          var typeid = object.runtimeType.toString();
          if (typeid.contains('<')) {
            typeid = typeid.substring(0, typeid.indexOf('<'));
          }
          var externClass = fetchExternalClass(typeid);
          externClass.instanceMemberSet(object, key, value);
        }
        break;
      case ReferrenceType.sub:
        final object = _register[HTRegIndex.unaryPostObject]!;
        final key = _register[HTRegIndex.unaryPostKey]!;
        // 如果是 buildin 集合
        if ((object is List) || (object is Map)) {
          object[key] = value;
        }
        // 如果是 Hetu 对象
        else if (object is HTObject) {
          object.subSet(key, value, from: curNamespace.fullName);
        }
        // 如果是 Dart 对象
        else {
          var typeid = object.runtimeType.toString();
          if (typeid.contains('<')) {
            typeid = typeid.substring(0, typeid.indexOf('<'));
          }
          var externClass = fetchExternalClass(typeid);
          externClass.instanceSubSet(object, key, value);
        }
        break;
    }
  }

  /// 只包括 for in & of，普通的 for 其实是 while
  void _handleForStmt() {
    final object = _curValue;
    final type = curCode.read();
    final id = curCode.readShortUtf8String();
    final loopLength = curCode.readUint16();

    if (type == ForStmtType.keyIn) {
      if (object is! Iterable && object is! Map) {
        throw HTErrorIterable(_curSymbol!);
      } else {
        // 这里要直接获取声明，而不是变量的值
        final decl = curNamespace.declarations[id]!;
        if (object is Iterable) {
          for (var value in object) {
            decl.assign(value);
            execute();
            curCode.ip -= loopLength;
          }
          curCode.skip(loopLength);
        } else if (object is Map) {
          for (var value in object.values) {
            decl.assign(value);
            execute();
            curCode.ip -= loopLength;
          }
          curCode.skip(loopLength);
        }
      }
    }
    //ForStmtType.valueOf
    else {
      if (object is! Map) {
        throw HTErrorIterable(_curSymbol!);
      } else {
        // 这里要直接获取声明，而不是变量的值
        final decl = curNamespace.declarations[id]!;
        for (var value in object.values) {
          decl.assign(value);
          execute();
          curCode.ip -= loopLength;
        }
        curCode.skip(loopLength);
      }
    }
  }

  void _handleWhenStmt() {
    var condition = _curValue;
    final hasCondition = curCode.readBool();

    final casesCount = curCode.read();
    final branchesIpList = <int>[];
    final casesList = [];
    for (var i = 0; i < casesCount; ++i) {
      branchesIpList.add(curCode.readUint16());
    }
    final elseBranchIp = curCode.readUint16();
    final endIp = curCode.readUint16();

    for (var i = 0; i < casesCount; ++i) {
      final value = execute();
      casesList.add(value);
    }

    final startIp = curCode.ip;

    var index = -1;
    if (hasCondition) {
      index = casesList.indexOf(condition);
    }

    if (index != -1) {
      final distance = branchesIpList[index];
      curCode.skip(distance);
      execute();
      curCode.ip = startIp + endIp;
    } else {
      final distance = elseBranchIp;
      curCode.skip(distance);
      execute();
    }
  }

  void _handleAssignOp(int opcode) {
    final right = curCode.read();

    switch (opcode) {
      case HTOpCode.assign:
        _curValue = _register[right];
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignMultiply:
        final leftValue = _curValue;
        _curValue = leftValue * _register[right];
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignDevide:
        final leftValue = _curValue;
        _curValue = leftValue / _register[right];
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignAdd:
        final leftValue = _curValue;
        _curValue = leftValue + _register[right];
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignSubtract:
        final leftValue = _curValue;
        _curValue = leftValue - _register[right];
        _assignCurRef(_curValue);
        break;
    }
  }

  void _handleBinaryOp(int opcode) {
    final left = curCode.read();
    final right = curCode.read();

    switch (opcode) {
      case HTOpCode.logicalOr:
        _curValue = _register[left] || _register[right];
        break;
      case HTOpCode.logicalAnd:
        _curValue = _register[left] && _register[right];
        break;
      case HTOpCode.equal:
        _curValue = _register[left] == _register[right];
        break;
      case HTOpCode.notEqual:
        _curValue = _register[left] != _register[right];
        break;
      case HTOpCode.lesser:
        _curValue = _register[left] < _register[right];
        break;
      case HTOpCode.greater:
        _curValue = _register[left] > _register[right];
        break;
      case HTOpCode.lesserOrEqual:
        _curValue = _register[left] <= _register[right];
        break;
      case HTOpCode.greaterOrEqual:
        _curValue = _register[left] >= _register[right];
        break;
      case HTOpCode.typeIs:
        final typeLeft = typeof(_register[left]);
        var typeRight = _register[right];
        if (typeRight is! HTTypeId) {
          throw HTErrorNotType(typeRight.toString());
        }
        _curValue = typeLeft.isA(typeRight);
        break;
      case HTOpCode.typeIsNot:
        final typeLeft = typeof(_register[left]);
        var typeRight = _register[right];
        if (typeRight is! HTTypeId) {
          throw HTErrorNotType(typeRight.toString());
        }
        _curValue = typeLeft.isNotA(typeRight);
        break;
      case HTOpCode.add:
        _curValue = _register[left] + _register[right];
        break;
      case HTOpCode.subtract:
        _curValue = _register[left] - _register[right];
        break;
      case HTOpCode.multiply:
        _curValue = _register[left] * _register[right];
        break;
      case HTOpCode.devide:
        _curValue = _register[left] / _register[right];
        break;
      case HTOpCode.modulo:
        _curValue = _register[left] % _register[right];
        break;
      default:
      // throw HTErrorUndefinedBinaryOperator(_register[left].toString(), _register[right].toString(), opcode);
    }
  }

  void _handleUnaryPrefixOp(int op) {
    switch (op) {
      case HTOpCode.negative:
        _curValue = -_curValue;
        break;
      case HTOpCode.logicalNot:
        _curValue = !_curValue;
        break;
      case HTOpCode.preIncrement:
        _curValue = ++_curValue;
        _assignCurRef(_curValue);
        break;
      case HTOpCode.preDecrement:
        _curValue = --_curValue;
        _assignCurRef(_curValue);
        break;
      default:
      // throw HTErrorUndefinedOperator(_register[left].toString(), _register[right].toString(), HTLexicon.add);
    }
  }

  void _handleCallExpr(dynamic callee) {
    var positionalArgs = [];
    final positionalArgsLength = curCode.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute();
      positionalArgs.add(arg);
    }

    var namedArgs = <String, dynamic>{};
    final namedArgsLength = curCode.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = curCode.readShortUtf8String();
      final arg = execute();
      namedArgs[name] = arg;
    }

    // TODO: typeArgs
    var typeArgs = <HTTypeId>[];

    _curValue = call(callee, positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
  }

  void _handleUnaryPostfixOp(int op) {
    switch (op) {
      case HTOpCode.memberGet:
        final objIndex = curCode.read();
        var object = _register[objIndex];
        final objKey = curCode.read();
        var key = _register[objKey];
        if (object is num) {
          object = HTNumber(object);
        } else if (object is bool) {
          object = HTBoolean(object);
        } else if (object is String) {
          object = HTString(object);
        } else if (object is List) {
          object = HTList(object);
        } else if (object is Map) {
          object = HTMap(object);
        }

        if ((object is HTObject)) {
          _curValue = object.memberGet(key, from: curNamespace.fullName);
        }
        //如果是Dart对象
        else {
          var typeid = object.runtimeType.toString();
          if (typeid.contains('<')) {
            typeid = typeid.substring(0, typeid.indexOf('<'));
          }
          final externClass = fetchExternalClass(typeid);
          _curValue = externClass.instanceMemberGet(object, key);
        }
        break;
      case HTOpCode.subGet:
        final objIndex = curCode.read();
        var object = _register[objIndex];
        final objKey = curCode.read();
        var key = _register[objKey];
        if (object is! List && object is! Map) {
          throw HTErrorSubGet(object.toString());
        }
        _curValue = object[key];
        _curRefType = ReferrenceType.sub;
        break;
      case HTOpCode.call:
        final objIndex = curCode.read();
        var object = _register[objIndex];
        _handleCallExpr(object);
        break;
      case HTOpCode.postIncrement:
        final objIndex = curCode.read();
        var object = _register[objIndex];
        _curValue = object;
        final newValue = _register[objIndex] += 1;
        _assignCurRef(newValue);
        break;
      case HTOpCode.postDecrement:
        final objIndex = curCode.read();
        var object = _register[objIndex];
        _curValue = object;
        final newValue = _register[objIndex] -= 1;
        _assignCurRef(newValue);
        break;
    }
  }

  HTTypeId _getTypeId() {
    final id = curCode.readShortUtf8String();

    final length = curCode.read();

    final args = <HTTypeId>[];
    for (var i = 0; i < length; ++i) {
      args.add(_getTypeId());
    }

    final isNullable = curCode.read() == 0 ? false : true;

    return HTTypeId(id, isNullable: isNullable, arguments: args);
  }

  void _handleVarDecl() {
    final id = curCode.readShortUtf8String();

    final isDynamic = curCode.readBool();
    final isExtern = curCode.readBool();
    final isImmutable = curCode.readBool();
    final isMember = curCode.readBool();
    final isStatic = curCode.readBool();

    HTTypeId? declType;
    final hasType = curCode.readBool();
    if (hasType) {
      declType = _getTypeId();
    }

    int? initializerIp;
    final hasInitializer = curCode.readBool();
    if (hasInitializer) {
      final length = curCode.readUint16();
      initializerIp = curCode.ip;
      curCode.skip(length);
    }

    final decl = HTBytesDecl(id, this, curModuleName,
        declType: declType,
        initializerIp: initializerIp,
        isDynamic: isDynamic,
        isExtern: isExtern,
        isImmutable: isImmutable,
        isMember: isMember,
        isStatic: isStatic);

    if (!isMember || isStatic) {
      curNamespace.define(decl);
    } else {
      (curNamespace as HTClass).defineInstance(decl);
    }
  }

  Map<String, HTBytesParamDecl> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTBytesParamDecl>{};

    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = curCode.readShortUtf8String();
      final isOptional = curCode.readBool();
      final isNamed = curCode.readBool();
      final isVariadic = curCode.readBool();

      HTTypeId? declType;
      final hasType = curCode.readBool();
      if (hasType) {
        declType = _getTypeId();
      }

      int? initializerIp;
      final hasInitializer = curCode.readBool();
      if (hasInitializer) {
        final length = curCode.readUint16();
        initializerIp = curCode.ip;
        curCode.skip(length);
      }

      paramDecls[id] = HTBytesParamDecl(id, this, curModuleName,
          declType: declType,
          initializerIp: initializerIp,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }

    return paramDecls;
  }

  void _handleEnumDecl() {
    final id = curCode.readShortUtf8String();
    final isExtern = curCode.readBool();
    final length = curCode.readUint16();

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < length; i++) {
      final id = curCode.readShortUtf8String();
      defs[id] = HTEnumItem(i, id, HTTypeId(id));
    }

    final enumClass = HTEnum(id, defs, this, isExtern: isExtern);

    curNamespace.define(HTDeclaration(id, value: enumClass));
  }

  void _handleFuncDecl() {
    final id = curCode.readShortUtf8String();

    final hasExternalTypedef = curCode.readBool();
    String? externalTypedef;
    if (hasExternalTypedef) {
      externalTypedef = curCode.readShortUtf8String();
    }

    final funcType = FunctionType.values[curCode.read()];
    final isExtern = curCode.readBool();
    final isStatic = curCode.readBool();
    final isConst = curCode.readBool();
    final isVariadic = curCode.readBool();

    final minArity = curCode.read();
    final maxArity = curCode.read();
    final paramDecls = _getParams(curCode.read());

    HTTypeId? returnType;
    final hasType = curCode.readBool();
    if (hasType) {
      returnType = _getTypeId();
    }

    int? definitionIp;
    final hasDefinition = curCode.readBool();
    if (hasDefinition) {
      final length = curCode.readUint16();
      definitionIp = curCode.ip;
      curCode.skip(length);
    }

    final func = HTBytesFunction(
      id,
      this,
      curModuleName,
      className: _curClassName,
      funcType: funcType,
      externalTypedef: externalTypedef,
      paramDecls: paramDecls,
      returnType: returnType,
      definitionIp: definitionIp,
      isExtern: isExtern,
      isStatic: isStatic,
      isConst: isConst,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
    );

    if (!isStatic &&
        (funcType == FunctionType.getter || funcType == FunctionType.setter || funcType == FunctionType.method)) {
      (curNamespace as HTClass).defineInstance(HTDeclaration(id, value: func, isExtern: func.isExtern, isMember: true));
    } else {
      if (funcType != FunctionType.constructor) {
        func.context = curNamespace;
      }
      curNamespace.define(HTDeclaration(id, value: func, isExtern: func.isExtern, isMember: true));
    }
  }

  void _handleClassDecl() {
    final id = curCode.readShortUtf8String();

    final classType = ClassType.values[curCode.read()];

    String? superClassId;
    final hasSuperClass = curCode.readBool();
    if (hasSuperClass) {
      superClassId = curCode.readShortUtf8String();
    }

    HTClass? superClass;
    if (id != HTLexicon.rootClass) {
      if (superClassId == null) {
        // TODO: Object基类
        // superClass = global.fetch(HTLexicon.rootClass);
      } else {
        superClass = curNamespace.memberGet(superClassId, from: curNamespace.fullName);
      }
    }

    final klass = HTClass(id, superClass, this, classType: classType, closure: curNamespace);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    curNamespace.define(HTDeclaration(id, value: klass));

    execute(closure: klass);

    // 继承所有父类的成员变量和方法，忽略掉已经被覆盖的那些
    var curSuper = superClass;
    while (curSuper != null) {
      for (final decl in curSuper.instanceDecls.values) {
        if (decl.id.startsWith(HTLexicon.underscore)) {
          continue;
        }
        klass.defineInstance(decl.clone(), error: false);
      }

      curSuper = curSuper.superClass;
    }
  }
}
