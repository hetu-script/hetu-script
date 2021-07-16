import 'dart:typed_data';

import '../binding/external_function.dart';
import '../declaration/namespace/namespace.dart';
import '../declaration/declaration.dart';
import '../object/object.dart';
import '../object/class/class.dart';
import '../object/instance/cast.dart';
import '../declaration/namespace/module.dart';
import '../object/function/function.dart';
import '../object/function/parameter.dart';
import '../object/variable/variable.dart';
import '../binding/external_class.dart';
// import '../parser/abstract_parser.dart';
// import '../parser/parser.dart';
import '../type/type.dart';
import '../type/unresolved_type.dart';
import '../type/function_type.dart';
import '../type/nominal_type.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../context/context.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../analyzer/analyzer.dart';
import 'abstract_interpreter.dart';
import 'compiler.dart';
import 'opcode.dart';
import 'bytecode_library.dart';

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

/// A bytecode implementation of a Hetu script interpreter
class Hetu extends HTAbstractInterpreter {
  static const verMajor = 0;
  static const verMinor = 1;
  static const verPatch = 0;

  @override
  final stackTrace = <String>[];

  final _cachedLibs = <String, HTBytecodeLibrary>{};

  @override
  InterpreterConfig config;

  @override
  HTContext context;

  @override
  ErrorHandlerConfig get errorConfig => config;

  var _curLine = 0;
  @override
  int get curLine => _curLine;

  var _curColumn = 0;
  @override
  int get curColumn => _curColumn;

  @override
  final HTNamespace global;

  late HTNamespace _curNamespace;
  @override
  HTNamespace get curNamespace => _curNamespace;

  late String _curModuleFullName;
  @override
  String get curModuleFullName => _curModuleFullName;

  late SourceType _curSourceType;

  @override
  SourceType get curSourceType => _curSourceType;

  late HTBytecodeLibrary _curLibrary;
  HTBytecodeLibrary get curLibrary => _curLibrary;

  HTClass? _curClass;
  HTFunction? _curFunction;

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
  String? get curSymbol => _registers[_getRegIndex(HTRegIdx.symbol)];
  // set  _curLeftValue(dynamic value) =>
  //     _registers[_getRegIndex(HTRegIdx.leftValue)] = value;
  // dynamic get curLeftValue =>
  //     _registers[_getRegIndex(HTRegIdx.leftValue)] ?? _curNamespace;
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

  late final HTAnalyzer analyzer;

  /// Create a bytecode interpreter.
  /// Each interpreter has a independent global [HTNamespace].
  Hetu({HTContext? context, this.config = const InterpreterConfig()})
      : global = HTNamespace(id: SemanticNames.global),
        context = context ?? HTContext.fileSystem() {
    _curNamespace = global;
    analyzer = HTAnalyzer(context: this.context);
  }

  @override
  void init(
      {Map<String, String> preincludes = const {},
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) {
    analyzer.init(
        preincludes: preincludes,
        externalClasses: externalClasses,
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef);
    super.init(
        preincludes: preincludes,
        externalClasses: externalClasses,
        externalFunctions: externalFunctions,
        externalFunctionTypedef: externalFunctionTypedef);
  }

  @override
  void handleError(Object error, {Object? externalStackTrace}) {
    final sb = StringBuffer();
    if (stackTrace.isNotEmpty && errorConfig.stackTrace) {
      sb.writeln('${HTLexicon.scriptStackTrace}${HTLexicon.colon}');
      if (stackTrace.length > errorConfig.hetuStackTraceThreshhold * 2) {
        for (var i = stackTrace.length - 1;
            i >= stackTrace.length - 1 - errorConfig.hetuStackTraceThreshhold;
            --i) {
          sb.writeln('#${stackTrace.length - 1 - i}\t${stackTrace[i]}');
        }
        sb.writeln('...\n...');
        for (var i = errorConfig.hetuStackTraceThreshhold - 1; i >= 0; --i) {
          sb.writeln('#${stackTrace.length - 1 - i}\t${stackTrace[i]}');
        }
      } else {
        for (var i = stackTrace.length - 1; i >= 0; --i) {
          sb.writeln('#${stackTrace.length - 1 - i}\t${stackTrace[i]}');
        }
      }
    }
    if (externalStackTrace != null) {
      sb.writeln('${HTLexicon.externalStackTrace}${HTLexicon.colon}');
      sb.writeln(externalStackTrace);
    }
    final stackTraceString = sb.toString().trimRight();
    if (error is HTError) {
      if (errorConfig.stackTrace) {
        error.extra = stackTraceString;
      }
      throw error;
    } else {
      var message = error.toString();
      final hetuError = HTError.extern(message,
          moduleFullName: _curModuleFullName, line: curLine, column: curColumn);
      hetuError.extra = stackTraceString;
      throw hetuError;
    }
  }

  /// Evaluate a string content.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  @override
  dynamic evalSource(HTSource source,
      {String? libraryName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    if (source.content.isEmpty) {
      return null;
    }
    _curSourceType = source.type;
    _curModuleFullName = source.fullName;
    try {
      final bytes = compileSource(source, errorHandled: true);
      if (bytes != null) {
        final result = loadBytecode(bytes, libraryName ?? source.fullName,
            globallyImport: globallyImport,
            invokeFunc: invokeFunc,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs,
            errorHandled: true);
        return result;
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, externalStackTrace: stackTrace);
      }
    }
  }

  /// Call a function within current [HTNamespace].
  @override
  dynamic invoke(String funcName,
      {String? libraryName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      if (libraryName != null) {
        _curLibrary = _cachedLibs[libraryName]!;
        _curNamespace = _curLibrary.declarations[libraryName]!;
      }
      final func = _curNamespace.memberGet(funcName, recursive: false);
      if (func is HTFunction) {
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        HTError.notCallable(funcName);
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, externalStackTrace: stackTrace);
      }
    }
  }

