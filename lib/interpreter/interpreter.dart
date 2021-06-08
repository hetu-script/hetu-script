import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../binding/external_function.dart';
import '../binding/external_class.dart';
import '../core/abstract_interpreter.dart';
import '../core/namespace/namespace.dart';
import '../core/object.dart';
import '../core/abstract_parser.dart';
import '../core/const_table.dart';
import '../core/declaration/typed_parameter_declaration.dart';
import '../type/type.dart';
import '../type/function_type.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../source/source_provider.dart';
import '../error/errors.dart';
import '../error/error_handler.dart';
import 'class/class.dart';
import 'class/enum.dart';
import 'class/cast.dart';
import 'compiler.dart';
import 'opcode.dart';
import 'variable.dart';
import 'function/function.dart';
import 'function/parameter.dart';
import 'bytecode/bytecode_reader.dart';

/// Mixin for classes that holds a ref of Interpreter
mixin HetuRef {
  late final Hetu interpreter;
}

class _LoopInfo {
  final int startIp;
  final int continueIp;
  final int breakIp;
  final HTNamespace namespace;
  _LoopInfo(this.startIp, this.continueIp, this.breakIp, this.namespace);
}

class _Library {
  final Map<String, HTNamespace> namespaces;

  final Uint8List bytes;

  _Library(this.namespaces, this.bytes);
}

/// A bytecode implementation of a Hetu script interpreter
class Hetu extends AbstractInterpreter {
  static const verMajor = 0;
  static const verMinor = 1;
  static const verPatch = 0;

  final _libs = <String, _Library>{};

  late BytecodeReader _code;

  final _constTable = ConstTable();

