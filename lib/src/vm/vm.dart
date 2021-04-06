import 'dart:typed_data';

import 'package:pub_semver/pub_semver.dart';

import 'compiler.dart';
import 'opcode.dart';
import 'bytecode.dart';
import 'bytecode_variable.dart';
import 'bytecode_funciton.dart';
import '../interpreter.dart';
import '../type.dart';
import '../common.dart';
import '../lexicon.dart';
import '../lexer.dart';
import '../errors.dart';
import '../namespace.dart';
import '../class.dart';
import '../extern_object.dart';
import '../object.dart';
import '../enum.dart';
import '../function.dart';
import '../plugin/moduleHandler.dart';
import '../plugin/errorHandler.dart';
import '../extern_function.dart';
import '../cast.dart';

/// Mixin for classes that holds a ref of Interpreter
mixin HetuRef {
  late final Hetu interpreter;
}

enum _RefType {
  normal,
  member,
  sub,
}

class _LoopInfo {
  final int startIp;
  final int continueIp;
  final int breakIp;
  final HTNamespace namespace;
  _LoopInfo(this.startIp, this.continueIp, this.breakIp, this.namespace);
}

/// A bytecode implementation of a Hetu script interpreter
class Hetu extends Interpreter {
  static var _anonymousScriptIndex = 0;

  late Compiler _compiler;

  final _modules = <String, HTBytecode>{};

  var _curLine = 0;

  /// Current line number of execution.
  @override
  int get curLine => _curLine;
  var _curColumn = 0;

  /// Current column number of execution.
  @override
  int get curColumn => _curColumn;
  late String _curModuleUniqueKey;

  /// Current module's unique key.
  @override
  String get curModuleUniqueKey => _curModuleUniqueKey;

  late HTBytecode _curCode;

  HTClass? _curClass;

  var _regIndex = 0;
  final _registers =
      List<dynamic>.filled(HTRegIdx.length, null, growable: true);

  int _getRegIndex(int relative) => (_regIndex * HTRegIdx.length + relative);
  void _setRegVal(int index, dynamic value) =>
      _registers[_getRegIndex(index)] = value;
  dynamic _getRegVal(int index) => _registers[_getRegIndex(index)];
  set _curValue(dynamic value) =>
      _registers[_getRegIndex(HTRegIdx.value)] = value;
  dynamic get _curValue => _registers[_getRegIndex(HTRegIdx.value)];
  set _curSymbol(String? value) =>
      _registers[_getRegIndex(HTRegIdx.symbol)] = value;
  @override
  String? get curSymbol => _registers[_getRegIndex(HTRegIdx.symbol)];
  set _curObjectSymbol(String? value) =>
      _registers[_getRegIndex(HTRegIdx.objectSymbol)] = value;
  @override
  String? get curObjectSymbol =>
      _registers[_getRegIndex(HTRegIdx.objectSymbol)];
  set _curRefType(_RefType value) =>
      _registers[_getRegIndex(HTRegIdx.refType)] = value;
  _RefType get _curRefType =>
      _registers[_getRegIndex(HTRegIdx.refType)] ?? _RefType.normal;
  set _curLoopCount(int value) =>
      _registers[_getRegIndex(HTRegIdx.loopCount)] = value;
  int get _curLoopCount => _registers[_getRegIndex(HTRegIdx.loopCount)] ?? 0;

  /// loop 信息以栈的形式保存
  /// break 指令将会跳回最近的一个 loop 的出口
  final _loops = <_LoopInfo>[];

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  /// Create a bytecode interpreter.
  /// Each interpreter has a independent global [HTNamespace].
  Hetu({HTErrorHandler? errorHandler, HTModuleHandler? moduleHandler})
      : super(errorHandler: errorHandler, moduleHandler: moduleHandler) {
    _curNamespace = global = HTNamespace(this, id: HTLexicon.global);
  }

  /// Evaluate a string content.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  Future<dynamic> eval(String content,
      {String? moduleUniqueKey,
      CodeType codeType = CodeType.module,
      bool debugMode = true,
      HTNamespace? namespace,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) async {
    if (content.isEmpty) throw HTErrorEmpty();

    _compiler = Compiler(this);

    final name = moduleUniqueKey ??
        (HTLexicon.anonymousScript + (_anonymousScriptIndex++).toString());

    try {
      final tokens = Lexer().lex(content, name);
      final bytes = await _compiler.compile(tokens, this, name,
          codeType: codeType, debugMode: debugMode);

      _curCode = _modules[name] = HTBytecode(bytes);
      _curModuleUniqueKey = name;
      var result = execute(namespace: namespace ?? global);
      if (codeType == CodeType.module && invokeFunc != null) {
        result = invoke(invokeFunc,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            errorHandled: true);
      }

      return result;
    } catch (error, stack) {
      handleError(error, stack);
    }
  }