  /// Compile a script content into bytecode for later use.
  Uint8List? compileFile(String key,
      {String? libraryName,
      SourceType type = SourceType.module,
      bool isLibraryEntry = true,
      CompilerConfig? config,
      bool errorHandled = false}) {
    final source = context.getSource(key, type: type);
    final bytes = compileSource(source,
        libraryName: libraryName,
        isLibraryEntry: isLibraryEntry,
        config: config,
        errorHandled: errorHandled);
    return bytes;
  }

  /// Compile a [HTSource] into bytecode for later use.
  Uint8List? compileSource(HTSource source,
      {String? libraryName,
      bool isLibraryEntry = true,
      CompilerConfig? config,
      bool errorHandled = false}) {
    try {
      analyzer.evalSource(source);
      if (analyzer.errors.isNotEmpty) {
        for (final error in analyzer.errors) {
          if (errorHandled) {
            throw error;
          } else {
            handleError(error);
          }
        }
      }
      final compiler = HTCompiler(config: config);
      final bytes = compiler
          .compile(analyzer.compilation); //, libraryName ?? source.fullName);
      return bytes;
    } catch (error) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error);
      }
    }
  }

  /// Load a pre-compiled bytecode in to module library.
  /// If [invokeFunc] is true, execute the bytecode immediately.
  dynamic loadBytecode(Uint8List bytes, String libraryName,
      {bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      _curLibrary = HTBytecodeLibrary(libraryName, bytes);
      while (_curLibrary.ip < _curLibrary.bytes.length) {
        final HTNamespace nsp = execute();
        _curLibrary.define(nsp.id!, nsp);
      }
      _cachedLibs[_curLibrary.id] = _curLibrary;
      if (curSourceType == SourceType.script) {
        for (final nsp in _curLibrary.declarations.values) {
          // scripts defines its member on global
          global.import(nsp);
        }
        // return the last expression's value
        return _registers.first;
      } else if (curSourceType == SourceType.module) {
        // handles module imports
        for (final nsp in _curLibrary.declarations.values) {
          // final nsp = _curLibrary.declarations[module.fullName]!;
          for (final decl in nsp.imports.values) {
            final importNamespace = _curLibrary.declarations[decl.fullName]!;
            if (decl.alias == null) {
              if (decl.showList.isEmpty) {
                nsp.import(importNamespace);
              } else {
                for (final id in decl.showList) {
                  HTDeclaration decl =
                      importNamespace.memberGet(id, recursive: false);
                  nsp.define(id, decl);
                }
              }
            } else {
              if (decl.showList.isEmpty) {
                final aliasNamespace =
                    HTNamespace(id: decl.alias!, closure: global);
                aliasNamespace.import(importNamespace);
                nsp.define(decl.alias!, aliasNamespace);
              } else {
                final aliasNamespace =
                    HTNamespace(id: decl.alias!, closure: global);
                for (final id in decl.showList) {
                  HTDeclaration decl =
                      importNamespace.memberGet(id, recursive: false);
                  aliasNamespace.define(id, decl);
                }
                nsp.define(decl.alias!, aliasNamespace);
              }
            }
          }
        }
        _curNamespace = _curLibrary.declarations[libraryName]!;
        if (globallyImport) {
          global.import(_curNamespace);
        }
        for (final namespace in _curLibrary.declarations.values) {
          for (final decl in namespace.declarations.values) {
            decl.resolve();
          }
        }
        if (curSourceType == SourceType.module && invokeFunc != null) {
          final result = invoke(invokeFunc,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              errorHandled: true);
          return result;
        }
      } else {
        throw HTError.sourceType(moduleFullName: _curModuleFullName);
      }
    } catch (error) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error);
      }
    }
  }

  /// Interpret a loaded library with the key of [libraryName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current expression value
  /// when encountered [HTOpCode.endOfExec] or [HTOpCode.endOfFunc].
  ///
  /// Chaning library will create space for new register values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute(
      {String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      HTFunction? function,
      int? ip,
      int? line,
      int? column}) {
    final savedModuleFullName = _curModuleFullName;
    final savedLibrary = _curLibrary;
    final savedNamespace = _curNamespace;
    final savedFunction = _curFunction;
    final savedIp = _curLibrary.ip;
    final savedLine = _curLine;
    final savedColumn = _curColumn;
    var libChanged = false;
    var ipChanged = false;
    if (moduleFullName != null) {
      _curModuleFullName = moduleFullName;
    }
    if (libraryName != null && (_curLibrary.id != libraryName)) {
      _curLibrary = _cachedLibs[libraryName]!;
      libChanged = true;
    }
    if (namespace != null) {
      _curNamespace = namespace;
    }
    if (function != null) {
      _curFunction = function;
    }
    if (ip != null) {
      _curLibrary.ip = ip;
      ipChanged = true;
    } else if (libChanged) {
      _curLibrary.ip = 0;
      ipChanged = true;
    }
    if (line != null) {
      _curLine = line;
    } else if (libChanged) {
      _curLine = 0;
    }
    if (column != null) {
      _curColumn = column;
    } else if (libChanged) {
      _curColumn = 0;
    }
    ++_regIndex;
    if (_registers.length <= _regIndex * HTRegIdx.length) {
      _registers.length += HTRegIdx.length;
    }
    final result = _execute();
    _curModuleFullName = savedModuleFullName;
    _curLibrary = savedLibrary;
    _curNamespace = savedNamespace;
    _curFunction = savedFunction;
    if (ipChanged) {
      _curLibrary.ip = savedIp;
    }
    _curLine = savedLine;
    _curColumn = savedColumn;
    --_regIndex;
    return result;
  }

  dynamic _execute() {
    var instruction = _curLibrary.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.signature:
          _curLibrary.readUint32();
          break;
        case HTOpCode.version:
          final major = _curLibrary.read();
          final minor = _curLibrary.read();
          final patch = _curLibrary.readUint16();
          if (major != verMajor) {
            throw HTError.version(
                '$major.$minor.$patch', '$verMajor.$verMinor.$verPatch',
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          }
          // _curCode.version = Version(major, minor, patch);
          break;
        // 将字面量存储在本地变量中
        case HTOpCode.local:
          _storeLocal();
          break;
        // 将本地变量存入下一个字节代表的寄存器位置中
        case HTOpCode.register:
          final index = _curLibrary.read();
          _setRegVal(index, _curValue);
          break;
        case HTOpCode.skip:
          final distance = _curLibrary.readInt16();
          _curLibrary.ip += distance;
          break;
        case HTOpCode.anchor:
          _curAnchor = _curLibrary.ip;
          break;
        case HTOpCode.goto:
          final distance = _curLibrary.readInt16();
          _curLibrary.ip = _curAnchor + distance;
          break;
        case HTOpCode.module:
          final id = _curLibrary.readShortUtf8String();
          final isLibraryEntry = _curLibrary.readBool();
          _curModuleFullName = id;
          _curNamespace =
              HTModule(id, closure: global, isLibraryEntry: isLibraryEntry);
          break;
        case HTOpCode.lineInfo:
          _curLine = _curLibrary.readUint16();
          _curColumn = _curLibrary.readUint16();
          break;
        case HTOpCode.loopPoint:
          final continueLength = _curLibrary.readUint16();
          final breakLength = _curLibrary.readUint16();
          _loops.add(_LoopInfo(_curLibrary.ip, _curLibrary.ip + continueLength,
              _curLibrary.ip + breakLength, _curNamespace));
          ++_curLoopCount;
          break;
        case HTOpCode.breakLoop:
          _curLibrary.ip = _loops.last.breakIp;
          _curNamespace = _loops.last.namespace;
          _loops.removeLast();
          --_curLoopCount;
          break;
        case HTOpCode.continueLoop:
          _curLibrary.ip = _loops.last.continueIp;
          _curNamespace = _loops.last.namespace;
          break;
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _curLibrary.readShortUtf8String();
          _curNamespace = HTNamespace(id: id, closure: _curNamespace);
          break;
        case HTOpCode.endOfBlock:
          _curNamespace = _curNamespace.closure!;
          break;
        // 语句结束
        case HTOpCode.endOfStmt:
          _curValue = null;
          _curSymbol = null;
          // _curLeftValue = null;
          _curTypeArgs = [];
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
          final int64Length = _curLibrary.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _curLibrary.addInt(_curLibrary.readInt64());
          }
          final float64Length = _curLibrary.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _curLibrary.addFloat(_curLibrary.readFloat64());
          }
          final utf8StringLength = _curLibrary.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _curLibrary.addString(_curLibrary.readUtf8String());
          }
          break;
        case HTOpCode.importDecl:
          final key = _curLibrary.readShortUtf8String();
          String? alias;
          final hasAlias = _curLibrary.readBool();
          if (hasAlias) {
            alias = _curLibrary.readShortUtf8String();
          }
          final showList = <String>[];
          final showListLength = _curLibrary.read();
          for (var i = 0; i < showListLength; ++i) {
            final id = _curLibrary.readShortUtf8String();
            showList.add(id);
          }
          _curNamespace.declareImport(key, alias: alias, showList: showList);
          break;
        case HTOpCode.typeAliasDecl:
          _handleTypeAliasDecl();
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
          final thenBranchLength = _curLibrary.readUint16();
          if (!condition) {
            _curLibrary.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          if (!_curValue) {
            _curLibrary.ip = _loops.last.breakIp;
            _loops.removeLast();
            --_curLoopCount;
          }
          break;
        case HTOpCode.doStmt:
          final hasCondition = _curLibrary.readBool();
          if (hasCondition && _curValue) {
            _curLibrary.ip = _loops.last.startIp;
          }
          break;
        case HTOpCode.whenStmt:
          _handleWhenStmt();
          break;
        case HTOpCode.assign:
          final value = _getRegVal(HTRegIdx.assign);
          _curNamespace.memberSet(curSymbol!, value);
          _curValue = value;
          break;
        case HTOpCode.memberSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final key = _getRegVal(HTRegIdx.postfixKey);
          final encap = encapsulate(object);
          encap.memberSet(key, _curValue);
          break;
        case HTOpCode.subSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final key = execute();
          final value = execute();
          if (object == null || object == HTObject.NULL) {
            throw HTError.nullObject(
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          }
          object[key] = value;
          // if ((object is List) || (object is Map)) {
          //   object[key] = value;
          // } else if (object is HTObject) {
          //   object.subSet(key, value);
          // } else {
          //   final typeString = object.runtimeType.toString();
          //   final id = HTType.parseBaseType(typeString);
          //   final externClass = fetchExternalClass(id);
          //   externClass.instanceSubSet(object, key!, value);
          // }
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
        case HTOpCode.typeOf:
          _handleUnaryPrefixOp(instruction);
          break;
        case HTOpCode.memberGet:
        case HTOpCode.subGet:
        case HTOpCode.call:
          _handleUnaryPostfixOp(instruction);
          break;
        default:
          throw HTError.unknownOpCode(instruction,
              moduleFullName: _curModuleFullName,
              line: _curLine,
              column: _curColumn);
      }
      instruction = _curLibrary.read();
    }
  }

  void _storeLocal() {
    final valueType = _curLibrary.read();
    switch (valueType) {
      case HTValueTypeCode.NULL:
        _curValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_curLibrary.read() == 0) ? _curValue = false : _curValue = true;
        break;
      case HTValueTypeCode.constInt:
        final index = _curLibrary.readUint16();
        _curValue = _curLibrary.getInt64(index);
        break;
      case HTValueTypeCode.constFloat:
        final index = _curLibrary.readUint16();
        _curValue = _curLibrary.getFloat64(index);
        break;
      case HTValueTypeCode.constString:
        final index = _curLibrary.readUint16();
        _curValue = _curLibrary.getUtf8String(index);
        break;
      case HTValueTypeCode.stringInterpolation:
        var literal = _curLibrary.readUtf8String();
        final interpolationLength = _curLibrary.read();
        for (var i = 0; i < interpolationLength; ++i) {
          final value = execute();
          literal = literal.replaceAll('{$i}', value.toString());
        }
        _curValue = literal;
        break;
      case HTValueTypeCode.symbol:
        final symbol = _curSymbol = _curLibrary.readShortUtf8String();
        final isLocal = _curLibrary.readBool();
        if (isLocal) {
          _curValue = _curNamespace.memberGet(symbol);
          // _curLeftValue = _curNamespace;
        } else {
          _curValue = symbol;
        }
        // final hasTypeArgs = _curLibrary.readBool();
        // if (hasTypeArgs) {
        //   final typeArgsLength = _curLibrary.read();
        //   final typeArgs = <HTType>[];
        //   for (var i = 0; i < typeArgsLength; ++i) {
        //     final arg = _handleTypeExpr();
        //     typeArgs.add(arg);
        //   }
        //   _curTypeArgs = typeArgs;
        // }
        break;
      case HTValueTypeCode.group:
        _curValue = execute();
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = _curLibrary.readUint16();
        for (var i = 0; i < length; ++i) {
          final listItem = execute();
          list.add(listItem);
        }
        _curValue = list;
        break;
      case HTValueTypeCode.map:
        final map = {};
        final length = _curLibrary.readUint16();
        for (var i = 0; i < length; ++i) {
          final key = execute();
          final value = execute();
          map[key] = value;
        }
        _curValue = map;
        break;
      case HTValueTypeCode.function:
        final internalName = _curLibrary.readShortUtf8String();
        final hasExternalTypedef = _curLibrary.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _curLibrary.readShortUtf8String();
        }
        final hasParamDecls = _curLibrary.readBool();
        final isVariadic = _curLibrary.readBool();
        final minArity = _curLibrary.read();
        final maxArity = _curLibrary.read();
        final paramDecls = _getParams(_curLibrary.read());
        int? line, column, definitionIp;
        final hasDefinition = _curLibrary.readBool();
        if (hasDefinition) {
          line = _curLibrary.readUint16();
          column = _curLibrary.readUint16();
          final length = _curLibrary.readUint16();
          definitionIp = _curLibrary.ip;
          _curLibrary.skip(length);
        }
        final func = HTFunction(
            internalName, _curModuleFullName, _curLibrary.id, this,
            closure: _curNamespace,
            category: FunctionCategory.literal,
            externalTypeId: externalTypedef,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            definitionIp: definitionIp,
            definitionLine: line,
            definitionColumn: column,
            context: _curNamespace);
        if (!hasExternalTypedef) {
          _curValue = func;
        } else {
          final externalFunc = unwrapExternalFunctionType(func);
          _curValue = externalFunc;
        }
        break;
      case HTValueTypeCode.type:
        _curValue = _handleTypeExpr();
        break;
      default:
        throw HTError.unkownValueType(valueType,
            moduleFullName: _curModuleFullName,
            line: _curLine,
            column: _curColumn);
    }
  }

  void _handleWhenStmt() {
    var condition = _curValue;
    final hasCondition = _curLibrary.readBool();
    final casesCount = _curLibrary.read();
    final branchesIpList = <int>[];
    final cases = <dynamic, int>{};
    for (var i = 0; i < casesCount; ++i) {
      branchesIpList.add(_curLibrary.readUint16());
    }
    final elseBranchIp = _curLibrary.readUint16();
    final endIp = _curLibrary.readUint16();
    for (var i = 0; i < casesCount; ++i) {
      final value = execute();
      cases[value] = branchesIpList[i];
    }
    if (hasCondition) {
      if (cases.containsKey(condition)) {
        final distance = cases[condition]!;
        _curLibrary.skip(distance);
      } else if (elseBranchIp > 0) {
        _curLibrary.skip(elseBranchIp);
      } else {
        _curLibrary.skip(endIp);
      }
    } else {
      var condition = false;
      for (final key in cases.keys) {
        if (key) {
          final distance = cases[key]!;
          _curLibrary.skip(distance);
          condition = true;
          break;
        }
      }
      if (!condition) {
        if (elseBranchIp > 0) {
          _curLibrary.skip(elseBranchIp);
        } else {
          _curLibrary.skip(endIp);
        }
      }
    }
  }

  void _handleBinaryOp(int opcode) {
    switch (opcode) {
      case HTOpCode.logicalOr:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curLibrary.readUint16();
        if (leftValue) {
          _curLibrary.skip(rightValueLength);
          _curValue = true;
        } else {
          final bool rightValue = execute();
          _curValue = rightValue;
        }
        break;
      case HTOpCode.logicalAnd:
        final bool leftValue = _getRegVal(HTRegIdx.andLeft);
        final rightValueLength = _curLibrary.readUint16();
        if (leftValue) {
          final bool rightValue = execute();
          _curValue = leftValue && rightValue;
        } else {
          _curLibrary.skip(rightValueLength);
          _curValue = false;
        }
        break;
      case HTOpCode.equal:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _curValue = left == _curValue;
        break;
      case HTOpCode.notEqual:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _curValue = left != _curValue;
        break;
      case HTOpCode.lesser:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left < _curValue;
        break;
      case HTOpCode.greater:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left > _curValue;
        break;
      case HTOpCode.lesserOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left <= _curValue;
        break;
      case HTOpCode.greaterOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _curValue = left >= _curValue;
        break;
      case HTOpCode.typeAs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_curValue as HTType).resolve(_curNamespace);
        final HTClass klass = curNamespace.memberGet(type.id);
        _curValue = HTCast(object, klass, this);
        break;
      case HTOpCode.typeIs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_curValue as HTType).resolve(_curNamespace);
        final encapsulated = encapsulate(object);
        _curValue = encapsulated.valueType.isA(type);
        break;
      case HTOpCode.typeIsNot:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_curValue as HTType).resolve(_curNamespace);
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
      case HTOpCode.typeOf:
        final encap = encapsulate(object);
        _curValue = encap.valueType;
        break;
    }
  }

  void _handleCallExpr() {
    var callee = _getRegVal(HTRegIdx.postfixObject);
    final positionalArgs = [];
    final positionalArgsLength = _curLibrary.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final arg = execute();
      positionalArgs.add(arg);
    }
    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _curLibrary.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _curLibrary.readShortUtf8String();
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
    }
    // calle is a dart function
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
    } else if ((callee is HTClass) || (callee is HTType)) {
      late HTClass klass;
      if (callee is HTType) {
        final resolvedType = callee.resolve(_curNamespace);
        if (resolvedType is! HTNominalType) {
          throw HTError.notCallable(callee.toString(),
              moduleFullName: _curModuleFullName,
              line: _curLine,
              column: _curColumn);
        }
        klass = resolvedType.klass as HTClass;
      } else {
        klass = callee;
      }
      if (klass.isAbstract) {
        throw HTError.abstracted(
            moduleFullName: _curModuleFullName,
            line: _curLine,
            column: _curColumn);
      }
      if (klass.contains(SemanticNames.constructor)) {
        final constructor =
            klass.memberGet(SemanticNames.constructor) as HTFunction;
        _curValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(klass.id!,
            moduleFullName: _curModuleFullName,
            line: _curLine,
            column: _curColumn);
      }
    } else {
      throw HTError.notCallable(callee.toString(),
          moduleFullName: _curModuleFullName,
          line: _curLine,
          column: _curColumn);
    }
  }

  void _handleUnaryPostfixOp(int op) {
    switch (op) {
      case HTOpCode.memberGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        final key = _getRegVal(HTRegIdx.postfixKey);
        final encap = encapsulate(object);
        // _curLeftValue = encap;
        _curValue = encap.memberGet(key);
        break;
      case HTOpCode.subGet:
        final object = _getRegVal(HTRegIdx.postfixObject);
        // _curLeftValue = object;
        final key = execute();
        // final key = execute(moveRegIndex: true);
        // _setRegVal(HTRegIdx.postfixKey, key);
        // if (object is HTObject) {
        //   _curValue = object.subGet(key);
        // } else {
        _curValue = object[key];
        // }
        // _curRefType = _RefType.sub;
        break;
      case HTOpCode.call:
        _handleCallExpr();
        break;
    }
  }

  HTType _handleTypeExpr() {
    final index = _curLibrary.read();
    final typeType = TypeType.values.elementAt(index);
    switch (typeType) {
      case TypeType.normal:
        final typeName = _curLibrary.readShortUtf8String();
        final typeArgsLength = _curLibrary.read();
        final typeArgs = <HTUnresolvedType>[];
        for (var i = 0; i < typeArgsLength; ++i) {
          final typearg = _handleTypeExpr() as HTUnresolvedType;
          typeArgs.add(typearg);
        }
        final isNullable = (_curLibrary.read() == 0) ? false : true;
        return HTUnresolvedType(typeName,
            typeArgs: typeArgs, isNullable: isNullable);
      case TypeType.function:
        final paramsLength = _curLibrary.read();
        final parameterTypes = <HTParameterType>[];
        for (var i = 0; i < paramsLength; ++i) {
          final declType = _handleTypeExpr();
          final isOptional = _curLibrary.read() == 0 ? false : true;
          final isVariadic = _curLibrary.read() == 0 ? false : true;
          final isNamed = _curLibrary.read() == 0 ? false : true;
          String? paramId;
          if (isNamed) {
            paramId = _curLibrary.readShortUtf8String();
          }
          final decl = HTParameterType(declType,
              isOptional: isOptional, isVariadic: isVariadic, id: paramId);
          parameterTypes.add(decl);
        }
        final returnType = _handleTypeExpr();
        return HTFunctionType(
            parameterTypes: parameterTypes, returnType: returnType);
      case TypeType.struct:
      case TypeType.interface:
      case TypeType.union:
        return HTUnresolvedType(_curLibrary.readShortUtf8String());
    }
  }

  void _handleTypeAliasDecl() {
    final id = _curLibrary.readShortUtf8String();
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _curLibrary.readShortUtf8String();
    }
    final isExported = _curLibrary.readBool();
    final value = _handleTypeExpr();
    final decl = HTVariable(id, this, _curModuleFullName, _curLibrary.id,
        classId: classId,
        closure: _curNamespace,
        initValue: value,
        isExported: isExported);
    _curNamespace.define(id, decl);
  }

  void _handleVarDecl() {
    final id = _curLibrary.readShortUtf8String();
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _curLibrary.readShortUtf8String();
    }
    final isExternal = _curLibrary.readBool();
    final isStatic = _curLibrary.readBool();
    final isMutable = _curLibrary.readBool();
    final isConst = _curLibrary.readBool();
    final isExported = _curLibrary.readBool();
    final lateInitialize = _curLibrary.readBool();
    HTType? declType;
    final hasTypeDecl = _curLibrary.readBool();
    if (hasTypeDecl) {
      declType = _handleTypeExpr();
    }
    late final HTVariable decl;
    final hasInitializer = _curLibrary.readBool();
    if (hasInitializer) {
      if (lateInitialize) {
        final definitionLine = _curLibrary.readUint16();
        final definitionColumn = _curLibrary.readUint16();
        final length = _curLibrary.readUint16();
        final definitionIp = _curLibrary.ip;
        _curLibrary.skip(length);
        decl = HTVariable(id, this, _curModuleFullName, _curLibrary.id,
            classId: classId,
            closure: _curNamespace,
            declType: declType,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable,
            isExported: isExported,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        final value = execute();
        decl = HTVariable(id, this, _curModuleFullName, _curLibrary.id,
            classId: classId,
            closure: _curNamespace,
            declType: declType,
            initValue: value,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable,
            isExported: isExported);
      }
    } else {
      decl = HTVariable(id, this, _curModuleFullName, _curLibrary.id,
          classId: classId,
          closure: _curNamespace,
          declType: declType,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          isMutable: isMutable,
          isExported: isExported);
    }
    _curNamespace.define(id, decl);
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};
    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _curLibrary.readShortUtf8String();
      final isOptional = _curLibrary.readBool();
      final isVariadic = _curLibrary.readBool();
      final isNamed = _curLibrary.readBool();
      HTType? declType;
      final hasTypeDecl = _curLibrary.readBool();
      if (hasTypeDecl) {
        declType = _handleTypeExpr();
      }
      int? definitionIp;
      int? definitionLine;
      int? definitionColumn;
      final hasInitializer = _curLibrary.readBool();
      if (hasInitializer) {
        definitionLine = _curLibrary.readUint16();
        definitionColumn = _curLibrary.readUint16();
        final length = _curLibrary.readUint16();
        definitionIp = _curLibrary.ip;
        _curLibrary.skip(length);
      }
      paramDecls[id] = HTParameter(id, this, _curModuleFullName, _curLibrary.id,
          closure: _curNamespace,
          declType: declType,
          definitionIp: definitionIp,
          definitionLine: definitionLine,
          definitionColumn: definitionColumn,
          isOptional: isOptional,
          isNamed: isNamed,
          isVariadic: isVariadic);
    }
    return paramDecls;
  }

  void _handleFuncDecl() {
    final internalName = _curLibrary.readShortUtf8String();
    String? id;
    final hasId = _curLibrary.readBool();
    if (hasId) {
      id = _curLibrary.readShortUtf8String();
    }
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _curLibrary.readShortUtf8String();
    }
    String? externalTypeId;
    final hasExternalTypedef = _curLibrary.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _curLibrary.readShortUtf8String();
    }
    final category = FunctionCategory.values[_curLibrary.read()];
    final isExternal = _curLibrary.readBool();
    final isStatic = _curLibrary.readBool();
    final isConst = _curLibrary.readBool();
    final isExported = _curLibrary.readBool();
    final hasParamDecls = _curLibrary.readBool();
    final isVariadic = _curLibrary.readBool();
    final minArity = _curLibrary.read();
    final maxArity = _curLibrary.read();
    final paramLength = _curLibrary.read();
    final paramDecls = _getParams(paramLength);
    RedirectingConstructor? redirCtor;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    if (category == FunctionCategory.constructor) {
      final hasRefCtor = _curLibrary.readBool();
      if (hasRefCtor) {
        final calleeId = _curLibrary.readShortUtf8String();
        final hasCtorName = _curLibrary.readBool();
        String? ctorName;
        if (hasCtorName) {
          ctorName = _curLibrary.readShortUtf8String();
        }
        final positionalArgIpsLength = _curLibrary.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _curLibrary.readUint16();
          positionalArgIps.add(_curLibrary.ip);
          _curLibrary.skip(argLength);
        }
        final namedArgsLength = _curLibrary.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _curLibrary.readShortUtf8String();
          final argLength = _curLibrary.readUint16();
          namedArgIps[argName] = _curLibrary.ip;
          _curLibrary.skip(argLength);
        }
        redirCtor = RedirectingConstructor(calleeId,
            key: ctorName,
            positionalArgsIp: positionalArgIps,
            namedArgsIp: namedArgIps);
      }
    }
    int? line, column, definitionIp;
    final hasDefinition = _curLibrary.readBool();
    if (hasDefinition) {
      line = _curLibrary.readUint16();
      column = _curLibrary.readUint16();
      final length = _curLibrary.readUint16();
      definitionIp = _curLibrary.ip;
      _curLibrary.skip(length);
    }
    final func = HTFunction(
        internalName, _curModuleFullName, _curLibrary.id, this,
        id: id,
        classId: classId,
        closure: _curNamespace,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        isExported: isExported,
        category: category,
        externalTypeId: externalTypeId,
        hasParamDecls: hasParamDecls,
        paramDecls: paramDecls,
        isVariadic: isVariadic,
        minArity: minArity,
        maxArity: maxArity,
        definitionIp: definitionIp,
        definitionLine: line,
        definitionColumn: column,
        redirectingConstructor: redirCtor);
    if ((category != FunctionCategory.constructor) || isStatic) {
      func.context = _curNamespace;
    }
    _curNamespace.define(func.internalName, func);
  }

  void _handleClassDecl() {
    final id = _curLibrary.readShortUtf8String();
    final isExternal = _curLibrary.readBool();
    final isAbstract = _curLibrary.readBool();
    final isExported = _curLibrary.readBool();
    final hasUserDefinedConstructor = _curLibrary.readBool();
    HTType? superType;
    final hasSuperClass = _curLibrary.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != HTLexicon.object)) {
        superType = HTObject.type;
      }
    }
    final klass = HTClass(this,
        id: id,
        closure: _curNamespace,
        superType: superType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isExported: isExported);
    _curNamespace.define(id, klass);
    final savedClass = _curClass;
    _curClass = klass;
    // deal with definition block
    execute(namespace: klass.namespace);
    // Add default constructor if non-exist.
    if (!isAbstract) {
      if (!hasUserDefinedConstructor) {
        final ctor = HTFunction(
            SemanticNames.constructor, _curModuleFullName, _curLibrary.id, this,
            classId: klass.id,
            category: FunctionCategory.constructor,
            closure: klass.namespace);
        klass.namespace.define(SemanticNames.constructor, ctor);
      }
    }
    if (curSourceType == SourceType.script || _curFunction != null) {
      klass.resolve();
    }
    _curClass = savedClass;
  }
}
