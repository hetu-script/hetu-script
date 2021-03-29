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

class _InterpreterState {
  int ip, line, column;
  String moduleName;
  String? symbol, className;
  dynamic value;
  ReferrenceType refType;
  HTNamespace namespace;

  // List<dynamic>

  _InterpreterState(this.ip, this.line, this.column, this.moduleName, this.symbol, this.className, this.value,
      this.refType, this.namespace);
}

class Hetu extends Interpreter {
  static var _anonymousScriptIndex = 0;

  final _modules = <String, BytesReader>{};
  late BytesReader _curCode;

  var _curLine = 0;
  @override
  int get curLine => _curLine;
  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;
  late String _curModuleName;
  @override
  String get curModuleName => _curModuleName;
  String? _curSymbol;
  String? _curClassName;
  dynamic _curValue; // local value
  var _curRefType = ReferrenceType.normal;

  final _savedStates = <_InterpreterState>[];

  var _regIndex = 0;
  final _registers = List<dynamic>.filled(16, null, growable: true);

  /// break 指令将会跳回最近的一个loop point
  final _loops = <LoopInfo>[];

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  Hetu({HTErrorHandler? errorHandler, HTModuleHandler? moduleHandler})
      : super(errorHandler: errorHandler, moduleHandler: moduleHandler) {
    _curNamespace = global = HTNamespace(this, id: HTLexicon.global);
  }

