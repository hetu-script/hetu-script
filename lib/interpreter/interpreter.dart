import 'dart:typed_data';

import 'package:pub_semver/pub_semver.dart';

import '../binding/external_function.dart';
import '../core/abstract_interpreter.dart';
import '../core/namespace/namespace.dart';
import '../core/object.dart';
import '../core/declaration/abstract_function.dart';
import '../core/abstract_parser.dart';
import '../type_system/type.dart';
import '../type_system/function_type.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../source/source_provider.dart';
import '../error/errors.dart';
import '../error/error_handler.dart';
import 'class/class.dart';
import 'class/enum.dart';
import 'class/cast.dart';
import 'old_compiler.dart';
import 'opcode.dart';
import 'bytecode/bytecode_source.dart';
import 'variable.dart';
import 'function/funciton.dart';
import 'function/parameter.dart';

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
class Hetu extends HTInterpreter {
  @override
  late HTCompiler curParser;

  // final _sources = HTBytecodeCompilation();

  // late HTBytecodeModule _curModule;

  var _curLine = 0;
  @override
  int get curLine => _curLine;

  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;

  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  HTClass? _curClass;

  var _regIndex = -1;
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
  // set _curLeftValue(String? value) =>
  //     _registers[_getRegIndex(HTRegIdx.leftValue)] = value;
  // @override
  // String? get curLeftValue => _registers[_getRegIndex(HTRegIdx.leftValue)];
  set _curRefType(_RefType value) =>
      _registers[_getRegIndex(HTRegIdx.refType)] = value;
  _RefType get _curRefType =>
      _registers[_getRegIndex(HTRegIdx.refType)] ?? _RefType.normal;
  set _curTypeArgs(List<HTType> value) =>
      _registers[_getRegIndex(HTRegIdx.typeArgs)] = value;
  List<HTType> get _curTypeArgs =>
      _registers[_getRegIndex(HTRegIdx.typeArgs)] ?? const [];
  set _curLoopCount(int value) =>
      _registers[_getRegIndex(HTRegIdx.loopCount)] = value;
  int get _curLoopCount => _registers[_getRegIndex(HTRegIdx.loopCount)] ?? 0;
  set _curAnchor(int value) =>
      _registers[_getRegIndex(HTRegIdx.anchor)] = value;
  int get _curAnchor => _registers[_getRegIndex(HTRegIdx.anchor)] ?? 0;

  /// loop 信息以栈的形式保存
  /// break 指令将会跳回最近的一个 loop 的出口
  final _loops = <_LoopInfo>[];

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  /// Create a bytecode interpreter.
  /// Each interpreter has a independent global [HTNamespace].
  Hetu({HTErrorHandler? errorHandler, SourceProvider? sourceProvider})
      : super(errorHandler: errorHandler, sourceProvider: sourceProvider) {
    _curNamespace = global;
  }