  /// Import a module by a key,
  /// will use module handler plug-in to resolve
  /// the unique key from the key and [curModuleUniqueKey]
  /// user provided to find the correct module.
  /// Module with the same unique key will be ignored.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  Future<dynamic> import(String key,
      {String? curModuleUniqueKey,
      String? moduleName,
      CodeType codeType = CodeType.module,
      bool debugMode = true,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) async {
    dynamic result;
    final module = await moduleHandler.import(key, curModuleUniqueKey);

    if (module.duplicate) return;

    final savedNamespace = _curNamespace;
    if ((moduleName != null) && (moduleName != HTLexicon.global)) {
      _curNamespace = HTNamespace(this, id: moduleName, closure: global);
      global.define(_curNamespace);
    }

    result = await eval(module.content,
        moduleUniqueKey: module.uniqueKey,
        namespace: _curNamespace,
        codeType: codeType,
        debugMode: debugMode,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);

    _curNamespace = savedNamespace;

    return result;
  }

  /// Call a function within current [HTNamespace].
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
          return func.call(
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          throw HTErrorCallable(funcName);
        }
      } else {
        func = global.fetch(funcName);
        if (func is HTFunction) {
          return func.call(
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          HTErrorCallable(funcName);
        }
      }
    } catch (error, stack) {
      if (errorHandled) rethrow;

      handleError(error, stack);
    }
  }

  /// Handle a error thrown by other funcion in Hetu.
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
        itpErr = HTInterpreterError(
            '${error.message}\nHetu call stack:\n$callStack\nDart call stack:\n',
            error.type,
            _compiler.curModuleUniqueKey,
            _compiler.curLine,
            _compiler.curColumn);
      } else if (error is HTError) {
        itpErr = HTInterpreterError(
            '${error.message}\nHetu call stack:\n$callStack\nDart call stack:\n',
            error.type,
            curModuleUniqueKey,
            curLine,
            curColumn);
      } else {
        itpErr = HTInterpreterError(
            '$error\nHetu call stack:\n$callStack\nDart call stack:\n',
            HTErrorType.other,
            curModuleUniqueKey,
            curLine,
            curColumn);
      }

      errorHandler.handle(itpErr);
    } else {
      errorHandler.handle(error);
    }
  }

  /// Compile a script content into bytecode for later use.
  Future<Uint8List> compile(String content, String moduleName,
      {CodeType codeType = CodeType.module, bool debugMode = true}) async {
    final bytesBuilder = BytesBuilder();

    try {
      final tokens = Lexer().lex(content, moduleName);
      final bytes = await _compiler.compile(tokens, this, moduleName,
          codeType: codeType, debugMode: debugMode);

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
          newErr = HTInterpreterError(
              '${e.message}\nHetu call stack:\n$callStack\nDart call stack:\n',
              e.type,
              _compiler.curModuleUniqueKey,
              _compiler.curLine,
              _compiler.curColumn);
        } else if (e is HTError) {
          newErr = HTInterpreterError(
              '${e.message}\nHetu call stack:\n$callStack\nDart call stack:\n',
              e.type,
              curModuleUniqueKey,
              curLine,
              curColumn);
        } else {
          newErr = HTInterpreterError(
              '$e\nHetu call stack:\n$callStack\nDart call stack:\n',
              HTErrorType.other,
              curModuleUniqueKey,
              curLine,
              curColumn);
        }

        errorHandler.handle(newErr);
      } else {
        errorHandler.handle(e);
      }
    } finally {
      return bytesBuilder.toBytes();
    }
  }

  /// Load a pre-compiled bytecode in to module library.
  /// If [run] is true, then execute the bytecode immediately.
  dynamic load(Uint8List code, String moduleUniqueKey,
      {bool run = true, int ip = 0}) {}

  /// Interpret a loaded module with the key of [moduleUniqueKey]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current value when encountered [OpCode.endOfExec] or [OpCode.endOfFunc].
  /// If [moduleUniqueKey] != null, will return to original [HTBytecode] module.
  /// If [ip] != null, will return to original [_curCode.ip].
  /// If [namespace] != null, will return to original [HTNamespace]
  ///
  /// Once changed into a new module, will open a new area of register space
  /// Every register space holds its own temporary values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute(
      {String? moduleUniqueKey,
      int? ip,
      HTNamespace? namespace,
      bool moveRegIndex = false}) {
    final savedModuleUniqueKey = curModuleUniqueKey;
    final savedIp = _curCode.ip;
    final savedNamespace = _curNamespace;

    var codeChanged = false;
    var ipChanged = false;
    var regIndexMoved = moveRegIndex;
    if (moduleUniqueKey != null && (curModuleUniqueKey != moduleUniqueKey)) {
      _curModuleUniqueKey = moduleUniqueKey;
      _curCode = _modules[moduleUniqueKey]!;
      codeChanged = true;
      ipChanged = true;
      regIndexMoved = true;
    }
    if (ip != null && _curCode.ip != ip) {
      _curCode.ip = ip;
      ipChanged = true;
      regIndexMoved = true;
    }
    if (namespace != null && _curNamespace != namespace) {
      _curNamespace = namespace;
    }

    if (regIndexMoved) {
      ++_regIndex;
      if (_registers.length <= _regIndex * HTRegIdx.length) {
        _registers.length += HTRegIdx.length;
      }
    }

    final result = _execute();

    if (codeChanged) {
      _curModuleUniqueKey = savedModuleUniqueKey;
      _curCode = _modules[_curModuleUniqueKey]!;
    }

    if (ipChanged) {
      _curCode.ip = savedIp;
    }

    if (regIndexMoved) {
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
          _curCode.version = Version(major, minor, patch);
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
          _curObjectSymbol = curSymbol;
          break;
        // 循环开始，记录断点
        case HTOpCode.loopPoint:
          final continueLength = _curCode.readUint16();
          final breakLength = _curCode.readUint16();
          _loops.add(_LoopInfo(_curCode.ip, _curCode.ip + continueLength,
              _curCode.ip + breakLength, _curNamespace));
          ++_curLoopCount;
          break;
        case HTOpCode.breakLoop:
          _curCode.ip = _loops.last.breakIp;
          _curNamespace = _loops.last.namespace;
          _loops.removeLast();
          --_curLoopCount;
          break;
        case HTOpCode.continueLoop:
          _curCode.ip = _loops.last.continueIp;
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
            _curCode.ip = _loops.last.breakIp;
            _loops.removeLast();
            --_curLoopCount;
          }
          break;
        case HTOpCode.doStmt:
          if (_curValue) {
            _curCode.ip = _loops.last.startIp;
          }
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
        case HTOpCode.typeAs:
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
        final symbol = _curSymbol = _curCode.readShortUtf8String();
        final isGetKey = _curCode.readBool();
        if (!isGetKey) {
          _curRefType = _RefType.normal;
          _curValue = _curNamespace.fetch(symbol, from: _curNamespace.fullName);
        } else {
          _curRefType = _RefType.member;
          // reg[13] 是 object，reg[14] 是 key
          _curValue = symbol;
        }
        break;
      case HTValueTypeCode.group:
        _curValue = execute(moveRegIndex: true);
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

        var returnType = HTTypeId.ANY;
        final hasTypeId = _curCode.readBool();
        if (hasTypeId) {
          returnType = _getTypeId();
        }

        int? definitionIp;
        final hasDefinition = _curCode.readBool();
        if (hasDefinition) {
          final length = _curCode.readUint16();
          definitionIp = _curCode.ip;
          _curCode.skip(length);
        }

        final func = HTBytecodeFunction(id, this, curModuleUniqueKey,
            funcType: funcType,
            externalTypedef: externalTypedef,
            parameterDeclarations: paramDecls,
            returnType: returnType,
            definitionIp: definitionIp,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            context: _curNamespace);

        if (!hasExternalTypedef) {
          _curValue = func;
        } else {
          final externalFunc =
              unwrapExternalFunctionType(externalTypedef!, func);
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
      case _RefType.normal:
        _curNamespace.assign(curSymbol!, value, from: _curNamespace.fullName);
        break;
      case _RefType.member:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = _getRegVal(HTRegIdx.postfixKey);
        if (object == null || object == HTObject.NULL) {
          throw HTErrorNullObject(curObjectSymbol!);
        }
        // 如果是 Hetu 对象
        if (object is HTObject) {
          object.memberSet(key!, value, from: _curNamespace.fullName);
        }
        // 如果是 Dart 对象
        else {
          final typeString = object.runtimeType.toString();
          final id = HTTypeId.parseBaseTypeId(typeString);
          final externClass = fetchExternalClass(id);
          externClass.instanceMemberSet(object, key!, value);
        }
        break;
      case _RefType.sub:
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
          final typeString = object.runtimeType.toString();
          final id = HTTypeId.parseBaseTypeId(typeString);
          final externClass = fetchExternalClass(id);
          externClass.instanceSubSet(object, key!, value);
        }
        break;
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
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curCode.readUint16();
        if (leftValue) {
          _curCode.skip(rightValueLength);
          _curValue = true;
        } else {
          final bool rightValue = execute();
          _curValue = rightValue;
        }
        break;
      case HTOpCode.logicalAnd:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curCode.readUint16();
        if (leftValue) {
          final bool rightValue = execute();
          _curValue = leftValue && rightValue;
        } else {
          _curCode.skip(rightValueLength);
          _curValue = false;
        }
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
      case HTOpCode.typeAs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTTypeId typeid = _curValue;
        final HTClass klass = global.fetch(typeid.typeName);
        _curValue = HTCast(object, klass, this);
        break;
      case HTOpCode.typeIs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTTypeId typeid = _curValue;
        _curValue = encapsulate(object).isA(typeid);
        break;
      case HTOpCode.typeIsNot:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTTypeId typeid = _curValue;
        _curValue = encapsulate(object).isNotA(typeid);
        break;
      case HTOpCode.add:
        _curValue = _getRegVal(HTRegIdx.addLeft) + _curValue;
        break;
      case HTOpCode.subtract:
        _curValue = _getRegVal(HTRegIdx.addLeft) - _curValue;
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
    }
  }

  void _handleCallExpr() {
    final callee = _getRegVal(HTRegIdx.postfixObject);

    final positionalArgs = [];
    final positionalArgsLength = _curCode.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute();
      positionalArgs.add(arg);
    }

    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _curCode.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _curCode.readShortUtf8String();
      final arg = execute();
      namedArgs[name] = arg;
    }

    // TODO: typeArgs
    final typeArgs = <HTTypeId>[];

    if (callee is HTFunction) {
      // 普通函数
      if (callee.funcType != FunctionType.constructor) {
        _curValue = callee.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        final classId = callee.classId!;
        HTClass klass = global.fetch(classId);
        if (klass.classType != ClassType.extern) {
          // 命名构造函数
          _curValue = klass.createInstance(
              constructorName: callee.id,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          // 外部命名构造函数
          final externClass = fetchExternalClass(classId);
          final constructor = externClass.memberGet(callee.id);
          if (constructor is HTExternalFunction) {
            _curValue = constructor(
                positionalArgs: positionalArgs,
                namedArgs: namedArgs,
                typeArgs: typeArgs);
          } else {
            return Function.apply(constructor, positionalArgs,
                namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          }
        }
      }
    } // 外部函数
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        _curValue = callee(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        _curValue = Function.apply(callee, positionalArgs,
            namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        // throw HTErrorExternFunc(callee.toString());
      }
    } else if (callee is HTClass) {
      if (callee.classType != ClassType.extern) {
        // 默认构造函数
        _curValue = callee.createInstance(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        // 外部默认构造函数
        final externClass = fetchExternalClass(callee.id);
        final constructor = externClass.memberGet(callee.id);
        if (constructor is HTExternalFunction) {
          _curValue = constructor(
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          _curValue = Function.apply(constructor, positionalArgs,
              namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
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
        final key = _getRegVal(HTRegIdx.postfixKey);

        if (object == null || object == HTObject.NULL) {
          throw HTErrorNullObject(curObjectSymbol!);
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
          final typeString = object.runtimeType.toString();
          final id = HTTypeId.parseBaseTypeId(typeString);
          final externClass = fetchExternalClass(id);
          _curValue = externClass.instanceMemberGet(object, key);
        }
        break;
      case HTOpCode.subGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = execute(moveRegIndex: true);

        if (object == null || object == HTObject.NULL) {
          throw HTErrorNullObject(curObjectSymbol!);
        }

        // TODO: support script subget operator override
        // if (object is! List && object is! Map) {
        //   throw HTErrorSubGet(object.toString());
        // }
        _curValue = object[key];
        _curRefType = _RefType.sub;
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

    return HTTypeId(id, isNullable: isNullable, typeArguments: args);
  }

  void _handleVarDecl() {
    final id = _curCode.readShortUtf8String();
    String? classId;
    final hasClassId = _curCode.readBool();
    if (hasClassId) {
      classId = _curCode.readShortUtf8String();
    }

    final isDynamic = _curCode.readBool();
    final isExtern = _curCode.readBool();
    final isImmutable = _curCode.readBool();
    final isMember = _curCode.readBool();
    final isStatic = _curCode.readBool();

    HTTypeId? declType;
    final hasTypeId = _curCode.readBool();
    if (hasTypeId) {
      declType = _getTypeId();
    }

    int? initializerIp;
    final hasInitializer = _curCode.readBool();
    if (hasInitializer) {
      final length = _curCode.readUint16();
      initializerIp = _curCode.ip;
      _curCode.skip(length);
    }

    final decl = HTBytecodeVariable(id, this, curModuleUniqueKey,
        classId: classId,
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
      final hasTypeId = _curCode.readBool();
      if (hasTypeId) {
        declType = _getTypeId();
      }

      int? initializerIp;
      final hasInitializer = _curCode.readBool();
      if (hasInitializer) {
        final length = _curCode.readUint16();
        initializerIp = _curCode.ip;
        _curCode.skip(length);
      }

      paramDecls[id] = HTBytesParameter(id, this, curModuleUniqueKey,
          declType: declType,
          initializerIp: initializerIp,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }

    return paramDecls;
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
    final externType = ExternalFunctionType.values[_curCode.read()];
    final isStatic = _curCode.readBool();
    final isConst = _curCode.readBool();
    final isVariadic = _curCode.readBool();

    final minArity = _curCode.read();
    final maxArity = _curCode.read();
    final paramDecls = _getParams(_curCode.read());

    var returnType = HTTypeId.ANY;
    HTBytecodeFunctionSuperConstructor? superConstructor;
    String? superCtorId;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    final returnTypeEnum = FunctionReturnType.values.elementAt(_curCode.read());
    if (returnTypeEnum == FunctionReturnType.typeid) {
      returnType = _getTypeId();
    } else if (returnTypeEnum == FunctionReturnType.superClassConstructor) {
      final hasSuperCtorid = _curCode.readBool();
      if (hasSuperCtorid) {
        superCtorId = _curCode.readShortUtf8String();
      }

      final positionalArgIpsLength = _curCode.read();
      for (var i = 0; i < positionalArgIpsLength; ++i) {
        final argLength = _curCode.readUint16();
        positionalArgIps.add(_curCode.ip);
        _curCode.skip(argLength);
      }

      final namedArgsLength = _curCode.read();
      for (var i = 0; i < namedArgsLength; ++i) {
        final argName = _curCode.readShortUtf8String();
        final argLength = _curCode.readUint16();
        namedArgIps[argName] = _curCode.ip;
        _curCode.skip(argLength);
      }
      superConstructor = HTBytecodeFunctionSuperConstructor(superCtorId,
          positionalArgsIp: positionalArgIps, namedArgsIp: namedArgIps);
    }

    int? definitionIp;
    final hasDefinition = _curCode.readBool();
    if (hasDefinition) {
      final length = _curCode.readUint16();
      definitionIp = _curCode.ip;
      _curCode.skip(length);
    }

    final func = HTBytecodeFunction(
      id,
      this,
      curModuleUniqueKey,
      declId: declId,
      klass: _curClass,
      funcType: funcType,
      externalFunctionType: externType,
      externalTypedef: externalTypedef,
      parameterDeclarations: paramDecls,
      returnType: returnType,
      definitionIp: definitionIp,
      isStatic: isStatic,
      isConst: isConst,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
      superConstructor: superConstructor,
    );

    if (!isStatic &&
        (funcType == FunctionType.method ||
            funcType == FunctionType.getter ||
            funcType == FunctionType.setter)) {
      // instance methods are defined separately.
      _curClass!.defineInstanceMember(func);
    } else {
      // constructor are defined in class's namespace,
      // however its context is on instance.
      if (funcType != FunctionType.constructor) {
        func.context = _curNamespace;
      }
      // static methods are defined in class's namespace,
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
        superClass =
            _curNamespace.fetch(superClassId, from: _curNamespace.fullName);
      }
    }

    final klass =
        HTClass(id, superClass, this, _curNamespace, classType: classType);
    _curNamespace.define(klass);

    _curClass = klass;

    execute(namespace: klass.namespace);

    // 继承不在这里处理
    // klass.inherit(superClass);

    _curClass = null;
  }

  void _handleEnumDecl() {
    final id = _curCode.readShortUtf8String();
    final isExtern = _curCode.readBool();
    final length = _curCode.readUint16();

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < length; i++) {
      final enumId = _curCode.readShortUtf8String();
      defs[enumId] = HTEnumItem(i, enumId, HTTypeId(id));
    }

    final enumClass = HTEnum(id, defs, this, isExtern: isExtern);

    _curNamespace.define(enumClass);
  }
}