  @override
  Future<dynamic> eval(String content,
      {String? moduleName,
      ParseStyle style = ParseStyle.module,
      bool debugMode = true,
      HTNamespace? namespace,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) async {
    if (content.isEmpty) throw HTErrorEmpty(moduleName ?? '');

    _curModuleName = moduleName ?? (HTLexicon.anonymousScript + (_anonymousScriptIndex++).toString());

    final compiler = Compiler();

    try {
      final tokens = Lexer().lex(content, _curModuleName);
      final bytes = await compiler.compile(tokens, this, _curModuleName, style: style, debugMode: debugMode);
      _curCode = _modules[_curModuleName] = BytesReader(bytes);

      var result = execute(namespace: namespace ?? global);
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
              '${e.message}\nHetu call stack:\n$callStack', e.type, _curModuleName, curLine, curColumn);
        } else {
          newErr = HTInterpreterError(
              '$e\nHetu call stack:\n$callStack', HTErrorType.other, _curModuleName, curLine, curColumn);
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
      final tokens = Lexer().lex(content, _curModuleName);
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
              '${e.message}\nHetu call stack:\n$callStack', e.type, _curModuleName, curLine, curColumn);
        } else {
          newErr = HTInterpreterError(
              '$e\nHetu call stack:\n$callStack', HTErrorType.other, _curModuleName, curLine, curColumn);
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

  /// 从 [ip?] 位置开始解释，遇到 [OP.endOfExec] 后返回当前值。
  /// 如果之前 namespace
  /// 如果之前 [closure != null] 会回到之前的命名空间
  /// 如果之前 [ip != null] 会回到执行前的 [ip] 位置
  dynamic execute({String? moduleName, int? ip, HTNamespace? namespace}) {
    _savedStates.add(_InterpreterState(
      _curCode.ip,
      _curLine,
      _curColumn,
      _curModuleName,
      _curSymbol,
      _curClassName,
      _curValue,
      _curRefType,
      _curNamespace,
    ));

    var changedCode = false;

    if (moduleName != null && (_curModuleName != moduleName)) {
      changedCode = true;
      _curCode = _modules[moduleName]!;
    }
    if (ip != null) {
      _curCode.ip = ip;
      ++_regIndex;

      if (_registers.length <= _regIndex * 16) _registers.length += 16;
    }
    if (namespace != null) {
      _curNamespace = namespace;
    }

    final result = _execute();

    final state = _savedStates.last;

    _curLine = state.line;
    _curColumn = state.column;
    _curSymbol = state.symbol;
    _curClassName = state.className;
    _curValue = state.value;
    _curRefType = state.refType;
    _curNamespace = state.namespace;

    if (changedCode) {
      _curModuleName = state.moduleName;
      _curCode = _modules[_curModuleName]!;
    }

    if (ip != null) {
      --_regIndex;
      _curCode.ip = state.ip;
    }

    _savedStates.removeLast();

    return result;
  }

  dynamic _execute() {
    var instruction = _curCode.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          _curCode.readUint32();
          break;
        case HTOpCode.version:
          final major = _curCode.read();
          final minor = _curCode.read();
          final patch = _curCode.readUint16();
          scriptVersion = HTVersion(major, minor, patch);
          break;
        case HTOpCode.debug:
          debugMode = _curCode.read() == 0 ? false : true;
          break;
        case HTOpCode.debugInfo:
          _curLine = _curCode.readUint16();
          _curColumn = _curCode.readUint16();
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          final index = _curCode.read();
          _storeRegVal(index, _curValue);
          break;
        case HTOpCode.goto:
          final distance = _curCode.readInt16();
          _curCode.ip += distance;
          break;
        // 循环开始，记录断点
        case HTOpCode.loopPoint:
          final endDistance = _curCode.readUint16();
          _loops.add(LoopInfo(_curCode.ip, _curCode.ip + endDistance, _curNamespace));
          break;
        case HTOpCode.breakLoop:
          _curCode.ip = _loops.last.endIp;
          _curNamespace = _loops.last.namespace;
          _loops.removeLast();
          break;
        case HTOpCode.continueLoop:
          _curCode.ip = _loops.last.startIp;
          _curNamespace = _loops.last.namespace;
          break;
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _curCode.readShortUtf8String();
          _curNamespace = HTNamespace(this, id: id, closure: _curNamespace);
          break;
        case HTOpCode.endOfBlock:
          _curNamespace = _curNamespace.closure!;
          break;
        // 语句结束
        case HTOpCode.endOfStmt:
          _curSymbol = null;
          break;
        case HTOpCode.endOfExec:
          return _curValue;
        case HTOpCode.constTable:
          final int64Length = _curCode.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _curCode.consts.intTable.add(_curCode.readInt64());
          }
          final float64Length = _curCode.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _curCode.consts.floatTable.add(_curCode.readFloat64());
          }
          final utf8StringLength = _curCode.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _curCode.consts.stringTable.add(_curCode.readUtf8String());
          }
          break;
        // 变量表
        case HTOpCode.declTable:
          var enumDeclLength = _curCode.readUint16();
          for (var i = 0; i < enumDeclLength; ++i) {
            _handleEnumDecl();
          }
          var funcDeclLength = _curCode.readUint16();
          for (var i = 0; i < funcDeclLength; ++i) {
            _handleFuncDecl();
          }
          var classDeclLength = _curCode.readUint16();
          for (var i = 0; i < classDeclLength; ++i) {
            _handleClassDecl();
          }
          var varDeclLength = _curCode.readUint16();
          for (var i = 0; i < varDeclLength; ++i) {
            _handleVarDecl();
          }
          break;
        case HTOpCode.ifStmt:
          bool condition = _curValue;
          final thenBranchLength = _curCode.readUint16();
          if (!condition) {
            _curCode.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          final hasCondition = _curCode.readBool();
          if (hasCondition && !_curValue) {
            _curCode.ip = _loops.last.endIp;
            _loops.removeLast();
          }
          break;
        case HTOpCode.doStmt:
          if (_curValue) {
            _curCode.ip = _loops.last.startIp;
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

      instruction = _curCode.read();
    }
  }

  // void _resolve() {}

  void _storeLocal() {
    final valueType = _curCode.read();
    switch (valueType) {
      case HTValueTypeCode.NULL:
        _curValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_curCode.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTValueTypeCode.int64:
        final index = _curCode.readUint16();
        _curValue = _curCode.consts.getInt64(index);
        break;
      case HTValueTypeCode.float64:
        final index = _curCode.readUint16();
        _curValue = _curCode.consts.getFloat64(index);
        break;
      case HTValueTypeCode.utf8String:
        final index = _curCode.readUint16();
        _curValue = _curCode.consts.getUtf8String(index);
        break;
      case HTValueTypeCode.symbol:
        _curSymbol = _curCode.readShortUtf8String();
        final isGetKey = _curCode.readBool();
        if (!isGetKey) {
          _curRefType = ReferrenceType.normal;
          _curValue = _curNamespace.memberGet(_curSymbol!, from: _curNamespace.fullName);
        } else {
          _curRefType = ReferrenceType.member;
          // reg[13] 是 object，reg[14] 是 key
          _curValue = _curSymbol;
        }
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = _curCode.readUint16();
        for (var i = 0; i < length; ++i) {
          final listItem = execute();
          list.add(listItem);
        }
        _curValue = list;
        break;
      case HTValueTypeCode.map:
        final map = {};
        final length = _curCode.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute();
          final value = execute();
          map[key] = value;
        }
        _curValue = map;
        break;
      case HTValueTypeCode.function:
        final id = _curCode.readShortUtf8String();

        final hasExternalTypedef = _curCode.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _curCode.readShortUtf8String();
        }

        final funcType = FunctionType.literal;
        final isVariadic = _curCode.readBool();
        final minArity = _curCode.read();
        final maxArity = _curCode.read();
        final paramDecls = _getParams(_curCode.read());

        HTTypeId? returnType;
        final hasType = _curCode.readBool();
        if (hasType) {
          returnType = _getTypeId();
        }

        int? definitionIp;
        final hasDefinition = _curCode.readBool();
        if (hasDefinition) {
          final length = _curCode.readUint16();
          definitionIp = _curCode.ip;
          _curCode.skip(length);
        }

        final func = HTBytesFunction(id, this, _curModuleName,
            className: _curClassName,
            funcType: funcType,
            externalTypedef: externalTypedef,
            paramDecls: paramDecls,
            returnType: returnType,
            definitionIp: definitionIp,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            context: _curNamespace);

        if (!hasExternalTypedef) {
          _curValue = func;
        } else {
          final externalFunc = unwrapExternalFunctionType(externalTypedef!, func);
          _curValue = externalFunc;
        }
        break;
      case HTValueTypeCode.typeid:
        _curValue = _getTypeId();
        break;
      default:
        throw HTErrorUnkownValueType(valueType);
    }
  }

  dynamic _getRegVal(int index) => _registers[(_regIndex * 16 + index)];

  void _storeRegVal(int index, dynamic value) => _registers[(_regIndex * 16 + index)] = value;

  void _assignCurRef(dynamic value) {
    switch (_curRefType) {
      case ReferrenceType.normal:
        _curNamespace.memberSet(_curSymbol!, value, from: _curNamespace.fullName);
        break;
      case ReferrenceType.member:
        final object = _getRegVal(HTRegIndex.unaryPostObject)!;
        final key = _getRegVal(HTRegIndex.unaryPostKey);
        // 如果是 Hetu 对象
        if (object is HTObject) {
          object.memberSet(key, value, from: _curNamespace.fullName);
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
        final object = _getRegVal(HTRegIndex.unaryPostObject);
        final key = _getRegVal(HTRegIndex.unaryPostKey);
        // 如果是 buildin 集合
        if ((object is List) || (object is Map)) {
          object[key] = value;
        }
        // 如果是 Hetu 对象
        else if (object is HTObject) {
          object.subSet(key, value, from: _curNamespace.fullName);
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
    final type = _curCode.read();
    final id = _curCode.readShortUtf8String();
    final loopLength = _curCode.readUint16();

    if (type == ForStmtType.keyIn) {
      if (object is! Iterable && object is! Map) {
        throw HTErrorIterable(_curSymbol!);
      } else {
        // 这里要直接获取声明，而不是变量的值
        final decl = _curNamespace.declarations[id]!;
        if (object is Iterable) {
          for (var value in object) {
            decl.assign(value);
            execute();
            _curCode.ip -= loopLength;
          }
          _curCode.skip(loopLength);
        } else if (object is Map) {
          for (var value in object.values) {
            decl.assign(value);
            execute();
            _curCode.ip -= loopLength;
          }
          _curCode.skip(loopLength);
        }
      }
    }
    //ForStmtType.valueOf
    else {
      if (object is! Map) {
        throw HTErrorIterable(_curSymbol!);
      } else {
        // 这里要直接获取声明，而不是变量的值
        final decl = _curNamespace.declarations[id]!;
        for (var value in object.values) {
          decl.assign(value);
          execute();
          _curCode.ip -= loopLength;
        }
        _curCode.skip(loopLength);
      }
    }
  }

  void _handleWhenStmt() {
    var condition = _curValue;
    final hasCondition = _curCode.readBool();

    final casesCount = _curCode.read();
    final branchesIpList = <int>[];
    final casesList = [];
    for (var i = 0; i < casesCount; ++i) {
      branchesIpList.add(_curCode.readUint16());
    }
    final elseBranchIp = _curCode.readUint16();
    final endIp = _curCode.readUint16();

    for (var i = 0; i < casesCount; ++i) {
      final value = execute();
      casesList.add(value);
    }

    final startIp = _curCode.ip;

    var index = -1;
    if (hasCondition) {
      index = casesList.indexOf(condition);
    }

    if (index != -1) {
      final distance = branchesIpList[index];
      _curCode.skip(distance);
      execute();
      _curCode.ip = startIp + endIp;
    } else {
      final distance = elseBranchIp;
      _curCode.skip(distance);
      execute();
    }
  }

  void _handleAssignOp(int opcode) {
    final right = _curCode.read();

    switch (opcode) {
      case HTOpCode.assign:
        _curValue = _getRegVal(right);
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignMultiply:
        final leftValue = _curValue;
        _curValue = leftValue * _getRegVal(right);
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignDevide:
        final leftValue = _curValue;
        _curValue = leftValue / _getRegVal(right);
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignAdd:
        final leftValue = _curValue;
        _curValue = leftValue + _getRegVal(right);
        _assignCurRef(_curValue);
        break;
      case HTOpCode.assignSubtract:
        final leftValue = _curValue;
        _curValue = leftValue - _getRegVal(right);
        _assignCurRef(_curValue);
        break;
    }
  }

  void _handleBinaryOp(int opcode) {
    final left = _curCode.read();
    final right = _curCode.read();

    switch (opcode) {
      case HTOpCode.logicalOr:
        _curValue = _getRegVal(left) || _getRegVal(right);
        break;
      case HTOpCode.logicalAnd:
        _curValue = _getRegVal(left) && _getRegVal(right);
        break;
      case HTOpCode.equal:
        _curValue = _getRegVal(left) == _getRegVal(right);
        break;
      case HTOpCode.notEqual:
        _curValue = _getRegVal(left) != _getRegVal(right);
        break;
      case HTOpCode.lesser:
        _curValue = _getRegVal(left) < _getRegVal(right);
        break;
      case HTOpCode.greater:
        _curValue = _getRegVal(left) > _getRegVal(right);
        break;
      case HTOpCode.lesserOrEqual:
        _curValue = _getRegVal(left) <= _getRegVal(right);
        break;
      case HTOpCode.greaterOrEqual:
        _curValue = _getRegVal(left) >= _getRegVal(right);
        break;
      case HTOpCode.typeIs:
        final typeLeft = typeof(_getRegVal(left));
        var typeRight = _getRegVal(right);
        if (typeRight is! HTTypeId) {
          throw HTErrorNotType(typeRight.toString());
        }
        _curValue = typeLeft.isA(typeRight);
        break;
      case HTOpCode.typeIsNot:
        final typeLeft = typeof(_getRegVal(left));
        var typeRight = _getRegVal(right);
        if (typeRight is! HTTypeId) {
          throw HTErrorNotType(typeRight.toString());
        }
        _curValue = typeLeft.isNotA(typeRight);
        break;
      case HTOpCode.add:
        _curValue = _getRegVal(left) + _getRegVal(right);
        break;
      case HTOpCode.subtract:
        _curValue = _getRegVal(left) - _getRegVal(right);
        break;
      case HTOpCode.multiply:
        _curValue = _getRegVal(left) * _getRegVal(right);
        break;
      case HTOpCode.devide:
        _curValue = _getRegVal(left) / _getRegVal(right);
        break;
      case HTOpCode.modulo:
        _curValue = _getRegVal(left) % _getRegVal(right);
        break;
      default:
      // throw HTErrorUndefinedBinaryOperator(_getRegVal(left).toString(), _getRegVal(right).toString(), opcode);
    }
  }

  void _handleUnaryPrefixOp(int op) {
    final objIndex = _curCode.read();
    final object = _getRegVal(objIndex);
    switch (op) {
      case HTOpCode.negative:
        _curValue = -object;
        break;
      case HTOpCode.logicalNot:
        _curValue = !object;
        break;
      case HTOpCode.preIncrement:
        _curValue = object + 1;
        _assignCurRef(_curValue);
        break;
      case HTOpCode.preDecrement:
        _curValue = object - 1;
        _assignCurRef(_curValue);
        break;
      default:
      // throw HTErrorUndefinedOperator(_getRegVal(left).toString(), _getRegVal(right).toString(), HTLexicon.add);
    }
  }

  void _handleCallExpr() {
    final objIndex = _curCode.read();
    var object = _getRegVal(objIndex);
    var positionalArgs = [];
    final positionalArgsLength = _curCode.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute();
      positionalArgs.add(arg);
    }

    var namedArgs = <String, dynamic>{};
    final namedArgsLength = _curCode.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _curCode.readShortUtf8String();
      final arg = execute();
      namedArgs[name] = arg;
    }

    // TODO: typeArgs
    var typeArgs = <HTTypeId>[];

    _curValue = call(object, positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
  }

  void _handleUnaryPostfixOp(int op) {
    switch (op) {
      case HTOpCode.memberGet:
        final objIndex = _curCode.read();
        var object = _getRegVal(objIndex);
        final objKey = _curCode.read();
        var key = _getRegVal(objKey);
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
          _curValue = object.memberGet(key, from: _curNamespace.fullName);
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
        final objIndex = _curCode.read();
        var object = _getRegVal(objIndex);
        final objKey = _curCode.read();
        var key = _getRegVal(objKey);
        // TODO: support script subget operator override
        // if (object is! List && object is! Map) {
        //   throw HTErrorSubGet(object.toString());
        // }
        _curValue = object[key];
        _curRefType = ReferrenceType.sub;
        break;
      case HTOpCode.call:
        _handleCallExpr();
        break;
      case HTOpCode.postIncrement:
        final objIndex = _curCode.read();
        var object = _getRegVal(objIndex);
        _curValue = object;
        final value = _getRegVal(objIndex);
        final newValue = value + 1;
        _assignCurRef(newValue);
        break;
      case HTOpCode.postDecrement:
        final objIndex = _curCode.read();
        var object = _getRegVal(objIndex);
        _curValue = object;
        final value = _getRegVal(objIndex);
        final newValue = value - 1;
        _assignCurRef(newValue);
        break;
    }
  }

  HTTypeId _getTypeId() {
    final id = _curCode.readShortUtf8String();

    final length = _curCode.read();

    final args = <HTTypeId>[];
    for (var i = 0; i < length; ++i) {
      args.add(_getTypeId());
    }

    final isNullable = _curCode.read() == 0 ? false : true;

    return HTTypeId(id, isNullable: isNullable, arguments: args);
  }

  void _handleVarDecl() {
    final id = _curCode.readShortUtf8String();

    final isDynamic = _curCode.readBool();
    final isExtern = _curCode.readBool();
    final isImmutable = _curCode.readBool();
    final isMember = _curCode.readBool();
    final isStatic = _curCode.readBool();

    HTTypeId? declType;
    final hasType = _curCode.readBool();
    if (hasType) {
      declType = _getTypeId();
    }

    int? initializerIp;
    final hasInitializer = _curCode.readBool();
    if (hasInitializer) {
      final length = _curCode.readUint16();
      initializerIp = _curCode.ip;
      _curCode.skip(length);
    }

    final decl = HTBytesDecl(id, this, _curModuleName,
        declType: declType,
        initializerIp: initializerIp,
        isDynamic: isDynamic,
        isExtern: isExtern,
        isImmutable: isImmutable,
        isMember: isMember,
        isStatic: isStatic);

    if (!isMember || isStatic) {
      _curNamespace.define(decl);
    } else {
      (_curNamespace as HTClass).defineInstance(decl);
    }
  }

  Map<String, HTBytesParamDecl> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTBytesParamDecl>{};

    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _curCode.readShortUtf8String();
      final isOptional = _curCode.readBool();
      final isNamed = _curCode.readBool();
      final isVariadic = _curCode.readBool();

      HTTypeId? declType;
      final hasType = _curCode.readBool();
      if (hasType) {
        declType = _getTypeId();
      }

      int? initializerIp;
      final hasInitializer = _curCode.readBool();
      if (hasInitializer) {
        final length = _curCode.readUint16();
        initializerIp = _curCode.ip;
        _curCode.skip(length);
      }

      paramDecls[id] = HTBytesParamDecl(id, this, _curModuleName,
          declType: declType,
          initializerIp: initializerIp,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }

    return paramDecls;
  }

  void _handleEnumDecl() {
    final id = _curCode.readShortUtf8String();
    final isExtern = _curCode.readBool();
    final length = _curCode.readUint16();

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < length; i++) {
      final id = _curCode.readShortUtf8String();
      defs[id] = HTEnumItem(i, id, HTTypeId(id));
    }

    final enumClass = HTEnum(id, defs, this, isExtern: isExtern);

    _curNamespace.define(HTDeclaration(id, value: enumClass));
  }

  void _handleFuncDecl() {
    final id = _curCode.readShortUtf8String();
    final declId = _curCode.readShortUtf8String();

    final hasExternalTypedef = _curCode.readBool();
    String? externalTypedef;
    if (hasExternalTypedef) {
      externalTypedef = _curCode.readShortUtf8String();
    }

    final funcType = FunctionType.values[_curCode.read()];
    final externType = ExternFunctionType.values[_curCode.read()];
    final isStatic = _curCode.readBool();
    final isConst = _curCode.readBool();
    final isVariadic = _curCode.readBool();

    final minArity = _curCode.read();
    final maxArity = _curCode.read();
    final paramDecls = _getParams(_curCode.read());

    HTTypeId? returnType;
    final hasType = _curCode.readBool();
    if (hasType) {
      returnType = _getTypeId();
    }

    int? definitionIp;
    final hasDefinition = _curCode.readBool();
    if (hasDefinition) {
      final length = _curCode.readUint16();
      definitionIp = _curCode.ip;
      _curCode.skip(length);
    }

    final func = HTBytesFunction(
      id,
      this,
      _curModuleName,
      declId: declId,
      className: _curClassName,
      funcType: funcType,
      externType: externType,
      externalTypedef: externalTypedef,
      paramDecls: paramDecls,
      returnType: returnType,
      definitionIp: definitionIp,
      isStatic: isStatic,
      isConst: isConst,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
    );

    if (!isStatic &&
        (funcType == FunctionType.getter || funcType == FunctionType.setter || funcType == FunctionType.method)) {
      (_curNamespace as HTClass).defineInstance(
          HTDeclaration(id, value: func, isExtern: func.externType != ExternFunctionType.none, isMember: true));
    } else {
      if (funcType != FunctionType.constructor) {
        func.context = _curNamespace;
      }
      _curNamespace
          .define(HTDeclaration(id, value: func, isExtern: func.externType != ExternFunctionType.none, isMember: true));
    }
  }

  void _handleClassDecl() {
    final id = _curCode.readShortUtf8String();
    _curClassName = id;

    final classType = ClassType.values[_curCode.read()];

    String? superClassId;
    final hasSuperClass = _curCode.readBool();
    if (hasSuperClass) {
      superClassId = _curCode.readShortUtf8String();
    }

    HTClass? superClass;
    if (id != HTLexicon.rootClass) {
      if (superClassId == null) {
        // TODO: Object基类
        // superClass = global.fetch(HTLexicon.rootClass);
      } else {
        superClass = _curNamespace.memberGet(superClassId, from: _curNamespace.fullName);
      }
    }

    final klass = HTClass(id, superClass, this, classType: classType, closure: _curNamespace);

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    _curNamespace.define(HTDeclaration(id, value: klass));

    execute(namespace: klass);

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

    _curClassName = null;
  }
}