  var _curLine = 0;
  @override
  int get curLine => _curLine;

  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;

  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  late String _curLibraryName;
  @override
  String get curLibraryName => _curLibraryName;

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
  set _curLeftValue(dynamic value) =>
      _registers[_getRegIndex(HTRegIdx.leftValue)] = value;
  dynamic get curLeftValue =>
      _registers[_getRegIndex(HTRegIdx.leftValue)] ?? _curNamespace;
  // set _curRefType(_RefType value) =>
  //     _registers[_getRegIndex(HTRegIdx.refType)] = value;
  // _RefType get _curRefType =>
  //     _registers[_getRegIndex(HTRegIdx.refType)] ?? _RefType.normal;
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
    _curNamespace = coreNamespace;
  }

  @override
  Future<void> init(
      {bool coreModule = true,
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) async {
    await super.init(
        coreModule: coreModule,
        externalClasses: externalClasses,
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef);

    // a postfix for correct path resolve
    _curModuleFullName =
        Uri.file(path.join(sourceProvider.workingDirectory, 'script'))
            .path
            .substring(1);
  }

  /// Evaluate a string content.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  Future<dynamic> eval(String content,
      {String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    if (content.isEmpty) throw HTError.emptyString();

    _curModuleFullName = moduleFullName ??= HTLexicon.anonymousScript;

    _curLibraryName = libraryName ??= moduleFullName;

    final createNamespace = namespace != coreNamespace;
    try {
      final compilation = await parser.parse(content,
          createNamespace: createNamespace,
          libraryName:
              libraryName, // TODO: should set in parser, and should read from script if exist
          moduleFullName: moduleFullName,
          sourceProvider: sourceProvider,
          config: config);

      final bytes = await compiler.compile(compilation);

      _code = BytecodeReader(bytes);

      if (config.sourceType == SourceType.script) {
        final result = execute(namespace: namespace ?? coreNamespace);
        return result;
      } else if (config.sourceType == SourceType.module) {
        final namespaces = <String, HTNamespace>{};
        while (_code.ip < _code.bytes.length) {
          final HTNamespace namespace = execute();
          namespaces[namespace.id] = namespace;
        }
        final lib = _Library(namespaces, bytes);
        _libs[_curLibraryName] = lib;

        if (createNamespace) {
          for (final module in compilation.modules) {
            final nsp = lib.namespaces[module.fullName]!;
            for (final info in module.imports) {
              // TODO: alias, showList
              final importNamespace = lib.namespaces[info.fullName]!;
              nsp.import(importNamespace);
            }
          }
        }

        for (final namespace in lib.namespaces.values) {
          for (final decl in namespace.declarations.values) {
            decl.resolve(namespace);
          }
        }

        if (config.sourceType == SourceType.module && invokeFunc != null) {
          final result = invoke(invokeFunc,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              errorHandled: true);
          return result;
        }
      } else {
        throw HTError.sourceType();
      }
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
      String? moduleAliasName,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) async {
    final fullName = sourceProvider.resolveFullName(key);

    if (config.reload || !sourceProvider.hasModule(fullName)) {
      final module = await sourceProvider.getSource(key,
          curModuleFullName: _curModuleFullName);

      final moduleName = moduleAliasName ?? module.fullName;
      _curNamespace = HTNamespace(this, id: moduleName, closure: coreNamespace);

      final result = await eval(module.content,
          moduleFullName: module.fullName,
          namespace: _curNamespace,
          config: config,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);

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
        HTClass klass = _curNamespace.memberGet(className);
        final func = klass.memberGet(funcName);

        if (func is HTFunction) {
          return func.call(
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          throw HTError.notCallable(funcName);
        }
      } else {
        func = _curNamespace.memberGet(funcName);
        if (func is HTFunction) {
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
  Future<Uint8List> compile(String content,
      {ParserConfig config = const ParserConfig()}) async {
    throw HTError(ErrorCode.extern, ErrorType.externalError,
        message: 'compile is currently unusable');
  }

  Future<dynamic> run(Uint8List code) async {}

  /// Load a pre-compiled bytecode in to module library.
  /// If [run] is true, then execute the bytecode immediately.
  dynamic load(Uint8List code, String moduleFullName,
      {bool run = true, int ip = 0}) {}

  /// Interpret a loaded module with the key of [moduleFullName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current value when encountered [OpCode.endOfExec] or [OpCode.endOfFunc].
  /// If [moduleFullName] != null, will return to original [HTBytecodeModule] module.
  /// If [ip] != null, will return to original [_code.ip].
  /// If [namespace] != null, will return to original [HTNamespace]
  ///
  /// Once changed into a new module, will open a new area of register space
  /// Every register space holds its own temporary values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute(
      {String? libraryName,
      String? moduleFullName,
      int? ip,
      HTNamespace? namespace,
      int? line,
      int? column}) {
    final savedLibraryName = _curLibraryName;
    final savedModuleFullName = _curModuleFullName;
    final savedIp = _code.ip;
    final savedNamespace = _curNamespace;

    var codeChanged = false;
    var ipChanged = false;
    var namespaceChanged = false;
    if (libraryName != null && (_curLibraryName != libraryName)) {
      _curLibraryName = libraryName;
      final module = _libs[libraryName]!;
      _code.changeCode(module.bytes);
      codeChanged = true;
      ipChanged = true;
    }
    if (moduleFullName != null && (_curModuleFullName != moduleFullName)) {
      _curModuleFullName = moduleFullName;
    }
    if (ip != null && _code.ip != ip) {
      _code.ip = ip;
      ipChanged = true;
    }
    if (namespace != null && _curNamespace != namespace) {
      _curNamespace = namespace;
      namespaceChanged = true;
    }

    ++_regIndex;
    if (_registers.length <= _regIndex * HTRegIdx.length) {
      _registers.length += HTRegIdx.length;
    }
    _curLine = line ?? 0;
    _curColumn = column ?? 0;

    final result = _execute();

    if (codeChanged) {
      _curLibraryName = savedLibraryName;
      final module = _libs[libraryName]!;
      _code.changeCode(module.bytes);
    }
    if (namespaceChanged) {
      _curModuleFullName = savedModuleFullName;
    }
    if (ipChanged) {
      _code.ip = savedIp;
    }
    if (namespaceChanged) {
      _curNamespace = savedNamespace;
    }

    --_regIndex;

    return result;
  }

  dynamic _execute() {
    var instruction = _code.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          _code.readUint32();
          break;
        case HTOpCode.version:
          final major = _code.read();
          final minor = _code.read();
          final patch = _code.readUint16();
          if (major != verMajor) {
            throw HTError.version(
                '$major.$minor.$patch', '$verMajor.$verMinor.$verPatch');
          }
          // _curCode.version = Version(major, minor, patch);
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          final index = _code.read();
          _setRegVal(index, _curValue);
          break;
        case HTOpCode.skip:
          final distance = _code.readInt16();
          _code.ip += distance;
          break;
        case HTOpCode.anchor:
          _curAnchor = _code.ip;
          break;
        case HTOpCode.goto:
          final distance = _code.readInt16();
          _code.ip = _curAnchor + distance;
          break;
        case HTOpCode.module:
          final id = _code.readShortUtf8String();
          _curModuleFullName = id;
          _curNamespace = HTNamespace(this, id: id, closure: coreNamespace);
          break;
        case HTOpCode.lineInfo:
          _curLine = _code.readUint16();
          _curColumn = _code.readUint16();
          break;
        case HTOpCode.loopPoint:
          final continueLength = _code.readUint16();
          final breakLength = _code.readUint16();
          _loops.add(_LoopInfo(_code.ip, _code.ip + continueLength,
              _code.ip + breakLength, _curNamespace));
          ++_curLoopCount;
          break;
        case HTOpCode.breakLoop:
          _code.ip = _loops.last.breakIp;
          _curNamespace = _loops.last.namespace;
          _loops.removeLast();
          --_curLoopCount;
          break;
        case HTOpCode.continueLoop:
          _code.ip = _loops.last.continueIp;
          _curNamespace = _loops.last.namespace;
          break;
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _code.readShortUtf8String();
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
          _curLoopCount = 0;
          return _curValue;
        case HTOpCode.endOfModule:
          return _curNamespace;
        case HTOpCode.constTable:
          final int64Length = _code.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _constTable.addInt(_code.readInt64());
          }
          final float64Length = _code.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _constTable.addFloat(_code.readFloat64());
          }
          final utf8StringLength = _code.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _constTable.addString(_code.readUtf8String());
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
          final thenBranchLength = _code.readUint16();
          if (!condition) {
            _code.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          final hasCondition = _code.readBool();
          if (hasCondition && !_curValue) {
            _code.ip = _loops.last.breakIp;
            _loops.removeLast();
            --_curLoopCount;
          }
          break;
        case HTOpCode.doStmt:
          if (_curValue) {
            _code.ip = _loops.last.startIp;
          }
          break;
        case HTOpCode.whenStmt:
          _handleWhenStmt();
          break;
        case HTOpCode.assign:
          final value = _getRegVal(HTRegIdx.assign);
          _curNamespace.memberSet(curSymbol!, value,
              from: _curNamespace.fullName);
          _curValue = value;
          break;
        case HTOpCode.memberSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final key = _getRegVal(HTRegIdx.postfixKey);
          final encap = encapsulate(object);
          encap.memberSet(key, _curValue, from: _curNamespace.fullName);
          break;
        case HTOpCode.subSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final key = execute();
          final value = execute();
          if (object == null || object == HTObject.NULL) {
            // TODO: object symbol?
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
          _handleUnaryPrefixOp(instruction);
          break;
        case HTOpCode.memberGet:
        case HTOpCode.subGet:
        case HTOpCode.call:
          _handleUnaryPostfixOp(instruction);
          break;
        default:
          throw HTError.unknownOpCode(instruction);
      }

      instruction = _code.read();
    }
  }

  // void _resolve() {}

  void _storeLocal() {
    final valueType = _code.read();
    switch (valueType) {
      case HTValueTypeCode.NULL:
        _curValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_code.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTValueTypeCode.constInt:
        final index = _code.readUint16();
        _curValue = _constTable.getInt64(index);
        break;
      case HTValueTypeCode.constFloat:
        final index = _code.readUint16();
        _curValue = _constTable.getFloat64(index);
        break;
      case HTValueTypeCode.constString:
        final index = _code.readUint16();
        _curValue = _constTable.getUtf8String(index);
        break;
      case HTValueTypeCode.symbol:
        final symbol = _curSymbol = _code.readShortUtf8String();
        final isLocal = _code.readBool();
        if (isLocal) {
          _curValue =
              _curNamespace.memberGet(symbol, from: _curNamespace.fullName);
          _curLeftValue = _curNamespace;
        } else {
          _curValue = symbol;
        }
        final hasTypeArgs = _code.readBool();
        if (hasTypeArgs) {
          final typeArgsLength = _code.read();
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
        final length = _code.readUint16();
        for (var i = 0; i < length; ++i) {
          final listItem = execute();
          list.add(listItem);
        }
        _curValue = list;
        break;
      case HTValueTypeCode.map:
        final map = {};
        final length = _code.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute();
          final value = execute();
          map[key] = value;
        }
        _curValue = map;
        break;
      case HTValueTypeCode.function:
        final id = _code.readShortUtf8String();

        final hasExternalTypedef = _code.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _code.readShortUtf8String();
        }

        final hasParamDecls = _code.readBool();
        final isVariadic = _code.readBool();
        final minArity = _code.read();
        final maxArity = _code.read();
        final paramDecls = _getParams(_code.read());

        int? line, column, definitionIp;
        final hasDefinition = _code.readBool();

        if (hasDefinition) {
          line = _code.readUint16();
          column = _code.readUint16();
          final length = _code.readUint16();
          definitionIp = _code.ip;
          _code.skip(length);
        }

        final func = HTFunction(id, _curModuleFullName, _curLibraryName, this,
            definitionIp: definitionIp,
            definitionLine: line,
            definitionColumn: column,
            category: FunctionCategory.literal,
            externalTypeId: externalTypedef,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
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

  void _handleWhenStmt() {
    var condition = _curValue;
    final hasCondition = _code.readBool();

    final casesCount = _code.read();
    final branchesIpList = <int>[];
    final cases = <dynamic, int>{};
    for (var i = 0; i < casesCount; ++i) {
      branchesIpList.add(_code.readUint16());
    }
    final elseBranchIp = _code.readUint16();
    final endIp = _code.readUint16();

    for (var i = 0; i < casesCount; ++i) {
      final value = execute();
      cases[value] = branchesIpList[i];
    }

    if (hasCondition) {
      if (cases.containsKey(condition)) {
        final distance = cases[condition]!;
        _code.skip(distance);
      } else if (elseBranchIp > 0) {
        _code.skip(elseBranchIp);
      } else {
        _code.skip(endIp);
      }
    } else {
      var condition = false;
      for (final key in cases.keys) {
        if (key) {
          final distance = cases[key]!;
          _code.skip(distance);
          condition = true;
          break;
        }
      }
      if (!condition) {
        if (elseBranchIp > 0) {
          _code.skip(elseBranchIp);
        } else {
          _code.skip(endIp);
        }
      }
    }
  }

  void _handleBinaryOp(int opcode) {
    switch (opcode) {
      case HTOpCode.logicalOr:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _code.readUint16();
        if (leftValue) {
          _code.skip(rightValueLength);
          _curValue = true;
        } else {
          final bool rightValue = execute();
          _curValue = rightValue;
        }
        break;
      case HTOpCode.logicalAnd:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _code.readUint16();
        if (leftValue) {
          final bool rightValue = execute();
          _curValue = leftValue && rightValue;
        } else {
          _code.skip(rightValueLength);
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
        final HTClass klass = curNamespace.memberGet(type.id);
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
    }
  }

  void _handleCallExpr() {
    final callee = _getRegVal(HTRegIdx.postfixObject);

    final positionalArgs = [];
    final positionalArgsLength = _code.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      positionalArgs.add(arg);
    }

    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _code.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _code.readShortUtf8String();
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      namedArgs[name] = arg;
    }

    final typeArgs = _curTypeArgs;

    if (callee is HTFunction) {
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
            callee.memberGet(HTLexicon.constructor) as HTFunction;
        _curValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        final constructor = callee.memberGet(callee.id) as HTFunction;
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
        _curLeftValue = encap;
        _curValue = encap.memberGet(key, from: _curNamespace.fullName);
        break;
      case HTOpCode.subGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        _curLeftValue = object;
        final key = execute();
        // final key = execute(moveRegIndex: true);
        _setRegVal(HTRegIdx.postfixKey, key);
        if (object is HTObject) {
          _curValue = object.subGet(key);
        } else {
          _curValue = object[key];
        }
        // _curRefType = _RefType.sub;
        break;
      case HTOpCode.call:
        _handleCallExpr();
        break;
    }
  }

  HTType _handleTypeExpr() {
    final index = _code.read();
    final typeType = TypeType.values.elementAt(index);

    switch (typeType) {
      case TypeType.normal:
        final typeName = _code.readShortUtf8String();
        final typeArgsLength = _code.read();
        final typeArgs = <HTType>[];
        for (var i = 0; i < typeArgsLength; ++i) {
          typeArgs.add(_handleTypeExpr());
        }
        final isNullable = (_code.read() == 0) ? false : true;
        return HTType(typeName, _curModuleFullName, _curLibraryName,
            typeArgs: typeArgs, isNullable: isNullable);
      case TypeType.function:
        final paramsLength = _code.read();
        final parameterTypes = <TypedParameterDeclaration>[];
        for (var i = 0; i < paramsLength; ++i) {
          final typeId = _code.readShortUtf8String();
          final length = _code.read();
          final typeArgs = <HTType>[];
          for (var i = 0; i < length; ++i) {
            typeArgs.add(_handleTypeExpr());
          }
          final isNullable = _code.read() == 0 ? false : true;
          final isOptional = _code.read() == 0 ? false : true;
          final isNamed = _code.read() == 0 ? false : true;
          String? paramId;
          if (isNamed) {
            paramId = _code.readShortUtf8String();
          }
          final isVariadic = _code.read() == 0 ? false : true;
          final decl = TypedParameterDeclaration(
              paramId ?? '', _curModuleFullName, _curLibraryName,
              declType: HTType(typeId, _curModuleFullName, _curLibraryName,
                  typeArgs: typeArgs, isNullable: isNullable),
              isOptional: isOptional,
              isNamed: isNamed,
              isVariadic: isVariadic);
          parameterTypes.add(decl);
        }
        final returnType = _handleTypeExpr();
        return HTFunctionType(_curModuleFullName, _curLibraryName,
            parameterDeclarations: parameterTypes, returnType: returnType);
      case TypeType.struct:
      case TypeType.interface:
      case TypeType.union:
        return HTType(
          _code.readShortUtf8String(),
          _curModuleFullName,
          _curLibraryName,
        );
    }
  }

  void _handleVarDecl() {
    final id = _code.readShortUtf8String();
    String? classId;
    final hasClassId = _code.readBool();
    if (hasClassId) {
      classId = _code.readShortUtf8String();
    }
    final isExternal = _code.readBool();
    final isStatic = _code.readBool();
    final isMutable = _code.readBool();
    final isConst = _code.readBool();
    final isExported = _code.readBool();
    final lateInitialize = _code.readBool();

    late final HTVariable decl;
    final hasInitializer = _code.readBool();
    if (hasInitializer) {
      if (lateInitialize) {
        final definitionLine = _code.readUint16();
        final definitionColumn = _code.readUint16();
        final length = _code.readUint16();
        final definitionIp = _code.ip;
        _code.skip(length);

        decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            isConst: isConst,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        final initValue = execute();

        decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
            classId: classId,
            value: initValue,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            isConst: isConst);
      }
    } else {
      decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
          classId: classId,
          isExternal: isExternal,
          isStatic: isStatic,
          isMutable: isMutable,
          isConst: isConst);
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
      final id = _code.readShortUtf8String();
      final isOptional = _code.readBool();
      final isNamed = _code.readBool();
      final isVariadic = _code.readBool();
      int? definitionIp;
      final hasInitializer = _code.readBool();
      if (hasInitializer) {
        final length = _code.readUint16();
        definitionIp = _code.ip;
        _code.skip(length);
      }

      paramDecls[id] = HTParameter(
          id, _curModuleFullName, _curLibraryName, this,
          definitionIp: definitionIp,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }

    return paramDecls;
  }

  void _handleFuncDecl() {
    final id = _code.readShortUtf8String();
    final declId = _code.readShortUtf8String();
    String? classId;
    final hasClassId = _code.readBool();
    if (hasClassId) {
      classId = _code.readShortUtf8String();
    }
    String? externalTypeId;
    final hasExternalTypedef = _code.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _code.readShortUtf8String();
    }
    final category = FunctionCategory.values[_code.read()];
    final isExternal = _code.readBool();
    final isStatic = _code.readBool();
    final isConst = _code.readBool();
    final isExported = _code.readBool();
    final hasParamDecls = _code.readBool();
    final isVariadic = _code.readBool();
    final minArity = _code.read();
    final maxArity = _code.read();
    final paramLength = _code.read();
    final paramDecls = _getParams(paramLength);

    ReferConstructor? referConstructor;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    if (category == FunctionCategory.constructor) {
      final hasRefCtor = _code.readBool();
      if (hasRefCtor) {
        final isSuper = _code.readBool();
        final hasCtorName = _code.readBool();
        String? name;
        if (hasCtorName) {
          name = _code.readShortUtf8String();
        }
        final positionalArgIpsLength = _code.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _code.readUint16();
          positionalArgIps.add(_code.ip);
          _code.skip(argLength);
        }
        final namedArgsLength = _code.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _code.readShortUtf8String();
          final argLength = _code.readUint16();
          namedArgIps[argName] = _code.ip;
          _code.skip(argLength);
        }
        referConstructor = ReferConstructor(
            isSuper: isSuper,
            name: name,
            positionalArgsIp: positionalArgIps,
            namedArgsIp: namedArgIps);
      }
    }

    int? line, column, definitionIp;
    final hasDefinition = _code.readBool();
    if (hasDefinition) {
      line = _code.readUint16();
      column = _code.readUint16();
      final length = _code.readUint16();
      definitionIp = _code.ip;
      _code.skip(length);
    }

    final func = HTFunction(id, _curModuleFullName, _curLibraryName, this,
        declId: declId,
        classId: classId,
        definitionIp: definitionIp,
        definitionLine: line,
        definitionColumn: column,
        category: category,
        isExternal: isExternal,
        externalTypeId: externalTypeId,
        hasParamDecls: hasParamDecls,
        paramDecls: paramDecls,
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
      // final decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
      //     value: func);
      _curClass!.defineInstanceMember(func);
    } else {
      // constructor are defined in class's namespace,
      // however its context is on instance.
      if (category != FunctionCategory.constructor) {
        func.context = _curNamespace;
      }
      // static methods are defined in class's namespace,
      // final decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
      //     value: func);
      _curNamespace.define(func);
    }
  }

  void _handleClassDecl() {
    final id = _code.readShortUtf8String();
    final isExternal = _code.readBool();
    final isAbstract = _code.readBool();
    final isExported = _code.readBool();
    HTType? superType;
    final hasSuperClass = _code.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != HTLexicon.object)) {
        superType = HTType.object;
      }
    }
    final klass = HTClass(
        id, _curModuleFullName, _curLibraryName, this, _curNamespace,
        superType: superType, isExternal: isExternal, isAbstract: isAbstract);
    _curNamespace.define(klass);
    _curClass = klass;
    final hasDefinition = _code.readBool();
    if (hasDefinition) {
      execute(namespace: klass.namespace);
    }
    // Add default constructor if non-exist.
    if (!isAbstract) {
      if (!isExternal) {
        if (!klass.namespace.contains(HTLexicon.constructor)) {
          final ctor = HTFunction(
              HTLexicon.constructor, _curModuleFullName, _curLibraryName, this,
              classId: klass.id, category: FunctionCategory.constructor);
          // final decl = HTVariable(
          //     ctor.id, _curModuleFullName, _curLibraryName, this,
          //     value: ctor);
          klass.namespace.define(ctor);
        }
      }
      // else {
      //   if (!klass.namespace.contains(klass.id)) {
      //     klass.namespace.define(HTBytecodeFunction(
      //         klass.id, this, _curModuleFullName,
      //         klass: klass, category: FunctionType.constructor));
      //   }
      // }
    }
    _curClass = null;
  }

  void _handleEnumDecl({String? classId}) {
    final id = _code.readShortUtf8String();
    final isExternal = _code.readBool();
    final length = _code.readUint16();

    var defs = <String, HTEnumItem>{};
    for (var i = 0; i < length; i++) {
      final enumId = _code.readShortUtf8String();
      defs[enumId] = HTEnumItem<int>(
          i,
          enumId,
          HTType(
            id,
            _curModuleFullName,
            _curLibraryName,
          ));
    }

    final enumClass = HTEnum(
        id, defs, _curModuleFullName, _curLibraryName, this,
        classId: classId, isExternal: isExternal);
    // final decl = HTVariable(id, _curModuleFullName, _curLibraryName, this,
    //     value: enumClass);
    _curNamespace.define(enumClass);
  }
}
