import 'dart:typed_data';
import 'package:path/path.dart' as path;

import '../value/namespace/namespace.dart';
import '../value/struct/named_struct.dart';
import '../value/entity.dart';
import '../value/class/class.dart';
import '../value/instance/cast.dart';
import '../value/function/function.dart';
import '../value/function/parameter.dart';
import '../value/variable/variable.dart';
import '../value/struct/struct.dart';
import '../value/external_enum/external_enum.dart';
import '../value/constant.dart';
import '../external/external_class.dart';
import '../external/external_function.dart';
import '../external/external_instance.dart';
import '../type/type.dart';
import '../type/unresolved.dart';
import '../type/function.dart';
import '../type/nominal.dart';
import '../type/structural.dart';
import '../lexer/lexicon.dart';
import '../lexer/lexicon_default_impl.dart';
import '../grammar/constant.dart';
import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../shared/constants.dart';
import '../bytecode/bytecode_module.dart';
import '../bytecode/compiler.dart';
import '../version.dart';
import '../value/unresolved_import_statement.dart';
import '../locale/locale.dart';
import '../analyzer/analyzer.dart' show AnalyzerImplConfig;

/// Mixin for classes that want to hold a ref of a bytecode interpreter
mixin InterpreterRef {
  late final HTInterpreter interpreter;
}

class InterpreterConfig implements AnalyzerImplConfig, ErrorHandlerConfig {
  @override
  bool showDartStackTrace;

  @override
  bool showHetuStackTrace;

  @override
  int stackTraceDisplayCountLimit;

  @override
  ErrorHanldeApproach errorHanldeApproach;

  @override
  bool allowVariableShadowing;

  @override
  bool allowImplicitVariableDeclaration;

  @override
  bool allowImplicitNullToZeroConversion;

  @override
  bool allowImplicitEmptyValueToFalseConversion;

  InterpreterConfig(
      {this.showDartStackTrace = false,
      this.showHetuStackTrace = false,
      this.stackTraceDisplayCountLimit = kStackTraceDisplayCountLimit,
      this.errorHanldeApproach = ErrorHanldeApproach.exception,
      this.allowVariableShadowing = true,
      this.allowImplicitVariableDeclaration = false,
      this.allowImplicitNullToZeroConversion = false,
      this.allowImplicitEmptyValueToFalseConversion = false});
}

class _LoopInfo {
  final int startIp;
  final int continueIp;
  final int breakIp;
  final HTNamespace namespace;
  _LoopInfo(this.startIp, this.continueIp, this.breakIp, this.namespace);
}

/// A bytecode implementation of Hetu Script interpreter
class HTInterpreter {
  static HTClass? rootClass;
  static HTStruct? rootStruct;

  final stackTraceList = <String>[];

  final _cachedModules = <String, HTBytecodeModule>{};

  InterpreterConfig config;

  late final HTLexicon _lexicon;
  HTLexicon get lexicon => _lexicon;

  HTResourceContext<HTSource> sourceContext;

  ErrorHandlerConfig get errorConfig => config;

  var _currentLine = 0;
  int get currentLine => _currentLine;

  var _column = 0;
  int get currentColumn => _column;

  final HTNamespace globalNamespace;

  late HTNamespace _currentNamespace;
  HTNamespace get currentNamespace => _currentNamespace;

  String _currentFileName = '';
  String get currentFileName => _currentFileName;

  bool _isModuleEntryScript = false;
  late HTResourceType _currentFileResourceType;

  late HTBytecodeModule _currentBytecodeModule;
  HTBytecodeModule get bytecodeModule => _currentBytecodeModule;

  HTClass? _class;
  HTFunction? _function;

  var _currentStackIndex = -1;

  /// Register values are stored by groups.
  /// Every group have 16 values, they are HTRegIdx.
  /// A such group can be understanded as the stack frame of a runtime function.
  final _stackFrames = <List>[];

  void _setRegVal(int index, dynamic value) =>
      _stackFrames[_currentStackIndex][index] = value;
  dynamic _getRegVal(int index) => _stackFrames[_currentStackIndex][index];
  set _localValue(dynamic value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.value] = value;
  dynamic get _localValue => _stackFrames[_currentStackIndex][HTRegIdx.value];
  set _localSymbol(String? value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.identifier] = value;
  String? get localSymbol =>
      _stackFrames[_currentStackIndex][HTRegIdx.identifier];
  set _localTypeArgs(List<HTType> value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.typeArgs] = value;
  List<HTType> get _localTypeArgs =>
      _stackFrames[_currentStackIndex][HTRegIdx.typeArgs] ?? const [];
  set _loopCount(int value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.loopCount] = value;
  int get _loopCount =>
      _stackFrames[_currentStackIndex][HTRegIdx.loopCount] ?? 0;
  set _anchor(int value) =>
      _stackFrames[_currentStackIndex][HTRegIdx.anchor] = value;
  int get _anchor => _stackFrames[_currentStackIndex][HTRegIdx.anchor] ?? 0;

  /// Loop point is stored as stack form.
  /// Break statement will jump to the last loop point,
  /// and remove it from this stack.
  /// Return statement will clear loop points by
  /// [_loopCount] in current stack frame.
  final _loops = <_LoopInfo>[];

  /// A bytecode interpreter.
  HTInterpreter(
      {InterpreterConfig? config,
      required this.sourceContext,
      HTLexicon? lexicon})
      : config = config ?? InterpreterConfig(),
        _lexicon = lexicon ?? HTDefaultLexicon(),
        globalNamespace = HTNamespace(id: Semantic.global) {
    _currentNamespace = globalNamespace;
  }

  /// inexpicit type conversion for zero or null values
  bool _isZero(dynamic condition) {
    if (config.allowImplicitNullToZeroConversion) {
      return condition == 0;
    } else {
      return condition == 0 || condition == null;
    }
  }

  /// inexpicit type conversion for truthy values
  bool _truthy(dynamic condition) {
    if (config.allowImplicitEmptyValueToFalseConversion) {
      if (condition == false ||
          condition == null ||
          condition == 0 ||
          condition == '' ||
          condition == '0' ||
          condition == 'false' ||
          (condition is Iterable && condition.isEmpty) ||
          (condition is Map && condition.isEmpty) ||
          (condition is HTStruct && condition.isEmpty)) {
        return false;
      } else {
        return true;
      }
    } else {
      return condition;
    }
  }

  /// Catch errors throwed by other code, and wrap them with detailed informations.
  void handleError(Object error, [Object? externalStackTrace]) {
    final sb = StringBuffer();

    void handleStackTrace(List<String> stackTrace,
        {bool withLineNumber = false}) {
      if (errorConfig.stackTraceDisplayCountLimit > 0) {
        if (stackTrace.length > errorConfig.stackTraceDisplayCountLimit) {
          for (var i = stackTrace.length - 1;
              i >= stackTrace.length - errorConfig.stackTraceDisplayCountLimit;
              --i) {
            if (withLineNumber) {
              sb.write('#${stackTrace.length - 1 - i}\t');
            }
            sb.writeln(stackTrace[i]);
          }
          sb.writeln(
              '...(and other ${stackTrace.length - errorConfig.stackTraceDisplayCountLimit} messages)');
        } else {
          for (var i = stackTrace.length - 1; i >= 0; --i) {
            if (withLineNumber) {
              sb.write('#${stackTrace.length - 1 - i}\t');
            }
            sb.writeln(stackTrace[i]);
          }
        }
      } else if (errorConfig.stackTraceDisplayCountLimit < 0) {
        for (var i = stackTrace.length - 1; i >= 0; --i) {
          if (withLineNumber) {
            sb.write('#${stackTrace.length - 1 - i}\t');
          }
          sb.writeln(stackTrace[i]);
        }
      }
    }

    if (stackTraceList.isNotEmpty && errorConfig.showHetuStackTrace) {
      sb.writeln(HTLocale.current.scriptStackTrace);
      handleStackTrace(stackTraceList, withLineNumber: true);
    }
    if (externalStackTrace != null && errorConfig.showDartStackTrace) {
      sb.writeln(HTLocale.current.externalStackTrace);
      final externalStackTraceList =
          externalStackTrace.toString().trim().split('\n').reversed.toList();
      handleStackTrace(externalStackTraceList);
    }

    final stackTraceString = sb.toString().trimRight();
    if (error is HTError) {
      final wrappedError = HTError(
        error.code,
        error.type,
        message: error.message,
        extra: stackTraceString,
        filename: error.filename ?? currentFileName,
        line: error.line ?? currentLine,
        column: error.column ?? currentColumn,
      );
      throw wrappedError;
    } else {
      final hetuError = HTError.extern(
        error.toString(),
        extra: stackTraceString,
        filename: currentFileName,
        line: currentLine,
        column: currentColumn,
      );
      throw hetuError;
    }
  }

