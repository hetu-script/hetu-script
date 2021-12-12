import 'dart:typed_data';

import '../binding/external_function.dart';
import '../declaration/namespace/namespace.dart';
import '../declaration/declaration.dart';
import '../value/struct/named_struct.dart';
import '../value/entity.dart';
import '../value/class/class.dart';
import '../value/instance/cast.dart';
import '../value/function/function.dart';
import '../value/function/parameter.dart';
import '../value/variable/variable.dart';
import '../value/struct/struct.dart';
import '../value/external_enum/external_enum.dart';
import '../binding/external_class.dart';
import '../type/type.dart';
import '../type/unresolved_type.dart';
import '../type/function_type.dart';
import '../type/nominal_type.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../source/source.dart';
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../analyzer/analyzer.dart';
import '../parser/parser.dart';
import 'abstract_interpreter.dart';
import 'compiler.dart';
import 'constants.dart';
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
  @override
  final stackTrace = <String>[];

  final _cachedLibs = <String, HTBytecodeLibrary>{};

  late final HTAnalyzer analyzer;

  @override
  InterpreterConfig config;

  HTResourceContext<HTSource> _sourceContext;

  @override
  HTResourceContext<HTSource> get sourceContext => _sourceContext;

  set sourceContext(HTResourceContext<HTSource> context) {
    analyzer.sourceContext = _sourceContext = context;
  }

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

  String _curModuleFullName = '';
  @override
  String get curModuleFullName => _curModuleFullName;

  late bool _isScript;

  late HTBytecodeLibrary _curLibrary;
  HTBytecodeLibrary get curLibrary => _curLibrary;

  HTClass? _curClass;
  HTFunction? _curFunction;

  bool _isStrictMode = false;

  var _currentStackIndex = -1;

  /// Register values are stored by groups.
  /// Every group have 16 values, they are HTRegIdx.
  /// A such group can be understanded as the stack frame of a runtime function.
  final _stackFrames = <List>[];

  void _setRegVal(int index, dynamic value) =>
      _stackFrames[_currentStackIndex][index] = value;
  dynamic _getRegVal(int index) => _stackFrames[_currentStackIndex][index];
  set _curValue(dynamic value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.value] = value;
  dynamic get _curValue => _stackFrames[_currentStackIndex][HTRegIdx.value];
  set _curSymbol(String? value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.identifier] = value;
  String? get curSymbol =>
      _stackFrames[_currentStackIndex][HTRegIdx.identifier];
  set _curTypeArgs(List<HTType> value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.typeArgs] = value;
  List<HTType> get _curTypeArgs =>
      _stackFrames[_currentStackIndex][HTRegIdx.typeArgs] ?? const [];
  set _curLoopCount(int value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.loopCount] = value;
  int get _curLoopCount =>
      _stackFrames[_currentStackIndex][HTRegIdx.loopCount] ?? 0;
  set _curAnchor(int value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.anchor] = value;
  int get _curAnchor => _stackFrames[_currentStackIndex][HTRegIdx.anchor] ?? 0;

  /// Loop point is stored as stack form.
  /// Break statement will jump to the last loop point,
  /// and remove it from this stack.
  /// Return statement will clear loop points by
  /// [_curLoopCount] in current stack frame.
  final _loops = <_LoopInfo>[];

  bool _isZero(dynamic condition) {
    if (_isStrictMode) {
      return condition == 0;
    } else {
      return condition == 0 || condition == null;
    }
  }

  bool _truthy(dynamic condition) {
    if (_isStrictMode) {
      return condition;
    } else {
      if ((condition is bool && !condition) ||
          condition == null ||
          condition == 0 ||
          condition == '' ||
          condition == '0' ||
          condition == 'false' ||
          (condition is List && condition.isEmpty) ||
          (condition is Map && condition.isEmpty) ||
          (condition is HTStruct && condition.isEmpty)) {
        return false;
      } else {
        return true;
      }
    }
  }

  /// A bytecode interpreter.
  Hetu(
      {HTResourceContext<HTSource>? sourceContext,
      this.config = const InterpreterConfig()})
      : global = HTNamespace(id: SemanticNames.global),
        _sourceContext = sourceContext ?? HTOverlayContext() {
    _curNamespace = global;
    analyzer = HTAnalyzer(sourceContext: this.sourceContext);
  }

  @override
  void init({
    Map<String, String> includes = const {},
    Map<String, Function> externalFunctions = const {},
    Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
    List<HTExternalClass> externalClasses = const [],
  }) {
    if (config.doStaticAnalyze) {
      analyzer.init(includes: includes);
    }
    super.init(
      includes: includes,
      externalFunctions: externalFunctions,
      externalFunctionTypedef: externalFunctionTypedef,
      externalClasses: externalClasses,
    );
  }

  @override
  void handleError(Object error, {Object? externalStackTrace}) {
    final sb = StringBuffer();
    if (stackTrace.isNotEmpty && errorConfig.showDartStackTrace) {
      sb.writeln('${HTLexicon.scriptStackTrace}${HTLexicon.colon}');
      if (stackTrace.length > errorConfig.hetuStackTraceDisplayCountLimit * 2) {
        for (var i = stackTrace.length - 1;
            i >=
                stackTrace.length -
                    1 -
                    errorConfig.hetuStackTraceDisplayCountLimit;
            --i) {
          sb.writeln('#${stackTrace.length - 1 - i}\t${stackTrace[i]}');
        }
        sb.writeln('...\n...');
        for (var i = errorConfig.hetuStackTraceDisplayCountLimit - 1;
            i >= 0;
            --i) {
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
      final wrappedError = HTError(
        error.code,
        error.type,
        message: error.message,
        extra: errorConfig.showDartStackTrace ? stackTraceString : null,
        moduleFullName: error.moduleFullName ?? _curModuleFullName,
        line: error.line ?? _curLine,
        column: error.column ?? _curColumn,
      );
      throw wrappedError;
    } else {
      final hetuError = HTError.extern(
        error.toString(),
        extra: errorConfig.showDartStackTrace ? stackTraceString : null,
        moduleFullName: _curModuleFullName,
        line: curLine,
        column: curColumn,
      );
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
      bool isStrictMode = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    if (source.content.isEmpty) {
      return null;
    }
    _isScript = source.isScript;
    _curModuleFullName = source.name;
    _isStrictMode = isStrictMode;
    try {
      final bytes = compileSource(
        source,
        libraryName: libraryName,
        config: config,
        errorHandled: true,
      );
      final result = loadBytecode(bytes, libraryName ?? source.name,
          globallyImport: globallyImport,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs,
          errorHandled: true);
      return result;
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

  bool switchLibrary(String id) {
    if (_cachedLibs.containsKey(id)) {
      newStackFrame(libraryName: id);
      return true;
    } else {
      return false;
    }
  }

  /// Compile a [HTSource] into bytecode for later use.
  Uint8List compileSource(HTSource source,
      {String? libraryName,
      CompilerConfig? config,
      bool errorHandled = false}) {
    try {
      final compileConfig = config ?? this.config;
      final compiler = HTCompiler(config: compileConfig);
      if (compileConfig.doStaticAnalyze) {
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
        final bytes = compiler
            .compile(analyzer.compilation); //, libraryName ?? source.fullName);
        return bytes;
      } else {
        final parser = HTParser(context: _sourceContext);
        final compilation =
            parser.parseToCompilation(source, libraryName: libraryName);
        final bytes =
            compiler.compile(compilation); //, libraryName ?? source.fullName);
        return bytes;
      }
    } catch (error) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error);
        return Uint8List.fromList([]);
      }
    }
  }

  Uint8List? compile(String content,
      {String? moduleFullName,
      String? libraryName,
      bool isScript = false,
      bool errorHandled = false}) {
    final source = HTSource(content,
        name: moduleFullName, isScript: isScript ? true : false);
    final result = compileSource(source,
        libraryName: libraryName, errorHandled: errorHandled);
    return result;
  }

  /// Compile a script content into bytecode for later use.
  Uint8List? compileFile(String key,
      {String? libraryName,
      CompilerConfig? config,
      bool errorHandled = false}) {
    final source = _sourceContext.getResource(key);
    final bytes = compileSource(source,
        libraryName: libraryName, config: config, errorHandled: errorHandled);
    return bytes;
  }

  /// Load a pre-compiled bytecode in to module library.
  /// If [invokeFunc] is true, execute the bytecode immediately.
  dynamic loadBytecode(Uint8List bytes, String libraryName,
      {bool globallyImport = false,
      bool isStrictMode = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    _isStrictMode = isStrictMode;
    try {
      _curLibrary = HTBytecodeLibrary(libraryName, bytes);
      while (_curLibrary.ip < _curLibrary.bytes.length) {
        final HTNamespace nsp = execute();
        _curLibrary.define(nsp.id!, nsp);
      }
      if (_isScript) {
        if (globallyImport) {
          for (final nsp in _curLibrary.declarations.values) {
            global.import(nsp);
          }
        }
        // return the last expression's value
        return _stackFrames.first.first;
      } else {
        _cachedLibs[_curLibrary.id] = _curLibrary;
        // handles module imports
        for (final nsp in _curLibrary.declarations.values) {
          for (final decl in nsp.imports.values) {
            final importNamespace = _curLibrary.declarations[decl.fullName]!;
            if (decl.alias == null) {
              if (decl.showList.isEmpty) {
                nsp.import(importNamespace,
                    isExported: decl.isExported, showList: decl.showList);
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
        _curNamespace = _curLibrary.declarations.values.last;
        if (globallyImport) {
          global.import(_curNamespace);
        }
        // resolve each declaration after we get all declarations
        for (final namespace in _curLibrary.declarations.values) {
          for (final decl in namespace.declarations.values) {
            decl.resolve();
          }
        }
        if (!_isScript && invokeFunc != null) {
          final result = invoke(invokeFunc,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              errorHandled: true);
          return result;
        }
      }
      // else {
      //   throw HTError.sourceType(moduleFullName: _curModuleFullName);
      // }
    } catch (error) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error);
      }
    }
  }

  void newStackFrame(
      {String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      HTFunction? function,
      int? ip,
      int? line,
      int? column}) {
    // var ipChanged = false;
    var libChanged = false;
    if (moduleFullName != null) {
      _curModuleFullName = moduleFullName;
    }
    if (libraryName != null && (_curLibrary.id != libraryName)) {
      _curLibrary = _cachedLibs[libraryName]!;
      libChanged = true;
    }
    if (namespace != null) {
      _curNamespace = namespace;
    } else if (libChanged) {
      _curNamespace = _curLibrary.declarations.values.last;
    }
    if (function != null) {
      _curFunction = function;
    }
    if (ip != null) {
      _curLibrary.ip = ip;
    } else if (libChanged) {
      _curLibrary.ip = 0;
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
    ++_currentStackIndex;
    if (_stackFrames.length <= _currentStackIndex) {
      _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
    }
  }

  void restoreStackFrame(
      {String? savedModuleFullName,
      String? savedLibraryName,
      HTNamespace? savedNamespace,
      HTFunction? savedFunction,
      int? savedIp,
      int? savedLine,
      int? savedColumn}) {
    if (savedModuleFullName != null) {
      _curModuleFullName = savedModuleFullName;
    }
    if (savedLibraryName != null) {
      if (_curLibrary.id != savedLibraryName) {
        _curLibrary = _cachedLibs[savedLibraryName]!;
      }
    }
    if (savedNamespace != null) {
      _curNamespace = savedNamespace;
    }
    if (savedFunction != null) {
      _curFunction = savedFunction;
    }
    if (savedIp != null) {
      _curLibrary.ip = savedIp;
    }
    if (savedLine != null) {
      _curLine = savedLine;
    }
    if (savedColumn != null) {
      _curColumn = savedColumn;
    }
    --_currentStackIndex;
  }

  /// Interpret a loaded library with the key of [libraryName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current expression value
  /// when encountered [HTOpCode.endOfExec] or [HTOpCode.endOfFunc].
  ///
  /// Changing library will create new stack frame for new register values.
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
    ++_currentStackIndex;
    if (_stackFrames.length <= _currentStackIndex) {
      _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
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
    --_currentStackIndex;
    return result;
  }

  String _readString() {
    final isLocal = _curLibrary.readBool();
    if (isLocal) {
      return _curLibrary.readUtf8String();
    } else {
      final index = _curLibrary.readUint16();
      return _curLibrary.getUtf8String(index);
    }
  }

  dynamic _execute() {
    var instruction = _curLibrary.read();
    while (instruction != HTOpCode.endOfFile) {
      switch (instruction) {
        case HTOpCode.lineInfo:
          _curLine = _curLibrary.readUint16();
          _curColumn = _curLibrary.readUint16();
          break;
        case HTOpCode.meta:
          final signature = _curLibrary.readUint32();
          if (signature != HTCompiler.hetuSignature) {
            throw HTError.bytecode(
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          }
          final major = _curLibrary.read();
          final minor = _curLibrary.read();
          final patch = _curLibrary.readUint16();
          var incompatible = false;
          if (major > 0) {
            if (major != HTCompiler.version.major) {
              incompatible = true;
            }
          } else {
            if (major != HTCompiler.version.major ||
                minor != HTCompiler.version.minor ||
                patch != HTCompiler.version.patch) {
              incompatible = true;
            }
          }
          if (incompatible) {
            throw HTError.version(
                '$major.$minor.$patch', '${HTCompiler.version}',
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          }
          _isScript = _curLibrary.readBool();
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
          final id = _readString();
          // final hasMetaInfo = _curLibrary.readBool();
          _curModuleFullName = id;
          _curNamespace = HTNamespace(id: id, closure: global);
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
        case HTOpCode.assertion:
          final text = _readString();
          final value = execute();
          if (!value) {
            throw HTError.assertionFailed(text);
          }
          break;
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _readString();
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
        case HTOpCode.importExportDecl:
          _handleImportExport();
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
        case HTOpCode.externalEnumDecl:
          _handleExternalEnumDecl();
          break;
        case HTOpCode.structDecl:
          _handleStructDecl();
          break;
        case HTOpCode.varDecl:
          _handleVarDecl();
          break;
        case HTOpCode.ifStmt:
          final thenBranchLength = _curLibrary.readUint16();
          final truthValue = _truthy(_curValue);
          if (!truthValue) {
            _curLibrary.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          final truthValue = _truthy(_curValue);
          if (!truthValue) {
            _curLibrary.ip = _loops.last.breakIp;
            _loops.removeLast();
            --_curLoopCount;
          }
          break;
        case HTOpCode.doStmt:
          final hasCondition = _curLibrary.readBool();
          if (hasCondition) {
            final truthValue = _truthy(_curValue);
            if (truthValue) {
              _curLibrary.ip = _loops.last.startIp;
            }
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
          if (object == null) {
            throw HTError.nullObject(
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          } else {
            final key = _getRegVal(HTRegIdx.postfixKey);
            final value = execute();
            final encap = encapsulate(object);
            encap.memberSet(key, value);
          }
          break;
        case HTOpCode.subSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          if (object == null) {
            throw HTError.nullObject(
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          } else {
            final key = execute();
            final value = execute();
            if (object is HTEntity) {
              object.subSet(key, value);
            } else {
              if (object is List) {
                if (key is! int) {
                  throw HTError.subGetKey(
                      moduleFullName: _curModuleFullName,
                      line: _curLine,
                      column: _curColumn);
                } else if (key >= object.length) {
                  throw HTError.outOfRange(key, object.length,
                      moduleFullName: _curModuleFullName,
                      line: _curLine,
                      column: _curColumn);
                }
                object[key] = value;
              }
            }
            _curValue = value;
          }
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
          final object = _getRegVal(HTRegIdx.postfixObject);
          if (object == null) {
            throw HTError.nullObject(
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          } else {
            final key = _getRegVal(HTRegIdx.postfixKey);
            final encap = encapsulate(object);
            _curValue = encap.memberGet(key);
          }
          break;
        case HTOpCode.subGet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          if (object == null) {
            throw HTError.nullObject(
                moduleFullName: _curModuleFullName,
                line: _curLine,
                column: _curColumn);
          } else {
            final key = execute();
            if (object is HTEntity) {
              _curValue = object.subGet(key);
            } else {
              if (object is List) {
                if (key is! int) {
                  throw HTError.subGetKey(
                      moduleFullName: _curModuleFullName,
                      line: _curLine,
                      column: _curColumn);
                } else if (key >= object.length) {
                  throw HTError.outOfRange(key, object.length,
                      moduleFullName: _curModuleFullName,
                      line: _curLine,
                      column: _curColumn);
                }
              }
              _curValue = object[key];
            }
          }
          break;
        case HTOpCode.call:
          _handleCallExpr();
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

  void _handleImportExport() {
    final isExported = _curLibrary.readBool();
    final showList = <String>[];
    final showListLength = _curLibrary.read();
    for (var i = 0; i < showListLength; ++i) {
      final id = _readString();
      showList.add(id);
      if (isExported) {
        _curNamespace.declareExport(id);
      }
    }
    final hasFromPath = _curLibrary.readBool();
    String? fromPath;
    if (hasFromPath) {
      fromPath = _readString();
    }
    String? alias;
    final hasAlias = _curLibrary.readBool();
    if (hasAlias) {
      alias = _readString();
    }
    if (fromPath != null) {
      _curNamespace.declareImport(
        fromPath,
        alias: alias,
        showList: showList,
        isExported: isExported,
      );
    }
  }

  void _storeLocal() {
    final valueType = _curLibrary.read();
    switch (valueType) {
      case HTValueTypeCode.nullValue:
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
      case HTValueTypeCode.string:
        _curValue = _curLibrary.readUtf8String();
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
      case HTValueTypeCode.identifier:
        final symbol = _curSymbol = _readString();
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
          final isSpread = _curLibrary.readBool();
          if (!isSpread) {
            final listItem = execute();
            list.add(listItem);
          } else {
            final List spreadValue = execute();
            list.addAll(spreadValue);
          }
        }
        _curValue = list;
        break;
      case HTValueTypeCode.struct:
        String? id;
        final hasId = _curLibrary.readBool();
        if (hasId) {
          id = _readString();
        }
        HTStruct? prototype;
        final hasPrototypeId = _curLibrary.readBool();
        if (hasPrototypeId) {
          final prototypeId = _readString();
          prototype = _curNamespace.memberGet(prototypeId);
        }
        final struct = HTStruct(_curNamespace, id: id, prototype: prototype);
        final fieldsCount = _curLibrary.read();
        for (var i = 0; i < fieldsCount; ++i) {
          final fieldType = _curLibrary.read();
          if (fieldType == StructObjFieldType.normal ||
              fieldType == StructObjFieldType.identifier) {
            final key = _readString();
            final value = execute();
            struct.fields[key] = value;
          } else if (fieldType == StructObjFieldType.spread) {
            final HTStruct value = execute();
            for (final key in value.fields.keys) {
              final copiedValue =
                  HTStruct.toStructValue(value.fields[key], value.closure!);
              struct.define(key, copiedValue);
            }
          }
        }
        // _curNamespace = savedCurNamespace;
        _curValue = struct;
        break;
      // case HTValueTypeCode.map:
      //   final map = {};
      //   final length = _curLibrary.readUint16();
      //   for (var i = 0; i < length; ++i) {
      //     final key = execute();
      //     final value = execute();
      //     map[key] = value;
      //   }
      //   _curValue = map;
      //   break;
      case HTValueTypeCode.function:
        final internalName = _readString();
        final hasExternalTypedef = _curLibrary.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _readString();
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
            namespace: _curNamespace);
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
        final left = _getRegVal(HTRegIdx.orLeft);
        final leftTruthValue = _truthy(left);
        final rightValueLength = _curLibrary.readUint16();
        if (leftTruthValue) {
          _curLibrary.skip(rightValueLength);
          _curValue = true;
        } else {
          final right = execute();
          final rightTruthValue = _truthy(right);
          _curValue = rightTruthValue;
        }
        break;
      case HTOpCode.logicalAnd:
        final left = _getRegVal(HTRegIdx.andLeft);
        final leftTruthValue = _truthy(left);
        final rightValueLength = _curLibrary.readUint16();
        if (!leftTruthValue) {
          _curLibrary.skip(rightValueLength);
          _curValue = false;
        } else {
          final right = execute();
          final rightTruthValue = _truthy(right);
          _curValue = leftTruthValue && rightTruthValue;
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
        var left = _getRegVal(HTRegIdx.addLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _curValue;
        if (_isZero(right)) {
          right = 0;
        }
        _curValue = left + right;
        break;
      case HTOpCode.subtract:
        var left = _getRegVal(HTRegIdx.addLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _curValue;
        if (_isZero(right)) {
          right = 0;
        }
        _curValue = left - right;
        break;
      case HTOpCode.multiply:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _curValue;
        if (_isZero(right)) {
          right = 0;
        }
        _curValue = left * right;
        break;
      case HTOpCode.devide:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _curValue;
        _curValue = left / right;
        break;
      case HTOpCode.modulo:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _curValue;
        _curValue = left % right;
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
        final truthValue = _truthy(object);
        _curValue = !truthValue;
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
      final isSpread = _curLibrary.readBool();
      if (!isSpread) {
        final arg = execute();
        positionalArgs.add(arg);
      } else {
        final List spreadValue = execute();
        positionalArgs.addAll(spreadValue);
      }
    }
    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _curLibrary.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _readString();
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      namedArgs[name] = arg;
    }
    final typeArgs = _curTypeArgs;
    // calle is a script function
    if (callee is HTFunction) {
      _curValue = callee.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    }
    // calle is a dart function
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        _curValue = callee(_curNamespace,
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
        final constructor = klass.memberGet(klass.id!) as HTFunction;
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
    } else if (callee is HTStruct && callee.definition != null) {
      HTNamedStruct def = callee.definition!;
      _curValue = def.createObject(
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
      );
    } else {
      throw HTError.notCallable(callee.toString(),
          moduleFullName: _curModuleFullName,
          line: _curLine,
          column: _curColumn);
    }
  }

  HTType _handleTypeExpr() {
    final index = _curLibrary.read();
    final typeType = TypeType.values.elementAt(index);
    switch (typeType) {
      case TypeType.normal:
        final typeName = _readString();
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
            paramId = _readString();
          }
          final decl = HTParameterType(declType,
              isOptional: isOptional, isVariadic: isVariadic, id: paramId);
          parameterTypes.add(decl);
        }
        final returnType = _handleTypeExpr();
        return HTFunctionType(
            parameterTypes: parameterTypes, returnType: returnType);
      case TypeType.struct:
      case TypeType.union:
        return HTUnresolvedType('Unsupported Type');
    }
  }

  void _handleTypeAliasDecl() {
    final id = _readString();
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _readString();
    }
    final value = _handleTypeExpr();
    final decl = HTVariable(id, this, _curModuleFullName, _curLibrary.id,
        classId: classId, closure: _curNamespace, value: value);
    _curNamespace.define(id, decl);
  }

  void _handleVarDecl() {
    final id = _readString();
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _readString();
    }
    final isField = _curLibrary.readBool();
    final isExternal = _curLibrary.readBool();
    final isStatic = _curLibrary.readBool();
    final isMutable = _curLibrary.readBool();
    final isConst = _curLibrary.readBool();
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
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        final value = execute();
        decl = HTVariable(id, this, _curModuleFullName, _curLibrary.id,
            classId: classId,
            closure: _curNamespace,
            declType: declType,
            value: value,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable);
      }
    } else {
      decl = HTVariable(id, this, _curModuleFullName, _curLibrary.id,
          classId: classId,
          closure: _curNamespace,
          declType: declType,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          isMutable: isMutable);
    }
    if (isField) {
    } else {
      _curNamespace.define(id, decl);
    }
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};
    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _readString();
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
    final internalName = _readString();
    String? id;
    final hasId = _curLibrary.readBool();
    if (hasId) {
      id = _readString();
    }
    String? classId;
    final hasClassId = _curLibrary.readBool();
    if (hasClassId) {
      classId = _readString();
    }
    String? externalTypeId;
    final hasExternalTypedef = _curLibrary.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _readString();
    }
    final category = FunctionCategory.values[_curLibrary.read()];
    final isField = _curLibrary.readBool();
    final isExternal = _curLibrary.readBool();
    final isStatic = _curLibrary.readBool();
    final isConst = _curLibrary.readBool();
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
      final hasRedirectingCtor = _curLibrary.readBool();
      if (hasRedirectingCtor) {
        final calleeId = _readString();
        final hasCtorName = _curLibrary.readBool();
        String? ctorName;
        if (hasCtorName) {
          ctorName = _readString();
        }
        final positionalArgIpsLength = _curLibrary.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _curLibrary.readUint16();
          positionalArgIps.add(_curLibrary.ip);
          _curLibrary.skip(argLength);
        }
        final namedArgsLength = _curLibrary.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _readString();
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
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
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
    if (isField) {
      _curValue = func;
    } else {
      if ((category != FunctionCategory.constructor) || isStatic) {
        func.namespace = _curNamespace;
      }
      _curNamespace.define(func.internalName, func);
    }
  }

  void _handleClassDecl() {
    final id = _readString();
    final isExternal = _curLibrary.readBool();
    final isAbstract = _curLibrary.readBool();
    final hasUserDefinedConstructor = _curLibrary.readBool();
    HTType? superType;
    final hasSuperClass = _curLibrary.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != HTLexicon.object)) {
        superType = HTEntity.type;
      }
    }
    final isEnum = _curLibrary.readBool();
    final klass = HTClass(this,
        id: id,
        closure: _curNamespace,
        superType: superType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isEnum: isEnum);
    _curNamespace.define(id, klass);
    final savedClass = _curClass;
    _curClass = klass;
    // deal with definition block
    execute(namespace: klass.namespace);
    // Add default constructor if non-exist.
    if (!isAbstract && !hasUserDefinedConstructor && !isExternal) {
      final ctor = HTFunction(
          SemanticNames.constructor, _curModuleFullName, _curLibrary.id, this,
          classId: klass.id,
          category: FunctionCategory.constructor,
          closure: klass.namespace);
      klass.namespace.define(SemanticNames.constructor, ctor);
    }
    if (_isScript || _curFunction != null) {
      klass.resolve();
    }
    _curClass = savedClass;
  }

  void _handleExternalEnumDecl() {
    final id = _readString();
    final enumClass = HTExternalEnum(id, this);
    _curNamespace.define(id, enumClass);
  }

  void _handleStructDecl() {
    final id = _readString();
    String? prototypeId;
    final hasPrototypeId = _curLibrary.readBool();
    if (hasPrototypeId) {
      prototypeId = _readString();
    }
    final lateInitialize = _curLibrary.readBool();
    final staticFiledsLength = _curLibrary.readUint16();
    final staticDefinitionIp = _curLibrary.ip;
    _curLibrary.skip(staticFiledsLength);
    final filedsLength = _curLibrary.readUint16();
    final definitionIp = _curLibrary.ip;
    _curLibrary.skip(filedsLength);
    final struct = HTNamedStruct(
      id,
      this,
      _curModuleFullName,
      _curLibrary.id,
      _curNamespace,
      prototypeId: prototypeId,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: definitionIp,
    );
    if (!lateInitialize) {
      struct.resolve();
    }
    _curNamespace.define(id, struct);
  }
}
