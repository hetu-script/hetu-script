import 'dart:typed_data';

import 'compiler.dart';
import 'opcode.dart';
import 'bytecode.dart';
import 'bytes_variable.dart';
import 'bytes_funciton.dart';
import '../interpreter.dart';
import '../type.dart';
import '../common.dart';
import '../lexicon.dart';
import '../lexer.dart';
import '../errors.dart';
import '../namespace.dart';
import '../variable.dart';
import '../class.dart';
import '../extern_object.dart';
import '../object.dart';
import '../enum.dart';
import '../function.dart';
import '../plugin/moduleHandler.dart';
import '../plugin/errorHandler.dart';
import '../extern_function.dart';

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

  late Compiler _compiler;

  final _modules = <String, Bytecode>{};

  var _curLine = 0;
  @override
  int get curLine => _curLine;
  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;
  late String _curModuleName;
  @override
  String get curModuleName => _curModuleName;

  late Bytecode _curCode;

  HTClass? _curClass;

  var _regIndex = 0;
  final _registers = List<dynamic>.filled(HTRegIdx.length, null, growable: true);

  int getRegIndex(int relative) => (_regIndex * HTRegIdx.length + relative);
  void _setRegVal(int index, dynamic value) => _registers[getRegIndex(index)] = value;
  dynamic _getRegVal(int index) => _registers[getRegIndex(index)];
  set _curValue(dynamic value) => _registers[getRegIndex(HTRegIdx.value)] = value;
  dynamic get _curValue => _registers[getRegIndex(HTRegIdx.value)];
  set _curSymbol(String? value) => _registers[getRegIndex(HTRegIdx.symbol)] = value;
  String? get _curSymbol => _registers[getRegIndex(HTRegIdx.symbol)];
  set _curObjectSymbol(String? value) => _registers[getRegIndex(HTRegIdx.objectSymbol)] = value;
  String? get _curObjectSymbol => _registers[getRegIndex(HTRegIdx.objectSymbol)];
  set _curRefType(ReferrenceType value) => _registers[getRegIndex(HTRegIdx.refType)] = value;
  ReferrenceType get _curRefType => _registers[getRegIndex(HTRegIdx.refType)] ?? ReferrenceType.normal;
  set _curLoopCount(int value) => _registers[getRegIndex(HTRegIdx.loopCount)] = value;
  int get _curLoopCount => _registers[getRegIndex(HTRegIdx.loopCount)] ?? 0;

  /// loop 信息以栈的形式保存
  /// break 指令将会跳回最近的一个 loop 的出口
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
      CodeType codeType = CodeType.module,
      bool debugMode = true,
      HTNamespace? namespace,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) async {
    if (content.isEmpty) throw HTErrorEmpty(moduleName ?? '');

    _compiler = Compiler(this);

    // a non-null version
    final name = moduleName ?? (HTLexicon.anonymousScript + (_anonymousScriptIndex++).toString());

    try {
      final tokens = Lexer().lex(content, name);
      final bytes = await _compiler.compile(tokens, this, name, codeType: codeType, debugMode: debugMode);

      _curCode = _modules[name] = Bytecode(bytes);
      _curModuleName = name;
      var result = execute(namespace: namespace ?? global);
      if (codeType == CodeType.module && invokeFunc != null) {
        result = invoke(invokeFunc, positionalArgs: positionalArgs, namedArgs: namedArgs, errorHandled: true);
      }

      return result;
    } catch (error, stack) {
      handleError(error, stack);
    }
  }

  @override
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      var func;
      if (className != null) {
        // 类的静态函数
        HTClass klass = global.fetch(className);
        final func = klass.memberGet(funcName);

        if (func is HTFunction) {
          return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
        } else {
          throw HTErrorCallable(funcName);
        }
      } else {
        func = global.fetch(funcName);
        if (func is HTFunction) {
          return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
        } else {
          HTErrorCallable(funcName);
        }
      }
    } catch (error, stack) {
      if (errorHandled) rethrow;

      handleError(error, stack);
    }
  }

  @override
  void handleError(Object error, [StackTrace? stack]) {
    var sb = StringBuffer();
    for (var funcName in HTFunction.callStack) {
      sb.writeln('  $funcName');
    }
    sb.writeln('\n$stack');
    var callStack = sb.toString();

    if (error is! HTInterpreterError) {
      HTInterpreterError itpErr;
      if (error is HTParserError) {
        itpErr = HTInterpreterError('${error.message}\nHetu call stack:\n$callStack\nDart call stack:\n', error.type,
            _compiler.curModuleName, _compiler.curLine, _compiler.curColumn);
      } else if (error is HTError) {
        itpErr = HTInterpreterError('${error.message}\nHetu call stack:\n$callStack\nDart call stack:\n', error.type,
            curModuleName, curLine, curColumn);
      } else {
        itpErr = HTInterpreterError('$error\nHetu call stack:\n$callStack\nDart call stack:\n', HTErrorType.other,
            curModuleName, curLine, curColumn);
      }

      errorHandler.handle(itpErr);
    } else {
      errorHandler.handle(error);
    }
  }

  Future<Uint8List> compile(String content, String moduleName,
      {CodeType codeType = CodeType.module, bool debugMode = true}) async {
    final bytesBuilder = BytesBuilder();

    try {
      final tokens = Lexer().lex(content, moduleName);
      final bytes = await _compiler.compile(tokens, this, moduleName, codeType: codeType, debugMode: debugMode);

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
          newErr = HTInterpreterError('${e.message}\nHetu call stack:\n$callStack\nDart call stack:\n', e.type,
              _compiler.curModuleName, _compiler.curLine, _compiler.curColumn);
        } else if (e is HTError) {
          newErr = HTInterpreterError('${e.message}\nHetu call stack:\n$callStack\nDart call stack:\n', e.type,
              curModuleName, curLine, curColumn);
        } else {
          newErr = HTInterpreterError('$e\nHetu call stack:\n$callStack\nDart call stack:\n', HTErrorType.other,
              curModuleName, curLine, curColumn);
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

  /// 从 [moduleName] 代码文件的 [ip] 字节位置开始解释
  /// 遇到 [OpCode.endOfExec] 或 [OpCode.endOfFunc] 后返回当前值。
  /// 如果 [moduleName != null] 会回到之前的代码文件
  /// 如果 [ip != null] 会回到之前的指令位置
  /// 如果 [namespace != null] 会回到之前的命名空间
  ///
  /// 一旦切换了moduleName，就会进入一个新的寄存器区域
  /// 每个寄存器区域有自己独立的一套临时变量
  /// 包括文件名，行列号，当前符号，当前值等等
  dynamic execute({String? moduleName, int? ip, HTNamespace? namespace}) {
    final savedModuleName = curModuleName;
    final savedIp = _curCode.ip;
    final savedNamespace = _curNamespace;

    var changedCode = false;
    var changedIp = false;
    if (moduleName != null && (curModuleName != moduleName)) {
      _curModuleName = moduleName;
      _curCode = _modules[moduleName]!;
      changedCode = true;
      changedIp = true;
    }
    if (ip != null && _curCode.ip != ip) {
      _curCode.ip = ip;
      changedIp = true;
    }
    if (namespace != null && _curNamespace != namespace) {
      _curNamespace = namespace;
    }

    if (changedIp) {
      ++_regIndex;
      if (_registers.length <= _regIndex * HTRegIdx.length) {
        _registers.length += HTRegIdx.length;
      }
    }

    final result = _execute();

    if (changedCode) {
      _curModuleName = savedModuleName;
      _curCode = _modules[_curModuleName]!;
    }

    if (changedIp) {
      _curCode.ip = savedIp;
      --_regIndex;
    }

    _curNamespace = savedNamespace;

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
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          final index = _curCode.read();
          _setRegVal(index, _curValue);
          break;
        case HTOpCode.goto:
          final distance = _curCode.readInt16();
          _curCode.ip += distance;
          break;
        case HTOpCode.debugInfo:
          _curLine = _curCode.readUint16();
          _curColumn = _curCode.readUint16();
          break;
        case HTOpCode.objectSymbol:
          _curObjectSymbol = _curSymbol;
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
          _curLoopCount -= 1;
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
        case HTOpCode.endOfFunc:
          final loopCount = _curLoopCount;
          for (var i = 0; i < loopCount; ++i) {
            _loops.removeLast();
          }
          return _curValue;
        case HTOpCode.constTable:
          final int64Length = _curCode.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _curCode.addInt(_curCode.readInt64());
          }
          final float64Length = _curCode.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _curCode.addConstFloat(_curCode.readFloat64());
          }
          final utf8StringLength = _curCode.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _curCode.addConstString(_curCode.readUtf8String());
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
        _curValue = _curCode.getInt64(index);
        break;
      case HTValueTypeCode.float64:
        final index = _curCode.readUint16();
        _curValue = _curCode.getFloat64(index);
        break;
      case HTValueTypeCode.utf8String:
        final index = _curCode.readUint16();
        _curValue = _curCode.getUtf8String(index);
        break;
      case HTValueTypeCode.symbol:
        _curSymbol = _curCode.readShortUtf8String();
        final isGetKey = _curCode.readBool();
        if (!isGetKey) {
          _curRefType = ReferrenceType.normal;
          _curValue = _curNamespace.fetch(_curSymbol!, from: _curNamespace.fullName);
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

        final func = HTBytesFunction(id, this, curModuleName,
            classId: _curClass?.id,
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

  void _assignCurRef(dynamic value) {
    switch (_curRefType) {
      case ReferrenceType.normal:
        _curNamespace.assign(_curSymbol!, value, from: _curNamespace.fullName);
        break;
      case ReferrenceType.member:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = _getRegVal(HTRegIdx.postfixKey);
        if (object == null || object == HTObject.NULL) {
          throw HTErrorNullObject(_curObjectSymbol!);
        }
        // 如果是 Hetu 对象
        if (object is HTObject) {
          object.memberSet(key!, value, from: _curNamespace.fullName);
        }
        // 如果是 Dart 对象
        else {
          var typeString = object.runtimeType.toString();
          final typeid = HTTypeId.parse(typeString);
          var externClass = fetchExternalClass(typeid.id);
          externClass.instanceMemberSet(object, key!, value);
        }
        break;
      case ReferrenceType.sub:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = _getRegVal(HTRegIdx.postfixKey);
        if (object == null || object == HTObject.NULL) {
          throw HTErrorNullObject(object);
        }
        // 如果是 buildin 集合
        if ((object is List) || (object is Map)) {
          object[key] = value;
        }
        // 如果是 Hetu 对象
        else if (object is HTObject) {
          object.subSet(key, value);
        }
        // 如果是 Dart 对象
        else {
          var typeString = object.runtimeType.toString();
          final typeid = HTTypeId.parse(typeString);
          var externClass = fetchExternalClass(typeid.id);
          externClass.instanceSubSet(object, key!, value);
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
        final decl = _curNamespace.declarations[id] as HTVariable;
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
        final decl = _curNamespace.declarations[id] as HTVariable;
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
      if (elseBranchIp > 0) {
        final distance = elseBranchIp;
        _curCode.skip(distance);
        execute();
      }
    }
  }

  void _handleAssignOp(int opcode) {
    switch (opcode) {
      case HTOpCode.assign:
        final value = _getRegVal(HTRegIdx.assign);
        _assignCurRef(value);
        _curValue = value;
        break;
      case HTOpCode.assignMultiply:
        final leftValue = _curValue;
        final value = leftValue * _getRegVal(HTRegIdx.assign);
        _assignCurRef(value);
        _curValue = value;
        break;
      case HTOpCode.assignDevide:
        final leftValue = _curValue;
        final value = leftValue / _getRegVal(HTRegIdx.assign);
        _assignCurRef(value);
        _curValue = value;
        break;
      case HTOpCode.assignAdd:
        final leftValue = _curValue;
        final value = leftValue + _getRegVal(HTRegIdx.assign);
        _assignCurRef(value);
        _curValue = value;
        break;
      case HTOpCode.assignSubtract:
        final leftValue = _curValue;
        final value = leftValue - _getRegVal(HTRegIdx.assign);
        _assignCurRef(value);
        _curValue = value;
        break;
    }
  }

  void _handleBinaryOp(int opcode) {
    switch (opcode) {
      case HTOpCode.logicalOr:
        _curValue = _getRegVal(HTRegIdx.orLeft) || _curValue;
        break;
      case HTOpCode.logicalAnd:
        _curValue = _getRegVal(HTRegIdx.andLeft) && _curValue;
        break;
      case HTOpCode.equal:
        _curValue = _getRegVal(HTRegIdx.equalLeft) == _curValue;
        break;
      case HTOpCode.notEqual:
        _curValue = _getRegVal(HTRegIdx.equalLeft) != _curValue;
        break;
      case HTOpCode.lesser:
        _curValue = _getRegVal(HTRegIdx.relationLeft) < _curValue;
        break;
      case HTOpCode.greater:
        _curValue = _getRegVal(HTRegIdx.relationLeft) > _curValue;
        break;
      case HTOpCode.lesserOrEqual:
        _curValue = _getRegVal(HTRegIdx.relationLeft) <= _curValue;
        break;
      case HTOpCode.greaterOrEqual:
        _curValue = _getRegVal(HTRegIdx.relationLeft) >= _curValue;
        break;
      case HTOpCode.typeIs:
        var object = _getRegVal(HTRegIdx.relationLeft);
        var typeid = _curValue;
        if (typeid is! HTTypeId) {
          throw HTErrorNotType(typeid.toString());
        }
        _curValue = encapsulate(object).isA(typeid);
        break;
      case HTOpCode.typeIsNot:
        var object = _getRegVal(HTRegIdx.relationLeft);
        var typeid = _curValue;
        if (typeid is! HTTypeId) {
          throw HTErrorNotType(typeid.toString());
        }
        _curValue = encapsulate(object).isNotA(typeid);
        break;
      case HTOpCode.add:
        _curValue = _getRegVal(HTRegIdx.addLeft) + _curValue;
        break;
      case HTOpCode.subtract:
        _curValue = _getRegVal(HTRegIdx.addLeft) - _getRegVal(HTRegIdx.addRight);
        break;
      case HTOpCode.multiply:
        _curValue = _getRegVal(HTRegIdx.multiplyLeft) * _curValue;
        break;
      case HTOpCode.devide:
        _curValue = _getRegVal(HTRegIdx.multiplyLeft) / _curValue;
        break;
      case HTOpCode.modulo:
        _curValue = _getRegVal(HTRegIdx.multiplyLeft) % _curValue;
        break;
      default:
      // throw HTErrorUndefinedBinaryOperator(_getRegVal(left).toString(), _getRegVal(right).toString(), opcode);
    }
  }

  void _handleUnaryPrefixOp(int op) {
    final object = _curValue;
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
    var callee = _getRegVal(HTRegIdx.postfixObject);

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

    if (callee is HTFunction) {
      _curValue = callee.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
    } // 外部函数
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        _curValue = callee(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
      } else {
        _curValue = Function.apply(callee, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        // throw HTErrorExternFunc(callee.toString());
      }
    } else if (callee is HTClass) {
      if (callee.classType != ClassType.extern) {
        // 默认构造函数
        _curValue = callee.createInstance(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
      } else {
        // 外部默认构造函数
        final externClass = fetchExternalClass(callee.id);
        final constructor = externClass.memberGet(callee.id);
        if (constructor is HTExternalFunction) {
          _curValue = constructor(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
        } else {
          _curValue =
              Function.apply(constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
    } else {
      throw HTErrorCallable(callee.toString());
    }
  }

  void _handleUnaryPostfixOp(int op) {
    switch (op) {
      case HTOpCode.memberGet:
        var object = _getRegVal(HTRegIdx.postfixObject);
        var key = _getRegVal(HTRegIdx.postfixKey);

        if (object == null || object == HTObject.NULL) {
          throw HTErrorNullObject(_curObjectSymbol!);
        }

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
          var typeString = object.runtimeType.toString();
          final typeid = HTTypeId.parse(typeString);
          var externClass = fetchExternalClass(typeid.id);
          _curValue = externClass.instanceMemberGet(object, key);
        }
        break;
      case HTOpCode.subGet:
        var object = _getRegVal(HTRegIdx.postfixObject);
        var key = _getRegVal(HTRegIdx.postfixKey);

        if (object == null || object == HTObject.NULL) {
          throw HTErrorNullObject(_curObjectSymbol!);
        }

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
        _curValue = _getRegVal(HTRegIdx.postfixObject);
        final value = _curValue + 1;
        _assignCurRef(value);
        break;
      case HTOpCode.postDecrement:
        _curValue = _getRegVal(HTRegIdx.postfixObject);
        final value = _curValue - 1;
        _assignCurRef(value);
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

    final decl = HTBytesVariable(id, this, curModuleName,
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
      _curClass!.defineInstanceMember(decl);
    }
  }

  Map<String, HTBytesParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTBytesParameter>{};

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

      paramDecls[id] = HTBytesParameter(id, this, curModuleName,
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

    _curNamespace.define(enumClass);
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
    final externType = ExternalFuncDeclType.values[_curCode.read()];
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
      curModuleName,
      declId: declId,
      classId: _curClass?.id,
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
      _curClass!.defineInstanceMember(func);
    } else {
      func.context = _curNamespace;
      _curNamespace.define(func);
    }
  }

  void _handleClassDecl() {
    final id = _curCode.readShortUtf8String();

    final classType = ClassType.values[_curCode.read()];

    String? superClassId;
    final hasSuperClass = _curCode.readBool();
    if (hasSuperClass) {
      superClassId = _curCode.readShortUtf8String();
    }

    HTClass? superClass;
    if (id != HTLexicon.object) {
      if (superClassId == null) {
        // TODO: Object基类
        superClass = global.fetch(HTLexicon.object);
      } else {
        superClass = _curNamespace.fetch(superClassId, from: _curNamespace.fullName);
      }
    }

    final klassNamespace = HTClassNamespace(id, this, closure: _curNamespace);
    final klass = HTClass(id, klassNamespace, superClass, this, classType: classType);

    _curClass = klass;

    // 在开头就定义类本身的名字，这样才可以在类定义体中使用类本身
    _curNamespace.define(klass);

    execute(namespace: klassNamespace);

    // 继承所有父类的成员变量和方法，忽略掉已经被覆盖的那些
    var curSuper = superClass;
    while (curSuper != null) {
      for (final decl in curSuper.instanceMembers.values) {
        if (decl.id.startsWith(HTLexicon.underscore)) {
          continue;
        }
        if (decl is HTVariable) {
          klass.defineInstanceMember(decl.clone(), error: false);
        } else {
          klass.defineInstanceMember(decl, error: false); // 函数不能复制，而是在每次call的时候被加上正确的context
        }
      }

      curSuper = curSuper.superClass;
    }

    _curClass = null;
  }
}