  /// Call a function within current [HTNamespace].
  dynamic invoke(String funcName,
      {String? moduleName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      stackTraceList.clear();
      if (moduleName != null) {
        _currentBytecodeModule = _cachedModules[moduleName]!;
        _currentNamespace = _currentBytecodeModule.namespaces.values.last;
      }
      final func = _currentNamespace.memberGet(funcName);
      if (func is HTFunction) {
        func.resolve();
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(funcName);
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, stackTrace);
      }
    }
  }

  final externClasses = <String, HTExternalClass>{};
  final externTypeReflection = <HTExternalTypeReflection>[];
  final externFuncs = <String, Function>{};
  final externFuncTypeUnwrappers = <String, HTExternalFunctionTypedef>{};

  /// Wether the interpreter has a certain external class binding.
  bool containsExternalClass(String id) => externClasses.containsKey(id);

  /// Register a external class into scrfipt.
  /// For acessing static members and constructors of this class,
  /// there must also be a declaraction in script
  void bindExternalClass(HTExternalClass externalClass,
      {bool override = false}) {
    if (externClasses.containsKey(externalClass.id) && !override) {
      throw HTError.defined(externalClass.id, ErrorType.runtimeError);
    }
    externClasses[externalClass.id] = externalClass;
  }

  /// Fetch a external class instance
  HTExternalClass fetchExternalClass(String id) {
    if (!externClasses.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externClasses[id]!;
  }

  /// Bind a external class name to a abstract class name for interpreter get dart class name by reflection
  void bindExternalReflection(HTExternalTypeReflection reflection) {
    externTypeReflection.add(reflection);
  }

  /// Register a external function into scrfipt
  /// there must be a declaraction also in script for using this
  void bindExternalFunction(String id, Function function,
      {bool override = false}) {
    if (externFuncs.containsKey(id) && !override) {
      throw HTError.defined(id, ErrorType.runtimeError);
    }
    externFuncs[id] = function;
  }

  /// Fetch a external function
  Function fetchExternalFunction(String id) {
    if (!externFuncs.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externFuncs[id]!;
  }

  /// Register a external function typedef into scrfipt
  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function,
      {bool override = false}) {
    if (externFuncTypeUnwrappers.containsKey(id) && !override) {
      throw HTError.defined(id, ErrorType.runtimeError);
    }
    externFuncTypeUnwrappers[id] = function;
  }

  /// Using unwrapper to turn a script function into a external function
  Function unwrapExternalFunctionType(HTFunction func) {
    if (!externFuncTypeUnwrappers.containsKey(func.externalTypeId)) {
      throw HTError.undefinedExternal(func.externalTypeId!);
    }
    final unwrapFunc = externFuncTypeUnwrappers[func.externalTypeId]!;
    return unwrapFunc(func);
  }

  bool switchModule(String id) {
    if (_cachedModules.containsKey(id)) {
      newStackFrame(moduleName: id);
      return true;
    } else {
      return false;
    }
  }

  HTBytecodeModule? getBytecode(String moduleName) {
    return _cachedModules[moduleName];
  }

  String stringify(dynamic object) {
    return _lexicon.stringify(object);
  }

  /// Encapsulate any value to a Hetu object, for members accessing and type check.
  HTEntity encapsulate(dynamic object) {
    if (object is HTEntity) {
      return object;
    } else if (object == null) {
      return HTEntity.nullValue;
    }
    late String typeString;
    if (object is bool) {
      typeString = _lexicon.typeBoolean;
    } else if (object is int) {
      typeString = _lexicon.typeNumber;
    } else if (object is double) {
      typeString = _lexicon.typeFloat;
    } else if (object is String) {
      typeString = _lexicon.typeString;
    } else if (object is List) {
      typeString = 'List';
      // var valueType = HTType.ANY;
      // if (object.isNotEmpty) {
      //   valueType = encapsulate(object.first).valueType;
      //   for (final item in object) {
      //     final value = encapsulate(item).valueType;
      //     if (value.isNotA(valueType)) {
      //       valueType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // return HTList(object, this, valueType: valueType);
    } else if (object is Set) {
      typeString = 'Set';
    } else if (object is Map) {
      typeString = 'Map';
      // var keyType = HTType.ANY;
      // var valueType = HTType.ANY;
      // if (object.keys.isNotEmpty) {
      //   keyType = encapsulate(object.keys.first).valueType;
      //   for (final item in object.keys) {
      //     final value = encapsulate(item).valueType;
      //     if (value.isNotA(keyType)) {
      //       keyType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // if (object.values.isNotEmpty) {
      //   valueType = encapsulate(object.values.first).valueType;
      //   for (final item in object.values) {
      //     final value = encapsulate(item).valueType;
      //     if (value.isNotA(valueType)) {
      //       valueType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // return HTMap(object, this, keyType: keyType, valueType: valueType);
    } else if (object is Iterable) {
      typeString = 'Iterable';
    } else if (object is Iterator) {
      typeString = 'Iterator';
    } else {
      var reflected = false;
      for (final reflect in externTypeReflection) {
        final result = reflect(object);
        if (result != null) {
          reflected = true;
          typeString = result;
          break;
        }
      }
      if (!reflected) {
        typeString = object.runtimeType.toString();
        typeString = _lexicon.getBaseTypeId(typeString);
      }
    }

    return HTExternalInstance(object, this, typeString);
  }

  dynamic toStructValue(dynamic value) {
    if (value is Iterable) {
      final list = [];
      for (final item in value) {
        final result = toStructValue(item);
        list.add(result);
      }
      return list;
    } else if (value is Map) {
      final HTStruct prototype = rootStruct ??
          globalNamespace.memberGet(lexicon.globalPrototypeId,
              isRecursive: true);
      final struct =
          HTStruct(this, prototype: prototype, closure: currentNamespace);
      for (final key in value.keys) {
        final fieldKey = key.toString();
        final fieldValue = toStructValue(value[key]);
        struct.define(fieldKey, fieldValue);
      }
      return struct;
    } else if (value is HTStruct) {
      return value.clone();
    } else {
      return value;
    }
  }

  HTStruct createStructfromJson(Map<dynamic, dynamic> jsonData) {
    final HTStruct prototype = rootStruct ??
        globalNamespace.memberGet(_lexicon.globalPrototypeId,
            isRecursive: true);
    final struct =
        HTStruct(this, prototype: prototype, closure: currentNamespace);
    for (final key in jsonData.keys) {
      var value = toStructValue(jsonData[key]);
      struct.define(key.toString(), value);
    }
    return struct;
  }

  void _handleNamespaceImport(HTNamespace nsp, UnresolvedImportStatement decl) {
    final importNamespace = _currentBytecodeModule.namespaces[decl.fromPath]!;
    if (_currentFileResourceType == HTResourceType.hetuScript ||
        _currentFileResourceType == HTResourceType.hetuLiteralCode) {
      for (final importDecl in importNamespace.imports.values) {
        _handleNamespaceImport(importNamespace, importDecl);
      }
      // for (final declaration in importNamespace.declarations.values) {
      //   declaration.resolve();
      // }
    }

    if (decl.alias == null) {
      if (decl.showList.isEmpty) {
        nsp.import(importNamespace,
            isExported: decl.isExported, showList: decl.showList);
      } else {
        for (final id in decl.showList) {
          final decl = importNamespace.symbols[id]!;
          nsp.defineImport(id, decl);
        }
      }
    } else {
      if (decl.showList.isEmpty) {
        final aliasNamespace =
            HTNamespace(id: decl.alias!, closure: globalNamespace);
        aliasNamespace.import(importNamespace);
        nsp.defineImport(decl.alias!, aliasNamespace);
      } else {
        final aliasNamespace =
            HTNamespace(id: decl.alias!, closure: globalNamespace);
        for (final id in decl.showList) {
          final decl = importNamespace.symbols[id]!;
          assert(!decl.isPrivate);
          aliasNamespace.define(id, decl);
        }
        nsp.defineImport(decl.alias!, aliasNamespace);
      }
    }
  }

  /// Load a pre-compiled bytecode file as a module.
  /// If [invokeFunc] is true, execute the bytecode immediately.
  dynamic loadBytecode(
      {required Uint8List bytes,
      required String moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      _currentBytecodeModule = HTBytecodeModule(id: moduleName, bytes: bytes);
      _cachedModules[_currentBytecodeModule.id] = _currentBytecodeModule;
      final signature = _currentBytecodeModule.readUint32();
      if (signature != HTCompiler.hetuSignature) {
        throw HTError.bytecode(
            filename: _currentFileName, line: _currentLine, column: _column);
      }
      final major = _currentBytecodeModule.read();
      final minor = _currentBytecodeModule.read();
      final patch = _currentBytecodeModule.readUint16();
      var incompatible = false;
      if (major > 0) {
        if (major != kHetuVersion.major) {
          incompatible = true;
        }
      } else {
        if (major != kHetuVersion.major ||
            minor != kHetuVersion.minor ||
            patch != kHetuVersion.patch) {
          incompatible = true;
        }
      }
      if (incompatible) {
        throw HTError.version('$major.$minor.$patch', '$kHetuVersion',
            filename: _currentFileName, line: _currentLine, column: _column);
      }
      _currentFileName = _currentBytecodeModule.readLongString();
      final sourceType =
          HTResourceType.values.elementAt(_currentBytecodeModule.read());
      _isModuleEntryScript = sourceType == HTResourceType.hetuScript ||
          sourceType == HTResourceType.hetuLiteralCode ||
          sourceType == HTResourceType.hetuValue;
      if (sourceType == HTResourceType.hetuLiteralCode) {
        _currentNamespace = globalNamespace;
      }
      while (_currentBytecodeModule.ip < _currentBytecodeModule.bytes.length) {
        final result = execute(clearStack: false);
        if (result is HTNamespace && result != globalNamespace) {
          _currentBytecodeModule.namespaces[result.id!] = result;
        } else if (result is HTValueSource) {
          _currentBytecodeModule.expressions[result.id] = result.value;
        }
        // TODO: import binary bytes
      }
      if (!_isModuleEntryScript) {
        // handles imports
        for (final nsp in _currentBytecodeModule.namespaces.values) {
          for (final decl in nsp.imports.values) {
            _handleNamespaceImport(nsp, decl);
          }
        }
      }
      if (_currentBytecodeModule.namespaces.isNotEmpty) {
        _currentNamespace = _currentBytecodeModule.namespaces.values.last;
        if (globallyImport) {
          globalNamespace.import(_currentNamespace);
        }
      }
      // resolve each declaration after we get all declarations
      // if (!_isModuleEntryScript) {
      //   for (final namespace in _currentBytecodeModule.namespaces.values) {
      //     for (final decl in namespace.declarations.values) {
      //       decl.resolve();
      //     }
      //   }
      // }
      _cachedModules[_currentBytecodeModule.id] = _currentBytecodeModule;
      dynamic result;
      if (invokeFunc != null) {
        result = invoke(invokeFunc,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            errorHandled: true);
        return result;
      }
      stackTraceList.clear();
      if (_isModuleEntryScript) {
        result = _stackFrames.last.first;
        return result;
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, stackTrace);
      }
    }
  }

  List<String> getExportList({String? sourceName, required String moduleName}) {
    final module = _cachedModules[moduleName]!;
    sourceName ??= module.namespaces.values.last.fullName;
    final namespace = module.namespaces[sourceName]!;
    if (namespace.willExportAll) {
      final list = <String>[];
      for (final symbol in namespace.symbols.keys) {
        if (symbol.startsWith(_lexicon.privatePrefix)) continue;
        list.add(symbol);
      }
      return list;
    } else {
      return namespace.exports;
    }
  }

  void newStackFrame(
      {String? filename,
      String? moduleName,
      HTNamespace? namespace,
      HTFunction? function,
      int? ip,
      int? line,
      int? column}) {
    // var ipChanged = false;
    var libChanged = false;
    if (filename != null) {
      _currentFileName = filename;
    }
    if (moduleName != null && (_currentBytecodeModule.id != moduleName)) {
      assert(_cachedModules.containsKey(moduleName));
      _currentBytecodeModule = _cachedModules[moduleName]!;
      libChanged = true;
    }
    if (namespace != null) {
      _currentNamespace = namespace;
    } else if (libChanged) {
      _currentNamespace = _currentBytecodeModule.namespaces.values.last;
    }
    if (function != null) {
      _function = function;
    }
    if (ip != null) {
      _currentBytecodeModule.ip = ip;
    } else if (libChanged) {
      _currentBytecodeModule.ip = 0;
    }
    if (line != null) {
      _currentLine = line;
    } else if (libChanged) {
      _currentLine = 0;
    }
    if (column != null) {
      _column = column;
    } else if (libChanged) {
      _column = 0;
    }
    ++_currentStackIndex;
    if (_stackFrames.length <= _currentStackIndex) {
      _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
    }
  }

  void restoreStackFrame(
      {bool clearStack = true,
      String? savedFileName,
      String? savedModuleName,
      HTNamespace? savedNamespace,
      HTFunction? savedFunction,
      int? savedIp,
      int? savedLine,
      int? savedColumn}) {
    if (savedFileName != null) {
      _currentFileName = savedFileName;
    }
    if (savedModuleName != null) {
      if (_currentBytecodeModule.id != savedModuleName) {
        assert(_cachedModules.containsKey(savedModuleName));
        _currentBytecodeModule = _cachedModules[savedModuleName]!;
      }
    }
    if (savedNamespace != null) {
      _currentNamespace = savedNamespace;
    }
    if (savedFunction != null) {
      _function = savedFunction;
    }
    if (savedIp != null) {
      _currentBytecodeModule.ip = savedIp;
    }
    if (savedLine != null) {
      _currentLine = savedLine;
    }
    if (savedColumn != null) {
      _column = savedColumn;
    }
    if (clearStack) {
      --_currentStackIndex;
      _stackFrames.removeLast();
    }
  }

  /// Interpret a loaded module with the key of [moduleName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current expression value
  /// when encountered [HTOpCode.endOfExec] or [HTOpCode.endOfFunc].
  ///
  /// Changing library will create new stack frame for new register values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute(
      {String? filename,
      String? moduleName,
      HTNamespace? namespace,
      HTFunction? function,
      int? ip,
      int? line,
      int? column,
      bool clearStack = true}) {
    final savedFileName = _currentFileName;
    final savedLibrary = _currentBytecodeModule;
    final savedNamespace = _currentNamespace;
    final savedFunction = _function;
    final savedIp = _currentBytecodeModule.ip;
    final savedLine = _currentLine;
    final savedColumn = _column;
    var libChanged = false;
    var ipChanged = false;
    if (filename != null) {
      _currentFileName = filename;
    }
    if (moduleName != null && (_currentBytecodeModule.id != moduleName)) {
      assert(_cachedModules.containsKey(moduleName));
      _currentBytecodeModule = _cachedModules[moduleName]!;
      libChanged = true;
    }
    if (namespace != null) {
      _currentNamespace = namespace;
    }
    if (function != null) {
      _function = function;
    }
    if (ip != null) {
      _currentBytecodeModule.ip = ip;
      ipChanged = true;
    } else if (libChanged) {
      _currentBytecodeModule.ip = 0;
      ipChanged = true;
    }
    if (line != null) {
      _currentLine = line;
    } else if (libChanged) {
      _currentLine = 0;
    }
    if (column != null) {
      _column = column;
    } else if (libChanged) {
      _column = 0;
    }
    ++_currentStackIndex;
    if (_stackFrames.length <= _currentStackIndex) {
      _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
    }

    final result = _execute();

    _currentFileName = savedFileName;
    _currentBytecodeModule = savedLibrary;
    _currentNamespace = savedNamespace;
    _function = savedFunction;
    if (ipChanged) {
      _currentBytecodeModule.ip = savedIp;
    }
    _currentLine = savedLine;
    _column = savedColumn;
    if (clearStack) {
      --_currentStackIndex;
      _stackFrames.removeLast();
    }
    return result;
  }

  void _clearLocals() {
    _localValue = null;
    _localSymbol = null;
    _localTypeArgs = [];
  }

  dynamic _execute() {
    var instruction = _currentBytecodeModule.read();
    while (instruction != HTOpCode.endOfCode) {
      switch (instruction) {
        case HTOpCode.lineInfo:
          _currentLine = _currentBytecodeModule.readUint16();
          _column = _currentBytecodeModule.readUint16();
          break;
        // store a local value in interpreter
        case HTOpCode.local:
          _storeLocal();
          break;
        // store current local value to a register position
        case HTOpCode.register:
          final index = _currentBytecodeModule.read();
          _setRegVal(index, _localValue);
          break;
        case HTOpCode.skip:
          final distance = _currentBytecodeModule.readInt16();
          _currentBytecodeModule.ip += distance;
          break;
        // store the current ip position
        case HTOpCode.anchor:
          _anchor = _currentBytecodeModule.ip;
          break;
        case HTOpCode.goto:
          final distance = _currentBytecodeModule.readInt16();
          _currentBytecodeModule.ip = _anchor + distance;
          break;
        case HTOpCode.file:
          _currentFileName = _currentBytecodeModule.readShortString();
          final resourceTypeIndex = _currentBytecodeModule.read();
          _currentFileResourceType =
              HTResourceType.values.elementAt(resourceTypeIndex);
          if (_currentFileResourceType != HTResourceType.hetuLiteralCode) {
            _currentNamespace =
                HTNamespace(id: _currentFileName, closure: globalNamespace);
          }
          break;
        case HTOpCode.loopPoint:
          final continueLength = _currentBytecodeModule.readUint16();
          final breakLength = _currentBytecodeModule.readUint16();
          _loops.add(_LoopInfo(
              _currentBytecodeModule.ip,
              _currentBytecodeModule.ip + continueLength,
              _currentBytecodeModule.ip + breakLength,
              _currentNamespace));
          ++_loopCount;
          break;
        case HTOpCode.breakLoop:
          _currentBytecodeModule.ip = _loops.last.breakIp;
          _currentNamespace = _loops.last.namespace;
          _loops.removeLast();
          --_loopCount;
          _clearLocals();
          break;
        case HTOpCode.continueLoop:
          _currentBytecodeModule.ip = _loops.last.continueIp;
          break;
        case HTOpCode.assertion:
          final text = _currentBytecodeModule.readShortString();
          final value = execute();
          if (!value) {
            throw HTError.assertionFailed(text);
          }
          break;
        case HTOpCode.throws:
          throw HTError.scriptThrows(_localValue);
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case HTOpCode.block:
          final id = _currentBytecodeModule.readShortString();
          _currentNamespace = HTNamespace(id: id, closure: _currentNamespace);
          _clearLocals();
          break;
        case HTOpCode.endOfBlock:
          _currentNamespace = _currentNamespace.closure!;
          break;
        // 语句结束
        case HTOpCode.endOfStmt:
          _clearLocals();
          break;
        case HTOpCode.endOfExec:
          return _localValue;
        case HTOpCode.endOfFunc:
          final loopCount = _loopCount;
          for (var i = 0; i < loopCount; ++i) {
            _loops.removeLast();
          }
          _loopCount = 0;
          return _localValue;
        case HTOpCode.endOfFile:
          if (_currentFileResourceType == HTResourceType.hetuValue) {
            return HTValueSource(
                id: _currentFileName,
                moduleName: _currentBytecodeModule.id,
                value: _localValue);
          } else {
            return _currentNamespace;
          }
        case HTOpCode.constIntTable:
          final int64Length = _currentBytecodeModule.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _currentBytecodeModule
                .addGlobalConstant<int>(_currentBytecodeModule.readInt64());
            // _bytecodeModule.addInt(_bytecodeModule.readInt64());
          }
          break;
        case HTOpCode.constFloatTable:
          final float64Length = _currentBytecodeModule.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _currentBytecodeModule.addGlobalConstant<double>(
                _currentBytecodeModule.readFloat64());
            // _bytecodeModule.addFloat(_bytecodeModule.readFloat64());
          }
          break;
        case HTOpCode.constStringTable:
          final utf8StringLength = _currentBytecodeModule.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _currentBytecodeModule.addGlobalConstant<String>(
                _currentBytecodeModule.readLongString());
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
        case HTOpCode.destructuringDecl:
          _handleDestructuringDecl();
          break;
        case HTOpCode.constDecl:
          _handleConstDecl();
          break;
        case HTOpCode.namespaceDecl:
          final internalName = _currentBytecodeModule.readShortString();
          String? classId;
          final hasClassId = _currentBytecodeModule.readBool();
          if (hasClassId) {
            classId = _currentBytecodeModule.readShortString();
          }
          final namespace = HTNamespace(
              id: internalName, classId: classId, closure: _currentNamespace);
          execute(namespace: namespace);
          _currentNamespace.define(internalName, namespace);
          _localValue = namespace;
          break;
        case HTOpCode.delete:
          final deletingType = _currentBytecodeModule.read();
          if (deletingType == DeletingTypeCode.member) {
            final object = execute();
            if (object is HTStruct) {
              final symbol = _currentBytecodeModule.readShortString();
              object.delete(symbol);
            } else {
              throw HTError.delete(
                  filename: _currentFileName,
                  line: _currentLine,
                  column: _column);
            }
          } else if (deletingType == DeletingTypeCode.sub) {
            final object = execute();
            if (object is HTStruct) {
              final symbol = execute().toString();
              object.delete(symbol);
            } else {
              throw HTError.delete(
                  filename: _currentFileName,
                  line: _currentLine,
                  column: _column);
            }
          } else {
            final symbol = _currentBytecodeModule.readShortString();
            _currentNamespace.delete(symbol);
          }
          _clearLocals();
          break;
        case HTOpCode.ifStmt:
          final thenBranchLength = _currentBytecodeModule.readUint16();
          final truthValue = _truthy(_localValue);
          if (!truthValue) {
            _currentBytecodeModule.skip(thenBranchLength);
          }
          break;
        case HTOpCode.whileStmt:
          final truthValue = _truthy(_localValue);
          if (!truthValue) {
            _currentBytecodeModule.ip = _loops.last.breakIp;
            _currentNamespace = _loops.last.namespace;
            _loops.removeLast();
            --_loopCount;
            _clearLocals();
          }
          break;
        case HTOpCode.doStmt:
          final hasCondition = _currentBytecodeModule.readBool();
          final truthValue = hasCondition ? _truthy(_localValue) : false;
          if (truthValue) {
            _currentBytecodeModule.ip = _loops.last.startIp;
          } else {
            _currentBytecodeModule.ip = _loops.last.breakIp;
            _currentNamespace = _loops.last.namespace;
            _loops.removeLast();
            --_loopCount;
            _clearLocals();
          }
          break;
        case HTOpCode.whenStmt:
          _handleWhen();
          break;
        case HTOpCode.assign:
          final value = _getRegVal(HTRegIdx.assign);
          final id = localSymbol!;
          final result = _currentNamespace.memberSet(id, value,
              isRecursive: true, throws: false);
          if (!result) {
            if (config.allowImplicitVariableDeclaration) {
              final decl = HTVariable(id,
                  interpreter: this,
                  fileName: _currentFileName,
                  moduleName: _currentBytecodeModule.id,
                  closure: _currentNamespace,
                  value: value,
                  isPrivate: id.startsWith(lexicon.privatePrefix),
                  isMutable: true);
              _currentNamespace.define(id, decl);
            } else {
              throw HTError.undefined(id);
            }
          }
          _localValue = value;
          break;
        case HTOpCode.ifNull:
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
        case HTOpCode.truncatingDevide:
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
          final isNullable = _currentBytecodeModule.readBool();
          final keyBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              _currentBytecodeModule.skip(keyBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.getter,
                  filename: _currentFileName,
                  line: _currentLine,
                  column: _column);
            }
          } else {
            final key = execute();
            _localSymbol = key;
            final encap = encapsulate(object);
            if (encap is HTNamespace) {
              _localValue = encap.memberGet(key,
                  from: _currentNamespace.fullName, isRecursive: false);
            } else {
              _localValue =
                  encap.memberGet(key, from: _currentNamespace.fullName);
            }
          }
          break;
        case HTOpCode.subGet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _currentBytecodeModule.readBool();
          final keyBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              _currentBytecodeModule.skip(keyBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.subGetter,
                  filename: _currentFileName,
                  line: _currentLine,
                  column: _column);
            }
          } else {
            final key = execute();
            if (object is HTEntity) {
              _localValue =
                  object.subGet(key, from: _currentNamespace.fullName);
            } else {
              if (object is List) {
                if (key is! int) {
                  throw HTError.subGetKey(key,
                      filename: _currentFileName,
                      line: _currentLine,
                      column: _column);
                } else if (key < 0 || key >= object.length) {
                  throw HTError.outOfRange(key, object.length,
                      filename: _currentFileName,
                      line: _currentLine,
                      column: _column);
                }
              }
              _localValue = object[key];
            }
          }
          break;
        case HTOpCode.memberSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _currentBytecodeModule.readBool();
          final valueBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              _currentBytecodeModule.skip(valueBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.setter,
                  filename: _currentFileName,
                  line: _currentLine,
                  column: _column);
            }
          } else {
            final key = _getRegVal(HTRegIdx.postfixKey);
            final value = execute();
            final encap = encapsulate(object);
            encap.memberSet(key, value);
            if (encap is HTNamespace) {
              encap.memberSet(key, value,
                  from: _currentNamespace.fullName, isRecursive: false);
            } else {
              encap.memberSet(key, value, from: _currentNamespace.fullName);
            }
            _localValue = value;
          }
          break;
        case HTOpCode.subSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _currentBytecodeModule.readBool();
          final keyAndValueBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              _currentBytecodeModule.skip(keyAndValueBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.subSetter,
                  filename: _currentFileName,
                  line: _currentLine,
                  column: _column);
            }
          } else {
            final key = execute();
            final value = execute();
            if (object is HTEntity) {
              object.subSet(key, value);
            } else {
              if (object is List) {
                if (key is! int) {
                  throw HTError.subGetKey(key,
                      filename: _currentFileName,
                      line: _currentLine,
                      column: _column);
                } else if (key < 0 || key >= object.length) {
                  throw HTError.outOfRange(key, object.length,
                      filename: _currentFileName,
                      line: _currentLine,
                      column: _column);
                }
                object[key] = value;
              } else if (object is Map) {
                object[key] = value;
              }
            }
            _localValue = value;
          }
          break;
        case HTOpCode.call:
          _handleCallExpr();
          break;
        default:
          throw HTError.unknownOpCode(instruction,
              filename: _currentFileName, line: _currentLine, column: _column);
      }
      instruction = _currentBytecodeModule.read();
    }
  }

  void _handleImportExport() {
    final isExported = _currentBytecodeModule.readBool();
    final isPreloadedModule = _currentBytecodeModule.readBool();
    final showList = <String>{};
    final showListLength = _currentBytecodeModule.read();
    for (var i = 0; i < showListLength; ++i) {
      final id = _currentBytecodeModule.readShortString();
      showList.add(id);
      if (isExported) {
        _currentNamespace.declareExport(id);
      }
    }
    final hasFromPath = _currentBytecodeModule.readBool();
    String? fromPath;
    if (hasFromPath) {
      fromPath = _currentBytecodeModule.readShortString();
    }
    String? alias;
    final hasAlias = _currentBytecodeModule.readBool();
    if (hasAlias) {
      alias = _currentBytecodeModule.readShortString();
    }
    if (isPreloadedModule) {
      assert(fromPath != null);
      final importedModule = _cachedModules[fromPath]!;
      final importedNamespace = importedModule.namespaces.values.last;
      _currentNamespace.import(importedNamespace);
    } else {
      if (fromPath != null) {
        final ext = path.extension(fromPath);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          // TODO: import binary bytes
          final value = _currentBytecodeModule.expressions[fromPath];
          assert(value != null);
          _currentNamespace.define(alias!, HTVariable(alias, value: value));
          if (isExported) {
            _currentNamespace.declareExport(alias);
          }
        } else {
          final decl = UnresolvedImportStatement(
            fromPath,
            alias: alias,
            showList: showList,
            isExported: isExported,
          );
          if (_currentFileResourceType == HTResourceType.hetuModule) {
            _currentNamespace.declareImport(decl);
          } else {
            _handleNamespaceImport(_currentNamespace, decl);
          }
        }
      }
    }
    _clearLocals();
  }

  void _storeLocal() {
    final valueType = _currentBytecodeModule.read();
    switch (valueType) {
      case HTValueTypeCode.nullValue:
        _localValue = null;
        break;
      case HTValueTypeCode.boolean:
        (_currentBytecodeModule.read() == 0)
            ? _localValue = false
            : _localValue = true;
        break;
      case HTValueTypeCode.constInt:
        final index = _currentBytecodeModule.readUint16();
        _localValue = _currentBytecodeModule.getGlobalConstant(int, index);
        break;
      case HTValueTypeCode.constFloat:
        final index = _currentBytecodeModule.readUint16();
        _localValue = _currentBytecodeModule.getGlobalConstant(double, index);
        break;
      case HTValueTypeCode.constString:
        final index = _currentBytecodeModule.readUint16();
        _localValue = _currentBytecodeModule.getGlobalConstant(String, index);
        break;
      case HTValueTypeCode.longString:
        _localValue = _currentBytecodeModule.readLongString();
        break;
      case HTValueTypeCode.stringInterpolation:
        var literal = _currentBytecodeModule.readLongString();
        final interpolationLength = _currentBytecodeModule.read();
        for (var i = 0; i < interpolationLength; ++i) {
          final value = execute();
          literal = literal.replaceAll(
              '${_lexicon.stringInterpolationStart}$i${_lexicon.stringInterpolationEnd}',
              lexicon.stringify(value));
        }
        _localValue = literal;
        break;
      case HTValueTypeCode.identifier:
        final symbol = _localSymbol = _currentBytecodeModule.readShortString();
        final isLocal = _currentBytecodeModule.readBool();
        if (isLocal) {
          _localValue = _currentNamespace.memberGet(symbol, isRecursive: true);
          // _curLeftValue = _curNamespace;
        } else {
          _localValue = symbol;
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
        _localValue = execute();
        break;
      case HTValueTypeCode.list:
        final list = [];
        final length = _currentBytecodeModule.readUint16();
        for (var i = 0; i < length; ++i) {
          final isSpread = _currentBytecodeModule.readBool();
          if (!isSpread) {
            final listItem = execute();
            list.add(listItem);
          } else {
            final List spreadValue = execute();
            list.addAll(spreadValue);
          }
        }
        _localValue = list;
        break;
      case HTValueTypeCode.struct:
        String? id;
        final hasId = _currentBytecodeModule.readBool();
        if (hasId) {
          id = _currentBytecodeModule.readShortString();
        }
        HTStruct? prototype;
        final hasPrototypeId = _currentBytecodeModule.readBool();
        if (hasPrototypeId) {
          final prototypeId = _currentBytecodeModule.readShortString();
          prototype = _currentNamespace.memberGet(prototypeId,
              from: _currentNamespace.fullName, isRecursive: true);
        }
        final struct = HTStruct(this,
            id: id,
            prototype: prototype,
            isRootPrototype: id == _lexicon.globalPrototypeId,
            closure: _currentNamespace);
        final fieldsCount = _currentBytecodeModule.read();
        for (var i = 0; i < fieldsCount; ++i) {
          final fieldType = _currentBytecodeModule.read();
          if (fieldType == StructObjFieldTypeCode.normal) {
            final key = _currentBytecodeModule.readShortString();
            final value = execute();
            struct[key] = value;
          } else if (fieldType == StructObjFieldTypeCode.spread) {
            final HTStruct spreadingStruct = execute();
            for (final key in spreadingStruct.keys) {
              // skip internal apis
              if (key.startsWith(_lexicon.internalPrefix)) continue;
              final copiedValue = toStructValue(spreadingStruct[key]);
              struct.define(key, copiedValue);
            }
          } else {
            // empty field
          }
        }
        // _curNamespace = savedCurNamespace;
        _localValue = struct;
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
        final internalName = _currentBytecodeModule.readShortString();
        final hasExternalTypedef = _currentBytecodeModule.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _currentBytecodeModule.readShortString();
        }
        final hasParamDecls = _currentBytecodeModule.readBool();
        final isVariadic = _currentBytecodeModule.readBool();
        final minArity = _currentBytecodeModule.read();
        final maxArity = _currentBytecodeModule.read();
        final paramDecls = _getParams(_currentBytecodeModule.read());
        HTType? returnType;
        final hasReturnType = _currentBytecodeModule.readBool();
        if (hasReturnType) {
          returnType = _handleTypeExpr();
        }
        final declType = HTFunctionType(
            parameterTypes: paramDecls.values
                .map((param) => HTParameterType(
                    declType:
                        param.declType ?? HTTypeIntrinsic.any(_lexicon.typeAny),
                    isOptional: param.isOptional,
                    isVariadic: param.isVariadic,
                    id: param.isNamed ? param.id : null))
                .toList(),
            returnType: returnType ?? HTTypeIntrinsic.any(_lexicon.typeAny));
        int? line, column, definitionIp;
        final hasDefinition = _currentBytecodeModule.readBool();
        if (hasDefinition) {
          line = _currentBytecodeModule.readUint16();
          column = _currentBytecodeModule.readUint16();
          final length = _currentBytecodeModule.readUint16();
          definitionIp = _currentBytecodeModule.ip;
          _currentBytecodeModule.skip(length);
        }
        final func = HTFunction(
            internalName, _currentFileName, _currentBytecodeModule.id, this,
            closure: _currentNamespace,
            category: FunctionCategory.literal,
            externalTypeId: externalTypedef,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
            declType: declType,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            definitionIp: definitionIp,
            definitionLine: line,
            definitionColumn: column,
            namespace: _currentNamespace);
        if (!hasExternalTypedef) {
          _localValue = func;
        } else {
          final externalFunc = unwrapExternalFunctionType(func);
          _localValue = externalFunc;
        }
        break;
      case HTValueTypeCode.type:
        _localValue = _handleTypeExpr();
        break;
      default:
        throw HTError.unkownValueType(valueType,
            filename: _currentFileName, line: _currentLine, column: _column);
    }
  }

  void _handleWhen() {
    var condition = _localValue;
    final hasCondition = _currentBytecodeModule.readBool();
    final casesCount = _currentBytecodeModule.read();
    for (var i = 0; i < casesCount; ++i) {
      final caseType = _currentBytecodeModule.read();
      // If condition expression is provided,
      // jump to the first case branch where its value equals condition.
      // If condition expression is not provided,
      // jump to the first case branch where its value is true.
      // If no case branch matches condition and else branch is provided,
      // will jump to else branch.
      if (caseType == WhenCaseTypeCode.equals) {
        final value = execute();
        if (hasCondition) {
          if (condition == value) {
            break;
          }
        } else if (value) {
          break;
        }
        // skip jumpping to branch
        _currentBytecodeModule.skip(3);
      } else if (caseType == WhenCaseTypeCode.eigherEquals) {
        assert(hasCondition);
        final count = _currentBytecodeModule.read();
        final values = [];
        for (var i = 0; i < count; ++i) {
          values.add(execute());
        }
        if (values.contains(condition)) {
          break;
        } else {
          // skip jumpping to branch
          _currentBytecodeModule.skip(3);
        }
      } else if (caseType == WhenCaseTypeCode.elementIn) {
        assert(hasCondition);
        final Iterable value = execute();
        if (value.contains(condition)) {
          break;
        } else {
          // skip jumpping to branch
          _currentBytecodeModule.skip(3);
        }
      }
    }
  }

  void _handleBinaryOp(int opcode) {
    switch (opcode) {
      case HTOpCode.ifNull:
        final left = _getRegVal(HTRegIdx.orLeft);
        final rightValueLength = _currentBytecodeModule.readUint16();
        if (left != null) {
          _currentBytecodeModule.skip(rightValueLength);
          _localValue = left;
        } else {
          final right = execute();
          _localValue = right;
        }
        break;
      case HTOpCode.logicalOr:
        final left = _getRegVal(HTRegIdx.orLeft);
        final leftTruthValue = _truthy(left);
        final rightValueLength = _currentBytecodeModule.readUint16();
        if (leftTruthValue) {
          _currentBytecodeModule.skip(rightValueLength);
          _localValue = leftTruthValue;
        } else {
          final right = execute();
          _localValue = _truthy(right);
        }
        break;
      case HTOpCode.logicalAnd:
        final left = _getRegVal(HTRegIdx.andLeft);
        final leftTruthValue = _truthy(left);
        final rightValueLength = _currentBytecodeModule.readUint16();
        if (!leftTruthValue) {
          _currentBytecodeModule.skip(rightValueLength);
          _localValue = false;
        } else {
          final right = execute();
          final rightTruthValue = _truthy(right);
          _localValue = leftTruthValue && rightTruthValue;
        }
        break;
      case HTOpCode.equal:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _localValue = left == _localValue;
        break;
      case HTOpCode.notEqual:
        final left = _getRegVal(HTRegIdx.equalLeft);
        _localValue = left != _localValue;
        break;
      case HTOpCode.lesser:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left < _localValue;
        break;
      case HTOpCode.greater:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left > _localValue;
        break;
      case HTOpCode.lesserOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left <= _localValue;
        break;
      case HTOpCode.greaterOrEqual:
        final left = _getRegVal(HTRegIdx.relationLeft);
        _localValue = left >= _localValue;
        break;
      case HTOpCode.typeAs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type =
            (_localValue as HTType).resolve(_currentNamespace) as HTNominalType;
        final klass = type.klass as HTClass;
        _localValue = HTCast(object, klass, this);
        break;
      case HTOpCode.typeIs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_localValue as HTType).resolve(_currentNamespace);
        final encapsulated = encapsulate(object);
        _localValue = encapsulated.valueType?.isA(type) ?? false;
        break;
      case HTOpCode.typeIsNot:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type = (_localValue as HTType).resolve(_currentNamespace);
        final encapsulated = encapsulate(object);
        _localValue = encapsulated.valueType?.isNotA(type) ?? true;
        break;
      case HTOpCode.add:
        var left = _getRegVal(HTRegIdx.addLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _localValue;
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left + right;
        break;
      case HTOpCode.subtract:
        var left = _getRegVal(HTRegIdx.addLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _localValue;
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left - right;
        break;
      case HTOpCode.multiply:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        var right = _localValue;
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left * right;
        break;
      case HTOpCode.devide:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        final right = _localValue;
        _localValue = left / right;
        break;
      case HTOpCode.truncatingDevide:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        final right = _localValue;
        _localValue = left ~/ right;
        break;
      case HTOpCode.modulo:
        var left = _getRegVal(HTRegIdx.multiplyLeft);
        if (_isZero(left)) {
          left = 0;
        }
        final right = _localValue;
        _localValue = left % right;
        break;
    }
  }

  void _handleUnaryPrefixOp(int op) {
    final object = _localValue;
    switch (op) {
      case HTOpCode.negative:
        _localValue = -object;
        break;
      case HTOpCode.logicalNot:
        final truthValue = _truthy(object);
        _localValue = !truthValue;
        break;
      case HTOpCode.typeOf:
        final encap = encapsulate(object);
        final type = encap.valueType;
        if (type == null) {
          _localValue = HTTypeIntrinsic.unknown(_lexicon.typeUnknown);
        } else {
          _localValue = type;
        }
        break;
    }
  }

  void _handleCallExpr() {
    final isNullable = _currentBytecodeModule.readBool();
    final hasNewOperator = _currentBytecodeModule.readBool();
    final callee = _getRegVal(HTRegIdx.postfixObject);
    final argsBytesLength = _currentBytecodeModule.readUint16();
    if (callee == null) {
      if (isNullable) {
        _currentBytecodeModule.skip(argsBytesLength);
        _localValue = null;
        return;
      } else {
        throw HTError.nullObject(
            localSymbol ?? _lexicon.kNull, InternalIdentifier.call,
            filename: _currentFileName, line: _currentLine, column: _column);
      }
    }
    final positionalArgs = [];
    final positionalArgsLength = _currentBytecodeModule.read();
    for (var i = 0; i < positionalArgsLength; ++i) {
      final isSpread = _currentBytecodeModule.readBool();
      if (!isSpread) {
        final arg = execute();
        positionalArgs.add(arg);
      } else {
        final List spreadValue = execute();
        positionalArgs.addAll(spreadValue);
      }
    }
    final namedArgs = <String, dynamic>{};
    final namedArgsLength = _currentBytecodeModule.read();
    for (var i = 0; i < namedArgsLength; ++i) {
      final name = _currentBytecodeModule.readShortString();
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      namedArgs[name] = arg;
    }
    final typeArgs = _localTypeArgs;

    void handleCLassConstructor() {
      late HTClass klass;
      if (callee is HTType) {
        final resolvedType = callee.resolve(_currentNamespace) as HTNominalType;
        // if (resolvedType is! HTNominalType) {
        //   throw HTError.notCallable(callee.toString(),
        //       filename: _fileName, line: _line, column: _column);
        // }
        klass = resolvedType.klass as HTClass;
      } else {
        klass = callee;
      }
      if (klass.isAbstract) {
        throw HTError.abstracted(
            filename: _currentFileName, line: _currentLine, column: _column);
      }
      if (klass.contains(InternalIdentifier.defaultConstructor)) {
        final constructor = klass
            .memberGet(InternalIdentifier.defaultConstructor) as HTFunction;
        _localValue = constructor.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(klass.id!,
            filename: _currentFileName, line: _currentLine, column: _column);
      }
    }

    void handleStructConstructor() {
      HTNamedStruct def = callee.declaration!;
      _localValue = def.createObject(
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
      );
    }

    if (hasNewOperator) {
      if ((callee is HTClass) || (callee is HTType)) {
        handleCLassConstructor();
      } else if (callee is HTStruct && callee.declaration != null) {
        handleStructConstructor();
      } else {
        throw HTError.notNewable(lexicon.stringify(callee),
            filename: _currentFileName, line: _currentLine, column: _column);
      }
    } else {
      // calle is a script function
      if (callee is HTFunction) {
        _localValue = callee.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      }
      // calle is a dart function
      else if (callee is Function) {
        if (callee is HTExternalFunction) {
          _localValue = callee(_currentNamespace,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          _localValue = Function.apply(
              callee,
              positionalArgs,
              namedArgs.map<Symbol, dynamic>(
                  (key, value) => MapEntry(Symbol(key), value)));
        }
      } else if ((callee is HTClass) || (callee is HTType)) {
        handleCLassConstructor();
      } else if (callee is HTStruct && callee.declaration != null) {
        handleStructConstructor();
      } else {
        throw HTError.notCallable(
            lexicon.stringify(callee, asStringLiteral: true),
            filename: _currentFileName,
            line: _currentLine,
            column: _column);
      }
    }
  }

  HTType _handleTypeExpr() {
    final index = _currentBytecodeModule.read();
    final typeType = TypeType.values.elementAt(index);
    switch (typeType) {
      case TypeType.normal:
        final typeName = _currentBytecodeModule.readShortString();
        final typeArgsLength = _currentBytecodeModule.read();
        final typeArgs = <HTUnresolvedType>[];
        for (var i = 0; i < typeArgsLength; ++i) {
          final typearg = _handleTypeExpr() as HTUnresolvedType;
          typeArgs.add(typearg);
        }
        final isNullable = (_currentBytecodeModule.read() == 0) ? false : true;
        if (typeName == _lexicon.typeAny) {
          return HTTypeIntrinsic.any(_lexicon.typeAny);
        } else if (typeName == _lexicon.typeUnknown) {
          return HTTypeIntrinsic.unknown(_lexicon.typeUnknown);
        } else if (typeName == _lexicon.typeVoid) {
          return HTTypeIntrinsic.vo1d(_lexicon.typeVoid);
        } else if (typeName == _lexicon.typeNever) {
          return HTTypeIntrinsic.never(_lexicon.typeNever);
        } else {
          return HTUnresolvedType(typeName,
              typeArgs: typeArgs, isNullable: isNullable);
        }
      case TypeType.function:
        final paramsLength = _currentBytecodeModule.read();
        final parameterTypes = <HTParameterType>[];
        for (var i = 0; i < paramsLength; ++i) {
          final declType = _handleTypeExpr();
          final isOptional = _currentBytecodeModule.read() == 0 ? false : true;
          final isVariadic = _currentBytecodeModule.read() == 0 ? false : true;
          final isNamed = _currentBytecodeModule.read() == 0 ? false : true;
          String? paramId;
          if (isNamed) {
            paramId = _currentBytecodeModule.readShortString();
          }
          final decl = HTParameterType(
              id: paramId,
              declType: declType,
              isOptional: isOptional,
              isVariadic: isVariadic);
          parameterTypes.add(decl);
        }
        final returnType = _handleTypeExpr();
        return HTFunctionType(
            parameterTypes: parameterTypes, returnType: returnType);
      case TypeType.structural:
        final fieldsLength = _currentBytecodeModule.readUint16();
        final fieldTypes = <String, HTType>{};
        for (var i = 0; i < fieldsLength; ++i) {
          final id = _currentBytecodeModule.readShortString();
          final typeExpr = _handleTypeExpr();
          fieldTypes[id] = typeExpr;
        }
        return HTStructuralType(currentNamespace, fieldTypes: fieldTypes);
      case TypeType.union:
        throw 'Union Type is not implemented yet in this version of Hetu.';
    }
  }

  void _handleTypeAliasDecl() {
    final id = _currentBytecodeModule.readShortString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.readShortString();
    }
    final value = _handleTypeExpr();
    final decl = HTVariable(id,
        classId: classId, closure: _currentNamespace, value: value);
    _currentNamespace.define(id, decl);
    _clearLocals();
  }

  void _handleConstDecl() {
    final id = _currentBytecodeModule.readShortString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.readShortString();
    }
    final typeIndex = _currentBytecodeModule.read();
    final type = HTConstantType.values.elementAt(typeIndex);
    final index = _currentBytecodeModule.readInt16();
    final decl = HTConstantValue(
        id: id,
        type: getConstantType(type),
        index: index,
        classId: classId,
        module: _currentBytecodeModule);
    _currentNamespace.define(id, decl, override: config.allowVariableShadowing);
    _clearLocals();
  }

  void _handleVarDecl() {
    final id = _currentBytecodeModule.readShortString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.readShortString();
    }
    final isField = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isStatic = _currentBytecodeModule.readBool();
    final isMutable = _currentBytecodeModule.readBool();
    final lateFinalize = _currentBytecodeModule.readBool();
    final lateInitialize = _currentBytecodeModule.readBool();
    HTType? declType;
    final hasTypeDecl = _currentBytecodeModule.readBool();
    if (hasTypeDecl) {
      declType = _handleTypeExpr();
    }
    late final HTVariable decl;
    final hasInitializer = _currentBytecodeModule.readBool();
    dynamic initValue;
    if (hasInitializer) {
      if (lateInitialize) {
        final definitionLine = _currentBytecodeModule.readUint16();
        final definitionColumn = _currentBytecodeModule.readUint16();
        final length = _currentBytecodeModule.readUint16();
        final definitionIp = _currentBytecodeModule.ip;
        _currentBytecodeModule.skip(length);
        decl = HTVariable(id,
            interpreter: this,
            fileName: _currentFileName,
            moduleName: _currentBytecodeModule.id,
            classId: classId,
            closure: _currentNamespace,
            declType: declType,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        initValue = execute();
        decl = HTVariable(id,
            interpreter: this,
            fileName: _currentFileName,
            moduleName: _currentBytecodeModule.id,
            classId: classId,
            closure: _currentNamespace,
            declType: declType,
            value: initValue,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable);
      }
    } else {
      decl = HTVariable(id,
          interpreter: this,
          fileName: _currentFileName,
          moduleName: _currentBytecodeModule.id,
          classId: classId,
          closure: _currentNamespace,
          declType: declType,
          isExternal: isExternal,
          isStatic: isStatic,
          isMutable: isMutable,
          lateFinalize: lateFinalize);
    }
    if (!isField) {
      _currentNamespace.define(id, decl,
          override: config.allowVariableShadowing);
    }
    _localValue = initValue;
  }

  void _handleDestructuringDecl() {
    final idCount = _currentBytecodeModule.read();
    final ids = <String, HTType?>{};
    final omittedPrefix = '##';
    var omittedIndex = 0;
    for (var i = 0; i < idCount; ++i) {
      var id = _currentBytecodeModule.readShortString();
      // omit '_' symbols
      if (id == _lexicon.omittedMark) {
        id = omittedPrefix + (omittedIndex++).toString();
      }
      HTType? declType;
      final hasTypeDecl = _currentBytecodeModule.readBool();
      if (hasTypeDecl) {
        declType = _handleTypeExpr();
      }
      ids[id] = declType;
    }
    final isVector = _currentBytecodeModule.readBool();
    final isMutable = _currentBytecodeModule.readBool();
    final collection = execute();
    for (var i = 0; i < ids.length; ++i) {
      final id = ids.keys.elementAt(i);
      dynamic initValue;
      if (isVector) {
        // omit '_' symbols
        if (id.startsWith(omittedPrefix)) {
          continue;
        }
        initValue = (collection as Iterable).elementAt(i);
      } else {
        if (collection is HTEntity) {
          initValue = collection.memberGet(id);
        } else {
          initValue = collection[id];
        }
      }
      final decl = HTVariable(id,
          interpreter: this,
          fileName: _currentFileName,
          moduleName: _currentBytecodeModule.id,
          closure: _currentNamespace,
          declType: ids[id],
          value: initValue,
          isMutable: isMutable);
      _currentNamespace.define(id, decl,
          override: config.allowVariableShadowing);
    }
    _clearLocals();
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};
    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _currentBytecodeModule.readShortString();
      final isOptional = _currentBytecodeModule.readBool();
      final isVariadic = _currentBytecodeModule.readBool();
      final isNamed = _currentBytecodeModule.readBool();
      HTType? declType;
      final hasTypeDecl = _currentBytecodeModule.readBool();
      if (hasTypeDecl) {
        declType = _handleTypeExpr();
      }
      int? definitionIp;
      int? definitionLine;
      int? definitionColumn;
      final hasInitializer = _currentBytecodeModule.readBool();
      if (hasInitializer) {
        definitionLine = _currentBytecodeModule.readUint16();
        definitionColumn = _currentBytecodeModule.readUint16();
        final length = _currentBytecodeModule.readUint16();
        definitionIp = _currentBytecodeModule.ip;
        _currentBytecodeModule.skip(length);
      }
      paramDecls[id] = HTParameter(id,
          interpreter: this,
          fileName: _currentFileName,
          moduleName: _currentBytecodeModule.id,
          closure: _currentNamespace,
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
    final internalName = _currentBytecodeModule.readShortString();
    String? id;
    final hasId = _currentBytecodeModule.readBool();
    if (hasId) {
      id = _currentBytecodeModule.readShortString();
    }
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.readShortString();
    }
    String? externalTypeId;
    final hasExternalTypedef = _currentBytecodeModule.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _currentBytecodeModule.readShortString();
    }
    final category = FunctionCategory.values[_currentBytecodeModule.read()];
    final isField = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isStatic = _currentBytecodeModule.readBool();
    final isConst = _currentBytecodeModule.readBool();
    final hasParamDecls = _currentBytecodeModule.readBool();
    final isVariadic = _currentBytecodeModule.readBool();
    final minArity = _currentBytecodeModule.read();
    final maxArity = _currentBytecodeModule.read();
    final paramLength = _currentBytecodeModule.read();
    final paramDecls = _getParams(paramLength);
    HTType? returnType;
    final hasReturnType = _currentBytecodeModule.readBool();
    if (hasReturnType) {
      returnType = _handleTypeExpr();
    }
    final declType = HTFunctionType(
        parameterTypes: paramDecls.values
            .map((param) => HTParameterType(
                declType:
                    param.declType ?? HTTypeIntrinsic.any(_lexicon.typeAny),
                isOptional: param.isOptional,
                isVariadic: param.isVariadic,
                id: param.isNamed ? param.id : null))
            .toList(),
        returnType: returnType ?? HTTypeIntrinsic.any(_lexicon.typeAny));
    RedirectingConstructor? redirCtor;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    if (category == FunctionCategory.constructor) {
      final hasRedirectingCtor = _currentBytecodeModule.readBool();
      if (hasRedirectingCtor) {
        final calleeId = _currentBytecodeModule.readShortString();
        final hasCtorName = _currentBytecodeModule.readBool();
        String? ctorName;
        if (hasCtorName) {
          ctorName = _currentBytecodeModule.readShortString();
        }
        final positionalArgIpsLength = _currentBytecodeModule.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _currentBytecodeModule.readUint16();
          positionalArgIps.add(_currentBytecodeModule.ip);
          _currentBytecodeModule.skip(argLength);
        }
        final namedArgsLength = _currentBytecodeModule.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _currentBytecodeModule.readShortString();
          final argLength = _currentBytecodeModule.readUint16();
          namedArgIps[argName] = _currentBytecodeModule.ip;
          _currentBytecodeModule.skip(argLength);
        }
        redirCtor = RedirectingConstructor(calleeId,
            key: ctorName,
            positionalArgsIp: positionalArgIps,
            namedArgsIp: namedArgIps);
      }
    }
    int? line, column, definitionIp;
    final hasDefinition = _currentBytecodeModule.readBool();
    if (hasDefinition) {
      line = _currentBytecodeModule.readUint16();
      column = _currentBytecodeModule.readUint16();
      final length = _currentBytecodeModule.readUint16();
      definitionIp = _currentBytecodeModule.ip;
      _currentBytecodeModule.skip(length);
    }
    final func = HTFunction(
        internalName, _currentFileName, _currentBytecodeModule.id, this,
        id: id,
        classId: classId,
        closure: _currentNamespace,
        isField: isField,
        isExternal: isExternal,
        isStatic: isStatic,
        isConst: isConst,
        category: category,
        externalTypeId: externalTypeId,
        hasParamDecls: hasParamDecls,
        paramDecls: paramDecls,
        declType: declType,
        isVariadic: isVariadic,
        minArity: minArity,
        maxArity: maxArity,
        definitionIp: definitionIp,
        definitionLine: line,
        definitionColumn: column,
        redirectingConstructor: redirCtor);
    if (isField) {
      _localValue = func;
    } else {
      if ((category != FunctionCategory.constructor) || isStatic) {
        func.namespace = _currentNamespace;
      }
      _currentNamespace.define(func.internalName, func);
    }
    _localValue = func;
  }

  void _handleClassDecl() {
    final id = _currentBytecodeModule.readShortString();
    final isExternal = _currentBytecodeModule.readBool();
    final isAbstract = _currentBytecodeModule.readBool();
    final hasUserDefinedConstructor = _currentBytecodeModule.readBool();
    HTType? superType;
    final hasSuperClass = _currentBytecodeModule.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != _lexicon.globalObjectId)) {
        final HTClass object = rootClass ??
            globalNamespace.memberGet(lexicon.globalObjectId,
                isRecursive: true);
        superType = HTNominalType(object);
      }
    }
    final isEnum = _currentBytecodeModule.readBool();
    final klass = HTClass(this,
        id: id,
        closure: _currentNamespace,
        superType: superType,
        isExternal: isExternal,
        isAbstract: isAbstract,
        isEnum: isEnum);
    _currentNamespace.define(id, klass);
    final savedClass = _class;
    _class = klass;
    // deal with definition block
    execute(namespace: klass.namespace);
    // Add default constructor if there's none.
    if (!isAbstract && !hasUserDefinedConstructor && !isExternal) {
      final ctorType =
          HTFunctionType(returnType: HTTypeIntrinsic.any(_lexicon.typeAny));
      final ctor = HTFunction(InternalIdentifier.defaultConstructor,
          _currentFileName, _currentBytecodeModule.id, this,
          classId: klass.id,
          closure: klass.namespace,
          category: FunctionCategory.constructor,
          declType: ctorType);
      klass.namespace.define(InternalIdentifier.defaultConstructor, ctor);
    }
    // if (_isModuleEntryScript || _function != null) {
    //   klass.resolve();
    // }
    _class = savedClass;
    _localValue = klass;
  }

  void _handleExternalEnumDecl() {
    final id = _currentBytecodeModule.readShortString();
    final enumClass = HTExternalEnum(id, this);
    _currentNamespace.define(id, enumClass);
    _localValue = enumClass;
  }

  void _handleStructDecl() {
    final id = _currentBytecodeModule.readShortString();
    String? prototypeId;
    final hasPrototypeId = _currentBytecodeModule.readBool();
    if (hasPrototypeId) {
      prototypeId = _currentBytecodeModule.readShortString();
    } else if (id != _lexicon.globalPrototypeId) {
      prototypeId = _lexicon.globalPrototypeId;
    }
    // final lateInitialize = _currentBytecodeModule.readBool();
    final staticFieldsLength = _currentBytecodeModule.readUint16();
    final staticDefinitionIp = _currentBytecodeModule.ip;
    _currentBytecodeModule.skip(staticFieldsLength);
    final fieldsLength = _currentBytecodeModule.readUint16();
    final definitionIp = _currentBytecodeModule.ip;
    _currentBytecodeModule.skip(fieldsLength);
    final struct = HTNamedStruct(
      id: id,
      interpreter: this,
      fileName: _currentFileName,
      moduleName: _currentBytecodeModule.id,
      closure: _currentNamespace,
      prototypeId: prototypeId,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: definitionIp,
    );
    // if (_isModuleEntryScript || !lateInitialize) {
    //   struct.resolve();
    // }
    _currentNamespace.define(id, struct);
    _localValue = struct;
  }
}