  /// Evaluate a string content.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  Future<dynamic> eval(String content,
      {String? moduleFullName,
      HTNamespace? namespace,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    if (content.isEmpty) throw HTError.emptyString();

    curParser = HTCompiler();

    _curModuleFullName = moduleFullName ?? HTLexicon.anonymousScript;

    try {
      final compilation = await curParser
          .compile(content, sourceProvider, _curModuleFullName, config: config);

      _sources.join(compilation);

      _curModule = compilation.getModule(_curModuleFullName);
      var result = execute(namespace: namespace ?? _curNamespace);

      if (config.sourceType == SourceType.module && invokeFunc != null) {
        result = invoke(invokeFunc,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            errorHandled: true);
      }

      return result;
    } catch (error, stack) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, stack);
      }
    }
  }

  /// Import a module by a key,
  /// will use module handler plug-in to resolve
  /// the full name from the key and [curModuleFullName]
  /// user provided to find the correct module.
  /// Module with the same full name will be ignored.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  Future<dynamic> import(String key,
      {String? curModuleFullName,
      String? moduleName,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) async {
    dynamic result;

    final fullName = sourceProvider.resolveFullName(key);

    if (config.reload || !sourceProvider.hasModule(fullName)) {
      final module = await sourceProvider.getSource(key,
          curModuleFullName: curModuleFullName);

      final savedNamespace = _curNamespace;
      if ((moduleName != null) && (moduleName != HTLexicon.global)) {
        _curNamespace = HTNamespace(this, id: moduleName, closure: global);
        final decl =
            HTVariable(moduleName, this, module.fullName, value: _curNamespace);
        global.define(decl);
      }

      result = await eval(module.content,
          moduleFullName: module.fullName,
          namespace: _curNamespace,
          config: config,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);

      _curNamespace = savedNamespace;

      return result;
    }
  }

  /// Call a function within current [HTNamespace].
  @override
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      var func;
      if (className != null) {
        // 类的静态函数
        HTClass klass = global.fetch(className);
        final func = klass.memberGet(funcName);

        if (func is AbstractFunction) {
          return func.call(
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          throw HTError.notCallable(funcName);
        }
      } else {
        func = global.fetch(funcName);
        if (func is AbstractFunction) {
          return func.call(
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          HTError.notCallable(funcName);
        }
      }
    } catch (error, stack) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, stack);
      }
    }
  }

  /// Compile a script content into bytecode for later use.
  Future<HTBytecodeCompilation> compile(String content, String moduleName,
      {ParserConfig config = const ParserConfig(),
      bool errorHandled = false}) async {
    throw HTError(ErrorCode.extern, ErrorType.externalError,
        message: 'compile is currently unusable');
  }

  /// Load a pre-compiled bytecode in to module library.
  /// If [run] is true, then execute the bytecode immediately.
  dynamic load(Uint8List code, String moduleFullName,
      {bool run = true, int ip = 0}) {}

  /// Interpret a loaded module with the key of [moduleFullName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current value when encountered [OpCode.endOfExec] or [OpCode.endOfFunc].
  /// If [moduleFullName] != null, will return to original [HTBytecodeModule] module.
  /// If [ip] != null, will return to original [_curModule.ip].
  /// If [namespace] != null, will return to original [HTNamespace]
  ///
  /// Once changed into a new module, will open a new area of register space
  /// Every register space holds its own temporary values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute(
      {String? moduleFullName,
      int? ip,
      HTNamespace? namespace,
      int? line,
      int? column
      // ,      bool moveRegIndex = false
      }) {
    final savedModule = _curModule;
    final savedModuleFullName = curModuleFullName;
    final savedIp = _curModule.ip;
    final savedNamespace = _curNamespace;

    var codeChanged = false;
    var ipChanged = false;
    // var regIndexMoved = moveRegIndex;
    if (moduleFullName != null && (curModuleFullName != moduleFullName)) {
      _curModuleFullName = moduleFullName;
      _curModule = _sources.getModule(moduleFullName);
      codeChanged = true;
      ipChanged = true;
      // regIndexMoved = true;
    }
    if (ip != null && _curModule.ip != ip) {
      _curModule.ip = ip;
      ipChanged = true;
      // regIndexMoved = true;
    }
    if (namespace != null && _curNamespace != namespace) {
      _curNamespace = namespace;
    }

    // if (regIndexMoved) {
    ++_regIndex;
    if (_registers.length <= _regIndex * HTRegIdx.length) {
      _registers.length += HTRegIdx.length;
    }
    _curLine = line ?? 0;
    _curColumn = column ?? 0;
    // }

    final result = _execute();

    if (codeChanged) {
      _curModuleFullName = savedModuleFullName;
      _curModule = savedModule;
    }

    if (ipChanged) {
      _curModule.ip = savedIp;
    }

    // if (regIndexMoved) {
    --_regIndex;
    // }

    _curNamespace = savedNamespace;

    return result;
  }

  dynamic _execute() {
    var instruction = _curModule.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          _curModule.readUint32();
          break;
        case HTOpCode.version:
          final major = _curModule.read();
          final minor = _curModule.read();
          final patch = _curModule.readUint16();
          _curModule.version = Version(major, minor, patch);
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          final index = _curModule.read();
          _setRegVal(index, _curValue);
          break;
        case HTOpCode.skip:
          final distance = _curModule.readInt16();
          _curModule.ip += distance;
          break;
        case HTOpCode.anchor:
          _curAnchor = _curModule.ip;
          break;
        case HTOpCode.goto:
          final distance = _curModule.readInt16();
          _curModule.ip = _curAnchor + distance;
          break;
        case HTOpCode.debugInfo:
          _curLine = _curModule.readUint16();
          _curColumn = _curModule.readUint16();
          break;
        // case HTOpCode.leftValue:
        //   _curLeftValue = curSymbol;
        //   break;
        // 循环开始，记录断点
        case HTOpCode.loopPoint:
          final continueLength = _curModule.readUint16();
          final breakLength = _curModule.readUint16();
          _loops.add(_LoopInfo(_curModule.ip, _curModule.ip + continueLength,
              _curModule.ip + breakLength, _curNamespace));
          ++_curLoopCount;
          break;
        case HTOpCode.breakLoop:
          _curModule.ip = _loops.last.breakIp;
          _curNamespace = _loops.last.namespace;
          _loops.removeLast();
          --_curLoopCount;
          break;
        case HTOpCode.continueLoop:
          _curModule.ip = _loops.last.continueIp;
          _curNamespace = _loops.last.namespace;
          break;
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _curModule.readShortUtf8String();
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
          final int64Length = _curModule.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _curModule.constTable.addInt(_curModule.readInt64());
          }
          final float64Length = _curModule.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _curModule.constTable.addFloat(_curModule.readFloat64());
          }
          final utf8StringLength = _curModule.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _curModule.constTable.addString(_curModule.readUtf8String());
          }
          break;
        case HTOpCode.enumDecl:
          _handleEnumDecl();
          break;
        case HTOpCode.funcDecl:
          _handleFuncDecl();
          break;
        case HTOpCode.classDecl:
          _handleClassDecl();
          break;
        case HTOpCode.varDecl:
          _handleVarDecl();
          break;
        case HTOpCode.ifStmt:
          bool condition = _curValue;
          final thenBranchLength = _curModule.readUint16();
          if (!condition) {
            _curModule.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          final hasCondition = _curModule.readBool();
          if (hasCondition && !_curValue) {
            _curModule.ip = _loops.last.breakIp;
            _loops.removeLast();
            --_curLoopCount;
          }
          break;
        case HTOpCode.doStmt:
          if (_curValue) {
            _curModule.ip = _loops.last.startIp;
          }
          break;
        case HTOpCode.whenStmt:
          _handleWhenStmt();
          break;
        case HTOpCode.assign:
          final value = _getRegVal(HTRegIdx.assign);
          _assignCurRef(value);
          _curValue = value;
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
          throw HTError.unknownOpCode(instruction);
      }

      instruction = _curModule.read();
    }
  }

  // void _resolve() {}

  void _storeLocal() {
    final valueType = _curModule.read();
    switch (valueType) {
      case HTValueTypeCode.NULL:
        _curValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_curModule.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTValueTypeCode.int64:
        final index = _curModule.readUint16();
        _curValue = _curModule.constTable.getInt64(index);
        break;
      case HTValueTypeCode.float64:
        final index = _curModule.readUint16();
        _curValue = _curModule.constTable.getFloat64(index);
        break;
      case HTValueTypeCode.utf8String:
        final index = _curModule.readUint16();
        _curValue = _curModule.constTable.getUtf8String(index);
        break;
      case HTValueTypeCode.symbol:
        final symbol = _curSymbol = _curModule.readShortUtf8String();
        final isGetKey = _curModule.readBool();
        if (!isGetKey) {
          _curRefType = _RefType.normal;
          _curValue = _curNamespace.fetch(symbol, from: _curNamespace.fullName);
        } else {
          _curRefType = _RefType.member;
          _curValue = symbol;
        }
        final hasTypeArgs = _curModule.readBool();
        if (hasTypeArgs) {
          final typeArgsLength = _curModule.read();
          final typeArgs = <HTType>[];
          for (var i = 0; i < typeArgsLength; ++i) {
            final arg = _handleTypeExpr();
            typeArgs.add(arg);
          }
          _curTypeArgs = typeArgs;
        }
        break;
      case HTValueTypeCode.group:
        _curValue = execute();
        // _curValue = execute(moveRegIndex: true);
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = _curModule.readUint16();
        for (var i = 0; i < length; ++i) {
          final listItem = execute();
          list.add(listItem);
        }
        _curValue = list;
        break;
      case HTValueTypeCode.map:
        final map = {};
        final length = _curModule.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute();
          final value = execute();
          map[key] = value;
        }
        _curValue = map;
        break;
      case HTValueTypeCode.function:
        final id = _curModule.readShortUtf8String();

        final hasExternalTypedef = _curModule.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _curModule.readShortUtf8String();
        }

        final hasParameterDeclarations = _curModule.readBool();

        final category = FunctionCategory.literal;
        final isVariadic = _curModule.readBool();
        final minArity = _curModule.read();
        final maxArity = _curModule.read();
        final paramDecls = _getParams(_curModule.read());

        HTType returnType = HTType.ANY;
        final hasType = _curModule.readBool();
        if (hasType) {
          returnType = _handleTypeExpr();
        }

        int? line, column, definitionIp;
        final hasDefinition = _curModule.readBool();

        if (hasDefinition) {
          line = _curModule.readUint16();
          column = _curModule.readUint16();
          final length = _curModule.readUint16();
          definitionIp = _curModule.ip;
          _curModule.skip(length);
        }

        final func = HTFunction(id, this, curModuleFullName,
            category: category,
            externalId: externalTypedef,
            hasParameterDeclarations: hasParameterDeclarations,
            parameterDeclarations: paramDecls,
            returnType: returnType,
            definitionIp: definitionIp,
            definitionLine: line,
            definitionColumn: column,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            context: _curNamespace);

        if (!hasExternalTypedef) {
          _curValue = func;
        } else {
          final externalFunc = unwrapExternalFunctionType(func);
          _curValue = externalFunc;
        }
        // } else {
        //   _curValue = HTFunctionType(
        //       parameterTypes:
        //           paramDecls.values.map((param) => param.declType).toList(),
        //       returnType: returnType);
        // }

        break;
      case HTValueTypeCode.type:
        _curValue = _handleTypeExpr();
        break;
      default:
        throw HTError.unkownValueType(valueType);
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
        final encap = encapsulate(object);
        // 如果是 Hetu 对象
        // if (encap is HTObject) {
        encap.memberSet(key!, value, from: _curNamespace.fullName);
        // }
        // // 如果是 Dart 对象
        // else {
        //   final typeString = encap.runtimeType.toString();
        //   final id = HTType.parseBaseType(typeString);
        //   final externClass = fetchExternalClass(id);
        //   externClass.instanceMemberSet(encap, key!, value);
        // }
        break;
      case _RefType.sub:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = _getRegVal(HTRegIdx.postfixKey);
        if (object == null || object == HTObject.NULL) {
          throw HTError.nullObject(object);
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
          final id = HTType.parseBaseType(typeString);
          final externClass = fetchExternalClass(id);
          externClass.instanceSubSet(object, key!, value);
        }
        break;
    }
  }

  void _handleWhenStmt() {
    var condition = _curValue;
    final hasCondition = _curModule.readBool();

    final casesCount = _curModule.read();
    final branchesIpList = <int>[];
    final cases = <dynamic, int>{};
    for (var i = 0; i < casesCount; ++i) {
      branchesIpList.add(_curModule.readUint16());
    }
    final elseBranchIp = _curModule.readUint16();
    final endIp = _curModule.readUint16();

    for (var i = 0; i < casesCount; ++i) {
      final value = execute();
      cases[value] = branchesIpList[i];
    }

    if (hasCondition) {
      if (cases.containsKey(condition)) {
        final distance = cases[condition]!;
        _curModule.skip(distance);
      } else if (elseBranchIp > 0) {
        _curModule.skip(elseBranchIp);
      } else {
        _curModule.skip(endIp);
      }
    } else {
      var condition = false;
      for (final key in cases.keys) {
        if (key) {
          final distance = cases[key]!;
          _curModule.skip(distance);
          condition = true;
          break;
        }
      }
      if (!condition) {
        if (elseBranchIp > 0) {
          _curModule.skip(elseBranchIp);
        } else {
          _curModule.skip(endIp);
        }
      }
    }
  }

  void _handleBinaryOp(int opcode) {
    switch (opcode) {
      case HTOpCode.logicalOr:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curModule.readUint16();
        if (leftValue) {
          _curModule.skip(rightValueLength);
          _curValue = true;
        } else {
          final bool rightValue = execute();
          _curValue = rightValue;
        }
        break;
      case HTOpCode.logicalAnd:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curModule.readUint16();
        if (leftValue) {
          final bool rightValue = execute();
          _curValue = leftValue && rightValue;
        } else {
          _curModule.skip(rightValueLength);
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
        final HTType type = _curValue;
        final HTClass klass = global.fetch(type.id);
        _curValue = HTCast(object, klass, this);
        break;
      case HTOpCode.typeIs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTType type = _curValue;
        final encapsulated = encapsulate(object);
        _curValue = encapsulated.valueType.isA(type);
        break;
      case HTOpCode.typeIsNot:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final HTType type = _curValue;
        final encapsulated = encapsulate(object);
        _curValue = encapsulated.valueType.isNotA(type);
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
    final positionalArgsLength = _curModule.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      positionalArgs.add(arg);
    }

    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _curModule.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _curModule.readShortUtf8String();
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      namedArgs[name] = arg;
    }

    final typeArgs = _curTypeArgs;

    if (callee is AbstractFunction) {
      _curValue = callee.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    } else if (callee is HTClass) {
      if (callee.isAbstract) {
        throw HTError.abstracted();
      }

      if (!callee.isExternal) {
        final constructor =
            callee.memberGet(HTLexicon.constructor) as AbstractFunction;
        _curValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        final constructor = callee.memberGet(callee.id) as AbstractFunction;
        _curValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      }
    } // 外部函数
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        _curValue = callee(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        _curValue = Function.apply(
            callee,
            positionalArgs,
            namedArgs.map<Symbol, dynamic>(
                (key, value) => MapEntry(Symbol(key), value)));
      }
    } else {
      throw HTError.notCallable(callee.toString());
    }
  }

  void _handleUnaryPostfixOp(int op) {
    switch (op) {
      case HTOpCode.memberGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = _getRegVal(HTRegIdx.postfixKey);
        final encap = encapsulate(object);
        _curValue = encap.memberGet(key, from: _curNamespace.fullName);
        break;
      case HTOpCode.subGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = execute();
        // final key = execute(moveRegIndex: true);
        _setRegVal(HTRegIdx.postfixKey, key);
        if (object is HTObject) {
          _curValue = object.subGet(key);
        } else {
          _curValue = object[key];
        }
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

  HTType _handleTypeExpr() {
    final index = _curModule.read();
    final typeType = TypeType.values.elementAt(index);

    switch (typeType) {
      case TypeType.normal:
        final typeName = _curModule.readShortUtf8String();
        final typeArgsLength = _curModule.read();
        final typeArgs = <HTType>[];
        for (var i = 0; i < typeArgsLength; ++i) {
          typeArgs.add(_handleTypeExpr());
        }
        final isNullable = _curModule.read() == 0 ? false : true;
        return HTType(typeName, typeArgs: typeArgs, isNullable: isNullable);
      case TypeType.parameter:
        final typeId = _curModule.readShortUtf8String();
        final length = _curModule.read();
        final typeArgs = <HTType>[];
        for (var i = 0; i < length; ++i) {
          typeArgs.add(_handleTypeExpr());
        }
        final isNullable = _curModule.read() == 0 ? false : true;
        final isOptional = _curModule.read() == 0 ? false : true;
        final isNamed = _curModule.read() == 0 ? false : true;
        String? paramId;
        if (isNamed) {
          paramId = _curModule.readShortUtf8String();
        }
        final isVariadic = _curModule.read() == 0 ? false : true;
        return HTParameterType(typeId,
            paramId: paramId ?? '',
            typeArgs: typeArgs,
            isNullable: isNullable,
            isOptional: isOptional,
            isNamed: isNamed,
            isVariadic: isVariadic);

      case TypeType.function:
        final paramsLength = _curModule.read();
        final parameterTypes = <HTParameterType>[];
        for (var i = 0; i < paramsLength; ++i) {
          final paramType = _handleTypeExpr() as HTParameterType;
          parameterTypes.add(paramType);
        }
        final returnType = _handleTypeExpr();
        return HTFunctionType(
            parameterTypes: parameterTypes, returnType: returnType);
      case TypeType.struct:
      case TypeType.interface:
      case TypeType.union:
        return HTType(_curModule.readShortUtf8String());
    }
  }

  void _handleVarDecl() {
    final id = _curModule.readShortUtf8String();
    String? classId;
    final hasClassId = _curModule.readBool();
    if (hasClassId) {
      classId = _curModule.readShortUtf8String();
    }

    final typeInferrence = _curModule.readBool();
    final isExternal = _curModule.readBool();
    final isImmutable = _curModule.readBool();
    final isStatic = _curModule.readBool();
    final lateInitialize = _curModule.readBool();

    HTType? declType;
    final hasType = _curModule.readBool();
    if (hasType) {
      declType = _handleTypeExpr();
    }

    late final HTVariable decl;

    final hasInitializer = _curModule.readBool();
    if (hasInitializer) {
      if (lateInitialize) {
        final definitionLine = _curModule.readUint16();
        final definitionColumn = _curModule.readUint16();
        final length = _curModule.readUint16();
        final definitionIp = _curModule.ip;
        _curModule.skip(length);

        decl = HTVariable(id, this, curModuleFullName,
            classId: classId,
            declType: declType,
            isExternal: isExternal,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        final initValue = execute();

        decl = HTVariable(id, this, curModuleFullName,
            classId: classId,
            value: initValue,
            declType: declType,
            isExternal: isExternal);
      }
    } else {
      decl = HTVariable(id, this, curModuleFullName,
          classId: classId, declType: declType, isExternal: isExternal);
    }

    if (!hasClassId || isStatic) {
      _curNamespace.define(decl);
    } else {
      _curClass!.defineInstanceMember(decl);
    }
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};

    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _curModule.readShortUtf8String();
      final isOptional = _curModule.readBool();
      final isNamed = _curModule.readBool();
      final isVariadic = _curModule.readBool();

      HTType? declType;
      final hasType = _curModule.readBool();
      if (hasType) {
        declType = _handleTypeExpr();
      }

      int? definitionIp;
      final hasInitializer = _curModule.readBool();
      if (hasInitializer) {
        final length = _curModule.readUint16();
        definitionIp = _curModule.ip;
        _curModule.skip(length);
      }

      paramDecls[id] = HTParameter(id, this, curModuleFullName,
          declType: declType,
          definitionIp: definitionIp,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }

    return paramDecls;
  }

  void _handleFuncDecl() {
    final id = _curModule.readShortUtf8String();
    final declId = _curModule.readShortUtf8String();

    final hasExternalTypedef = _curModule.readBool();
    String? externalTypedef;
    if (hasExternalTypedef) {
      externalTypedef = _curModule.readShortUtf8String();
    }

    final category = FunctionCategory.values[_curModule.read()];
    final isExternal = _curModule.readBool();
    final isStatic = _curModule.readBool();
    final isConst = _curModule.readBool();

    final hasParameterDeclarations = _curModule.readBool();

    final isVariadic = _curModule.readBool();
    final minArity = _curModule.read();
    final maxArity = _curModule.read();

    final parameterDeclarations = _getParams(_curModule.read());

    HTType returnType = HTType.ANY;
    ReferConstructor? referConstructor;
    String? superCtorId;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    final returnTypeEnum =
        FunctionAppendixType.values.elementAt(_curModule.read());
    if (returnTypeEnum == FunctionAppendixType.type) {
      returnType = _handleTypeExpr();
    } else if (returnTypeEnum == FunctionAppendixType.referConstructor) {
      final hasSuperCtorid = _curModule.readBool();
      if (hasSuperCtorid) {
        superCtorId = _curModule.readShortUtf8String();
      }

      final positionalArgIpsLength = _curModule.read();
      for (var i = 0; i < positionalArgIpsLength; ++i) {
        final argLength = _curModule.readUint16();
        positionalArgIps.add(_curModule.ip);
        _curModule.skip(argLength);
      }

      final namedArgsLength = _curModule.read();
      for (var i = 0; i < namedArgsLength; ++i) {
        final argName = _curModule.readShortUtf8String();
        final argLength = _curModule.readUint16();
        namedArgIps[argName] = _curModule.ip;
        _curModule.skip(argLength);
      }
      referConstructor = ReferConstructor(superCtorId,
          positionalArgsIp: positionalArgIps, namedArgsIp: namedArgIps);
    }

    int? line, column, definitionIp;
    final hasDefinition = _curModule.readBool();
    if (hasDefinition) {
      line = _curModule.readUint16();
      column = _curModule.readUint16();
      final length = _curModule.readUint16();
      definitionIp = _curModule.ip;
      _curModule.skip(length);
    }

    final func = HTFunction(id, this, curModuleFullName,
        declId: declId,
        klass: _curClass,
        category: category,
        isExternal: isExternal,
        externalId: externalTypedef,
        hasParameterDeclarations: hasParameterDeclarations,
        parameterDeclarations: parameterDeclarations,
        returnType: returnType,
        definitionIp: definitionIp,
        definitionLine: line,
        definitionColumn: column,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isVariadic,
        minArity: minArity,
        maxArity: maxArity,
        referConstructor: referConstructor);

    if (!isStatic &&
        (category == FunctionCategory.method ||
            category == FunctionCategory.getter ||
            category == FunctionCategory.setter)) {
      final decl = HTVariable(id, this, _curModuleFullName, value: func);
      _curClass!.defineInstanceMember(decl);
    } else {
      // constructor are defined in class's namespace,
      // however its context is on instance.
      if (category != FunctionCategory.constructor) {
        func.context = _curNamespace;
      }
      // static methods are defined in class's namespace,
      final decl = HTVariable(id, this, _curModuleFullName, value: func);
      _curNamespace.define(decl);
    }
  }

  void _handleClassDecl() {
    final id = _curModule.readShortUtf8String();

    final isExternal = _curModule.readBool();
    final isAbstract = _curModule.readBool();

    // final classType = ClassType.values[_curCode.read()];

    HTClass? superClass;
    HTType? superType;
    final hasSuperClass = _curModule.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
      superClass =
          _curNamespace.fetch(superType.id, from: _curNamespace.fullName);
    } else {
      if (!isExternal && (id != HTLexicon.object)) {
        superType = HTType.object;
        superClass = global.fetch(HTLexicon.object);
      }
    }

    final klass = HTClass(id, this, _curModuleFullName, _curNamespace,
        superClass: superClass,
        superType: superType,
        isExternal: isExternal,
        isAbstract: isAbstract);
    final decl = HTVariable(id, this, _curModuleFullName, value: klass);
    _curNamespace.define(decl);

    _curClass = klass;

    final hasBody = _curModule.readBool();
    if (hasBody) {
      execute(namespace: klass.namespace);
    }

    // Add default constructor if non-exist.
    if (!isAbstract) {
      if (!isExternal) {
        if (!klass.namespace.contains(HTLexicon.constructor)) {
          final ctor = HTFunction(
              HTLexicon.constructor, this, curModuleFullName,
              klass: klass, category: FunctionCategory.constructor);
          final decl =
              HTVariable(ctor.id, this, _curModuleFullName, value: ctor);
          klass.namespace.define(decl);
        }
      }
      // else {
      //   if (!klass.namespace.contains(klass.id)) {
      //     klass.namespace.define(HTBytecodeFunction(
      //         klass.id, this, curModuleFullName,
      //         klass: klass, category: FunctionType.constructor));
      //   }
      // }
    }

    // 继承不在这里处理
    // klass.inherit(superClass);

    _curClass = null;
  }

  void _handleEnumDecl() {
    final id = _curModule.readShortUtf8String();
    final isExternal = _curModule.readBool();
    final length = _curModule.readUint16();

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < length; i++) {
      // final enumId = _curCode.readShortUtf8String();
      // defs[enumId] = HTEnumItem<int>(i, enumId, HTType(id));
    }

    final enumClass = HTEnum(id, defs, this, isExternal: isExternal);
    final decl = HTVariable(id, this, _curModuleFullName, value: enumClass);
    _curNamespace.define(decl);
  }
}
