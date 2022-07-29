import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:hetu_script/declaration/declaration.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import '../value/class/class_namespace.dart';
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

/// Collection of config of bytecode interpreter.
class InterpreterConfig implements AnalyzerImplConfig, ErrorHandlerConfig {
  @override
  bool showDartStackTrace;

  @override
  bool showHetuStackTrace;

  @override
  int stackTraceDisplayCountLimit;

  @override
  bool processError;

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
      this.processError = true,
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

/// Determines how the interepreter deal with stack frame information when context are changed.
enum StackFrameStrategy {
  none,
  retract,
  create,
}

/// The exucution context of the bytecode interpreter.
class HTContext {
  final String? filename;
  final String? moduleName;
  final HTNamespace? namespace;
  final int? ip;
  final int? line;
  final int? column;

  HTContext({
    this.filename,
    this.moduleName,
    this.namespace,
    this.ip,
    this.line,
    this.column,
  });
}

/// A wrapper class for the bytecode interpreter to run a certain task in a future.
class FutureExecution {
  Future future;
  HTContext context;

  FutureExecution({
    required this.future,
    required this.context,
  });
}

/// A bytecode implementation of Hetu Script interpreter
class HTInterpreter {
  static HTClass? rootClass;
  static HTStruct? rootStruct;

  final stackTraceList = <String>[];

  final cachedModules = <String, HTBytecodeModule>{};

  InterpreterConfig config;

  late final HTLexicon _lexicon;
  HTLexicon get lexicon => _lexicon;

  HTResourceContext<HTSource> sourceContext;

  ErrorHandlerConfig get errorConfig => config;

  late final HTNamespace globalNamespace;

  late HTNamespace _currentNamespace;
  HTNamespace get currentNamespace => _currentNamespace;

  String _currentFileName = '';
  String get currentFileName => _currentFileName;

  bool _isModuleEntryScript = false;
  late HTResourceType _currentFileResourceType;

  late HTBytecodeModule _currentBytecodeModule;
  HTBytecodeModule get currentBytecodeModule => _currentBytecodeModule;

  var _currentLine = 0;
  int get currentLine => _currentLine;

  var _column = 0;
  int get currentColumn => _column;

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
        _lexicon = lexicon ?? HTDefaultLexicon() {
    globalNamespace = HTNamespace(lexicon: _lexicon, id: Semantic.global);
    _currentNamespace = globalNamespace;
  }

  /// inexpicit type conversion for zero or null values
  bool _isZero(dynamic condition) {
    if (config.allowImplicitNullToZeroConversion) {
      return condition == 0 || condition == null;
    } else {
      return condition == 0;
    }
  }

  /// inexpicit type conversion for truthy values
  bool _truthy(dynamic condition) {
    if (config.allowImplicitEmptyValueToFalseConversion) {
      if (condition == false ||
          condition == null ||
          condition == '' ||
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
  void processError(Object error, [Object? externalStackTrace]) {
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
        _lexicon.stringify(error),
        extra: stackTraceString,
        filename: currentFileName,
        line: currentLine,
        column: currentColumn,
      );
      throw hetuError;
    }
  }

  /// handler for various kinds of invocations.
  dynamic _call(
    dynamic callee, {
    bool isConstructorCall = false,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const [],
  }) {
    dynamic handleClassConstructor(dynamic callee) {
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
        return constructor.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs,
        );
      } else {
        throw HTError.notCallable(klass.id!,
            filename: _currentFileName, line: _currentLine, column: _column);
      }
    }

    if (isConstructorCall) {
      if ((callee is HTClass) || (callee is HTType)) {
        return handleClassConstructor(callee);
      } else if (callee is HTStruct && callee.declaration != null) {
        return callee.declaration!.createObject(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs,
        );
      } else {
        throw HTError.notNewable(_lexicon.stringify(callee),
            filename: _currentFileName, line: _currentLine, column: _column);
      }
    } else {
      // calle is a script function
      if (callee is HTFunction) {
        return callee.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      }
      // calle is a dart function
      else if (callee is Function) {
        if (callee is HTExternalFunction) {
          return callee(_currentNamespace,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
        } else {
          return Function.apply(
              callee,
              positionalArgs,
              namedArgs.map<Symbol, dynamic>(
                  (key, value) => MapEntry(Symbol(key), value)));
        }
      } else if ((callee is HTClass) || (callee is HTType)) {
        return handleClassConstructor(callee);
      } else if (callee is HTStruct && callee.declaration != null) {
        return callee.declaration!.createObject(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs,
        );
      } else {
        throw HTError.notCallable(
            _lexicon.stringify(callee, asStringLiteral: true),
            filename: _currentFileName,
            line: _currentLine,
            column: _column);
      }
    }
  }

  /// Get a namespace in certain module with a certain name.
  HTNamespace getNamespace({String? moduleName}) {
    var nsp = globalNamespace;
    if (moduleName != null) {
      final bytecodeModule = cachedModules[moduleName]!;
      assert(bytecodeModule.namespaces.isNotEmpty);
      nsp = bytecodeModule.namespaces.values.last;
    }
    return nsp;
  }

  /// Add a declaration to certain namespace.
  /// if the value is not a declaration, will create one with [isMutable] value.
  /// if not, the [isMutable] will be ignored.
  bool define(
    String varName,
    dynamic value, {
    bool isMutable = false,
    bool override = false,
    bool throws = true,
    String? moduleName,
  }) {
    final nsp = getNamespace(moduleName: moduleName);
    if (value is HTDeclaration) {
      return nsp.define(varName, value, override: override, throws: throws);
    } else {
      final decl = HTVariable(id: varName, value: value, isMutable: isMutable);
      return nsp.define(varName, decl, override: override, throws: throws);
    }
  }

  /// Get the documentation of a declaration in a certain namespace.
  String? help(
    dynamic id, {
    String? moduleName,
  }) {
    try {
      if (id is HTDeclaration) {
        return id.documentation;
      } else if (id is String) {
        HTNamespace nsp = getNamespace(moduleName: moduleName);
        return nsp.help(id);
      } else {
        throw 'The argument of the `help` api [$id] is neither a defined symbol nor a string.';
      }
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
        return null;
      } else {
        rethrow;
      }
    }
  }

  /// Get a top level variable defined in a certain namespace.
  dynamic fetch(
    String varName, {
    String? moduleName,
  }) {
    try {
      final savedModuleName = _currentBytecodeModule.id;
      HTNamespace nsp = getNamespace(moduleName: moduleName);
      final result = nsp.memberGet(varName, isRecursive: false);
      if (_currentBytecodeModule.id != savedModuleName) {
        _currentBytecodeModule = cachedModules[savedModuleName]!;
      }
      return result;
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  /// Assign value to a top level variable defined in a certain namespace in the interpreter.
  void assign(
    String varName,
    dynamic value, {
    String? moduleName,
  }) {
    try {
      final savedModuleName = _currentBytecodeModule.id;
      HTNamespace nsp = getNamespace(moduleName: moduleName);
      nsp.memberSet(varName, value, isRecursive: false);
      if (_currentBytecodeModule.id != savedModuleName) {
        _currentBytecodeModule = cachedModules[savedModuleName]!;
      }
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  /// Invoke a top level function defined in a certain namespace.
  /// It's possible to use this method to invoke a [HTClass] or [HTNamedStruct]
  /// name as a contruct call, you will get a [HTInstance] or [HTStruct] as return value.
  dynamic invoke(String funcName,
      {String? moduleName,
      bool isConstructorCall = false,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    try {
      stackTraceList.clear();
      final savedModuleName = _currentBytecodeModule.id;
      HTNamespace nsp = globalNamespace;
      if (moduleName != null) {
        if (_currentBytecodeModule.id != moduleName) {
          _currentBytecodeModule = cachedModules[moduleName]!;
        }
        assert(_currentBytecodeModule.namespaces.isNotEmpty);
        nsp = _currentBytecodeModule.namespaces.values.last;
      }
      final callee = nsp.memberGet(funcName, isRecursive: false);
      final result = _call(
        callee,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
      );
      if (_currentBytecodeModule.id != savedModuleName) {
        _currentBytecodeModule = cachedModules[savedModuleName]!;
      }
      return result;
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  final externFunctions = <String, Function>{};
  final externFunctionTypedefs = <String, HTExternalFunctionTypedef>{};
  final externClasses = <String, HTExternalClass>{};
  final externTypeReflection = <HTExternalTypeReflection>[];

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
    if (externFunctions.containsKey(id) && !override) {
      throw HTError.defined(id, ErrorType.runtimeError);
    }
    externFunctions[id] = function;
  }

  /// Fetch a external function
  Function fetchExternalFunction(String id) {
    if (!externFunctions.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externFunctions[id]!;
  }

  /// Register a external function typedef into scrfipt
  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function,
      {bool override = false}) {
    if (externFunctionTypedefs.containsKey(id) && !override) {
      throw HTError.defined(id, ErrorType.runtimeError);
    }
    externFunctionTypedefs[id] = function;
  }

  /// Using unwrapper to turn a script function into a external function
  Function unwrapExternalFunctionType(HTFunction func) {
    if (!externFunctionTypedefs.containsKey(func.externalTypeId)) {
      throw HTError.undefinedExternal(func.externalTypeId!);
    }
    final unwrapFunc = externFunctionTypedefs[func.externalTypeId]!;
    return unwrapFunc(func);
  }

  void switchModule(String moduleName) {
    assert(cachedModules.containsKey(moduleName));
    setContext(context: HTContext(moduleName: moduleName));
  }

  HTBytecodeModule? getBytecode(String moduleName) {
    return cachedModules[moduleName];
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
      typeString = _lexicon.typeInteger;
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
    } else if (object is math.Random) {
      typeString = 'Random';
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
          globalNamespace.memberGet(_lexicon.globalPrototypeId,
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
    final importedNamespace = _currentBytecodeModule.namespaces[decl.fromPath]!;

    // for script and literal code, namespaces are resolved immediately.
    if (_currentFileResourceType == HTResourceType.hetuScript ||
        _currentFileResourceType == HTResourceType.hetuLiteralCode) {
      for (final importDecl in importedNamespace.imports.values) {
        _handleNamespaceImport(importedNamespace, importDecl);
      }
      // for (final declaration in importNamespace.declarations.values) {
      //   declaration.resolve();
      // }
    }

    if (decl.alias == null) {
      if (decl.showList.isEmpty) {
        nsp.import(importedNamespace, export: decl.isExported);
      } else {
        for (final id in decl.showList) {
          HTDeclaration decl;
          if (importedNamespace.symbols.containsKey(id)) {
            decl = importedNamespace.symbols[id]!;
          } else if (importedNamespace.exports.contains(id)) {
            decl = importedNamespace.importedSymbols[id]!;
          } else {
            throw HTError.undefined(id);
          }
          nsp.defineImport(id, decl);
        }
      }
    } else {
      if (decl.showList.isEmpty) {
        nsp.defineImport(decl.alias!, importedNamespace);
      } else {
        final aliasNamespace = HTNamespace(
            lexicon: _lexicon, id: decl.alias!, closure: nsp.closure);
        for (final id in decl.showList) {
          if (!importedNamespace.symbols.containsKey(id)) {
            throw HTError.undefined(id);
          }
          final decl = importedNamespace.symbols[id]!;
          assert(!decl.isPrivate);
          aliasNamespace.define(id, decl);
        }
        nsp.defineImport(decl.alias!, aliasNamespace);
      }
    }
  }

  Version _handleVersion() {
    final major = _currentBytecodeModule.read();
    final minor = _currentBytecodeModule.read();
    final patch = _currentBytecodeModule.readUint16();
    final preReleaseLength = _currentBytecodeModule.read();
    String? preRelease;
    for (var i = 0; i < preReleaseLength; ++i) {
      preRelease ??= '';
      preRelease += _currentBytecodeModule.readUtf8String();
    }
    final buildLength = _currentBytecodeModule.read();
    String? build;
    for (var i = 0; i < buildLength; ++i) {
      build ??= '';
      build += _currentBytecodeModule.readUtf8String();
    }
    return Version(major, minor, patch, pre: preRelease, build: build);
  }

  /// Load a pre-compiled bytecode file as a module.
  /// If [invokeFunc] is true, execute the bytecode immediately.
  dynamic loadBytecode({
    required Uint8List bytes,
    required String moduleName,
    bool globallyImport = false,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const [],
    bool printPerformanceStatistics = false,
  }) {
    try {
      final tik = DateTime.now().millisecondsSinceEpoch;
      _currentBytecodeModule = HTBytecodeModule(id: moduleName, bytes: bytes);
      cachedModules[_currentBytecodeModule.id] = _currentBytecodeModule;
      final signature = _currentBytecodeModule.readUint32();
      if (signature != HTCompiler.hetuSignature) {
        throw HTError.bytecode(
            filename: _currentFileName, line: _currentLine, column: _column);
      }
      // compare the version of the compiler of the bytecode to my version.
      final compilerVersion = _handleVersion();
      var incompatible = false;
      if (compilerVersion.major > 0) {
        if (compilerVersion.major > kHetuVersion.major) {
          incompatible = true;
        }
      } else {
        if (compilerVersion != kHetuVersion) {
          incompatible = true;
        }
      }
      if (incompatible) {
        throw HTError.version(
          _currentBytecodeModule.version.toString(),
          kHetuVersion.toString(),
          filename: _currentFileName,
          line: _currentLine,
          column: _column,
        );
      }
      // read the version of the bytecode.
      final hasVersion = _currentBytecodeModule.readBool();
      if (hasVersion) {
        _currentBytecodeModule.version = _handleVersion();
      }
      _currentBytecodeModule.compiledAt =
          _currentBytecodeModule.readUtf8String();
      _currentFileName = _currentBytecodeModule.readUtf8String();
      final sourceType =
          HTResourceType.values.elementAt(_currentBytecodeModule.read());
      _isModuleEntryScript = sourceType == HTResourceType.hetuScript ||
          sourceType == HTResourceType.hetuLiteralCode ||
          sourceType == HTResourceType.hetuValue;
      if (sourceType == HTResourceType.hetuLiteralCode) {
        _currentNamespace = globalNamespace;
      }
      while (_currentBytecodeModule.ip < _currentBytecodeModule.bytes.length) {
        final result = execute(retractStackFrame: false);
        if (result is HTNamespace && result != globalNamespace) {
          _currentBytecodeModule.namespaces[result.id!] = result;
        } else if (result is HTValueSource) {
          _currentBytecodeModule.values[result.id] = result.value;
        } else {
          assert(result == globalNamespace);
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
      cachedModules[_currentBytecodeModule.id] = _currentBytecodeModule;
      dynamic result;
      if (invokeFunc != null) {
        result = invoke(invokeFunc,
            moduleName: _currentBytecodeModule.id,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs);
      } else if (_isModuleEntryScript) {
        result = _stackFrames.last.first;
      }
      final tok = DateTime.now().millisecondsSinceEpoch;
      if (printPerformanceStatistics) {
        var message =
            'hetu: ${tok - tik}ms\tto load module\t${_currentBytecodeModule.id}';
        if (_currentBytecodeModule.version != null) {
          message += '@${_currentBytecodeModule.version}';
        }
        message +=
            ' (compiled at ${_currentBytecodeModule.compiledAt} UTC with hetu@$compilerVersion)';
        print(message);
      }
      stackTraceList.clear();
      return result;
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  /// Get the current context of the interpreter,
  /// parameter determines wether to store certain items.
  /// For example, if you set ip to false,
  /// the context you get from this method will leave ip as null.
  HTContext getContext({
    bool filename = true,
    bool moduleName = true,
    bool namespace = true,
    bool ip = true,
    bool line = true,
    bool column = true,
  }) {
    return HTContext(
      filename: filename ? currentFileName : null,
      moduleName: moduleName ? currentBytecodeModule.id : null,
      namespace: namespace ? currentNamespace : null,
      ip: ip ? currentBytecodeModule.ip : null,
      line: line ? currentLine : null,
      column: column ? currentColumn : null,
    );
  }

  /// Change the current context of the bytecode interpreter to a new one.
  void setContext(
      {StackFrameStrategy stackFrameStrategy = StackFrameStrategy.none,
      HTContext? context}) {
    if (context != null) {
      var libChanged = false;
      if (context.filename != null) {
        _currentFileName = context.filename!;
      }
      if (context.moduleName != null &&
          (_currentBytecodeModule.id != context.moduleName)) {
        assert(cachedModules.containsKey(context.moduleName));
        _currentBytecodeModule = cachedModules[context.moduleName]!;
        libChanged = true;
      }
      if (context.namespace != null) {
        _currentNamespace = context.namespace!;
      } else if (libChanged) {
        _currentNamespace = _currentBytecodeModule.namespaces.values.last;
      }
      if (context.ip != null) {
        _currentBytecodeModule.ip = context.ip!;
      } else if (libChanged) {
        _currentBytecodeModule.ip = 0;
      }
      if (context.line != null) {
        _currentLine = context.line!;
      } else if (libChanged) {
        _currentLine = 0;
      }
      if (context.column != null) {
        _column = context.column!;
      } else if (libChanged) {
        _column = 0;
      }
    }
    if (stackFrameStrategy == StackFrameStrategy.retract) {
      if (_currentStackIndex > 0) {
        --_currentStackIndex;
        _stackFrames.removeLast();
      } else {
        _stackFrames.first.fillRange(0, _stackFrames.first.length, null);
      }
    } else if (stackFrameStrategy == StackFrameStrategy.create) {
      ++_currentStackIndex;
      if (_stackFrames.length <= _currentStackIndex) {
        _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
      }
    }
  }

  /// Interpret a loaded module with the key of [moduleName]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current expression value
  /// when encountered [HTOpCode.endOfExec] or [HTOpCode.endOfFunc].
  ///
  /// Changing library will create new stack frame for new register values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute({
    bool retractStackFrame = true,
    HTContext? context,
    dynamic localValue,
  }) {
    final savedContext = getContext(
      filename: context?.filename != null,
      moduleName: context?.moduleName != null,
      namespace: context?.namespace != null,
      ip: context?.ip != null,
      line: context?.line != null,
      column: context?.column != null,
    );
    setContext(stackFrameStrategy: StackFrameStrategy.create, context: context);
    _localValue = localValue;
    final result = _execute();
    setContext(
        stackFrameStrategy: retractStackFrame
            ? StackFrameStrategy.retract
            : StackFrameStrategy.none,
        context: context != null ? savedContext : null);
    return result;
  }

  void _clearLocals() {
    _localValue = null;
    _localSymbol = null;
    _localTypeArgs = [];
  }

  dynamic _execute() {
    do {
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
            _currentFileName = _currentBytecodeModule.getConstString();
            final resourceTypeIndex = _currentBytecodeModule.read();
            _currentFileResourceType =
                HTResourceType.values.elementAt(resourceTypeIndex);
            if (_currentFileResourceType != HTResourceType.hetuLiteralCode) {
              _currentNamespace = HTNamespace(
                  lexicon: _lexicon,
                  id: _currentFileName,
                  closure: globalNamespace);
            } else {
              _currentNamespace = globalNamespace;
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
            break;
          case HTOpCode.continueLoop:
            _currentBytecodeModule.ip = _loops.last.continueIp;
            break;
          case HTOpCode.assertion:
            assert(_localValue is bool);
            final text = _currentBytecodeModule.getConstString();
            if (!_localValue) {
              throw HTError.assertionFailed(text);
            }
            break;
          case HTOpCode.throws:
            throw HTError.scriptThrows(_lexicon.stringify(_localValue));
          // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
          case HTOpCode.codeBlock:
            final id = _currentBytecodeModule.getConstString();
            _currentNamespace = HTNamespace(
                lexicon: _lexicon, id: id, closure: _currentNamespace);
            break;
          case HTOpCode.endOfCodeBlock:
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
                  _currentBytecodeModule.readUtf8String());
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
          case HTOpCode.classDeclEnd:
            assert(_currentNamespace is HTClassNamespace);
            final klass = (_currentNamespace as HTClassNamespace).klass;
            _currentNamespace = _currentNamespace.closure!;
            // Add default constructor if there's none.
            if (!klass.isAbstract &&
                !klass.hasUserDefinedConstructor &&
                !klass.isExternal) {
              final ctorType =
                  HTFunctionType(returnType: HTTypeAny(_lexicon.typeAny));
              final ctor = HTFunction(
                  _currentFileName, _currentBytecodeModule.id, this,
                  internalName: InternalIdentifier.defaultConstructor,
                  classId: klass.id,
                  closure: klass.namespace,
                  category: FunctionCategory.constructor,
                  declType: ctorType);
              klass.namespace
                  .define(InternalIdentifier.defaultConstructor, ctor);
            }
            _localValue = klass;
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
            final hasDoc = _currentBytecodeModule.readBool();
            String? documentation;
            if (hasDoc) {
              documentation = _currentBytecodeModule.readUtf8String();
            }
            final id = _currentBytecodeModule.getConstString();
            String? classId;
            final hasClassId = _currentBytecodeModule.readBool();
            if (hasClassId) {
              classId = _currentBytecodeModule.getConstString();
            }
            final isTopLevel = _currentBytecodeModule.readBool();
            _currentNamespace = HTNamespace(
              lexicon: _lexicon,
              id: id,
              classId: classId,
              closure: _currentNamespace,
              documentation: documentation,
              isTopLevel: isTopLevel,
            );
            break;
          case HTOpCode.namespaceDeclEnd:
            final nsp = _currentNamespace;
            _localValue = nsp;
            assert(nsp.closure != null);
            _currentNamespace = nsp.closure!;
            assert(nsp.id != null);
            _currentNamespace.define(nsp.id!, nsp);
            break;
          case HTOpCode.delete:
            final deletingType = _currentBytecodeModule.read();
            if (deletingType == DeletingTypeCode.member) {
              final object = execute();
              if (object is HTStruct) {
                final symbol = _currentBytecodeModule.getConstString();
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
              final symbol = _currentBytecodeModule.getConstString();
              _currentNamespace.delete(symbol);
            }
            break;
          case HTOpCode.ifStmt:
            final thenBranchLength = _currentBytecodeModule.readUint16();
            final truthValue = _truthy(_localValue);
            if (!truthValue) {
              _currentBytecodeModule.skip(thenBranchLength);
              _clearLocals();
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
            assert(localSymbol != null);
            final id = localSymbol!;
            final result = _currentNamespace.memberSet(id, value,
                isRecursive: true, throws: false);
            if (!result) {
              if (config.allowImplicitVariableDeclaration) {
                final decl = HTVariable(
                    id: id,
                    interpreter: this,
                    fileName: _currentFileName,
                    moduleName: _currentBytecodeModule.id,
                    closure: _currentNamespace,
                    value: value,
                    isPrivate: id.startsWith(_lexicon.privatePrefix),
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
          case HTOpCode.awaitedValue:
            // handle the possible future execution request raised by await keyword and Future value.
            // final object = _localValue;
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
                    if (key.toInt() != key) {
                      throw HTError.subGetKey(key,
                          filename: _currentFileName,
                          line: _currentLine,
                          column: _column);
                    }
                  } else if (key < 0 || key >= object.length) {
                    throw HTError.outOfRange(key, object.length,
                        filename: _currentFileName,
                        line: _currentLine,
                        column: _column);
                  }
                }
                _localValue = object[key.toInt()];
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
                    if (key.toInt() != key) {
                      throw HTError.subGetKey(key,
                          filename: _currentFileName,
                          line: _currentLine,
                          column: _column);
                    }
                  } else if (key < 0 || key >= object.length) {
                    throw HTError.outOfRange(key, object.length,
                        filename: _currentFileName,
                        line: _currentLine,
                        column: _column);
                  }
                  object[key.toInt()] = value;
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
                filename: _currentFileName,
                line: _currentLine,
                column: _column);
        }
        instruction = _currentBytecodeModule.read();
      }
    } while (true);
  }

  void _handleImportExport() {
    final isExported = _currentBytecodeModule.readBool();
    final isPreloadedModule = _currentBytecodeModule.readBool();
    final showList = <String>{};
    final showListLength = _currentBytecodeModule.read();
    for (var i = 0; i < showListLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      showList.add(id);
      if (isExported) {
        _currentNamespace.declareExport(id);
      }
    }
    final hasFromPath = _currentBytecodeModule.readBool();
    String? fromPath;
    if (hasFromPath) {
      fromPath = _currentBytecodeModule.getConstString();
    }
    String? alias;
    final hasAlias = _currentBytecodeModule.readBool();
    if (hasAlias) {
      alias = _currentBytecodeModule.getConstString();
    }
    if (isPreloadedModule) {
      assert(fromPath != null);
      final importedModule = cachedModules[fromPath]!;
      final importedNamespace = importedModule.namespaces.values.last;
      if (showList.isEmpty) {
        _currentNamespace.defineImport(alias!, importedNamespace);
      } else {
        final aliasNamespace = HTNamespace(
            lexicon: _lexicon, id: alias!, closure: _currentNamespace.closure);
        for (final id in showList) {
          final decl = importedNamespace.symbols[id]!;
          assert(!decl.isPrivate);
          aliasNamespace.define(id, decl);
        }
        _currentNamespace.defineImport(alias, aliasNamespace);
      }
    } else {
      if (fromPath != null) {
        final ext = path.extension(fromPath);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          // TODO: import binary bytes
          final value = _currentBytecodeModule.values[fromPath];
          assert(value != null);
          _currentNamespace.defineImport(
              alias!, HTVariable(id: alias, value: value));
          if (isExported) {
            _currentNamespace.declareExport(alias);
          }
        } else {
          final decl = UnresolvedImportStatement(fromPath,
              alias: alias, showList: showList, isExported: isExported);
          if (_currentFileResourceType == HTResourceType.hetuModule) {
            _currentNamespace.declareImport(decl);
          } else {
            _handleNamespaceImport(_currentNamespace, decl);
          }
        }
      } else {
        // If it's an export statement regarding this namespace self,
        // It will be handled immediately since it does not needed resolve.
        assert(isExported);
        if (showList.isNotEmpty) {
          _currentNamespace.willExportAll = false;
          _currentNamespace.exports.addAll(showList);
        }
        // If the namespace will export all,
        // a declared id will be add to the list
        // when the declaration statement is handled.
      }
    }
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
      case HTValueTypeCode.string:
        _localValue = _currentBytecodeModule.readUtf8String();
        break;
      case HTValueTypeCode.stringInterpolation:
        var literal = _currentBytecodeModule.readUtf8String();
        final interpolationLength = _currentBytecodeModule.read();
        for (var i = 0; i < interpolationLength; ++i) {
          final value = execute();
          literal = literal.replaceAll(
              '${_lexicon.stringInterpolationStart}$i${_lexicon.stringInterpolationEnd}',
              _lexicon.stringify(value));
        }
        _localValue = literal;
        break;
      case HTValueTypeCode.identifier:
        final symbol = _localSymbol = _currentBytecodeModule.getConstString();
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
          id = _currentBytecodeModule.getConstString();
        }
        HTStruct? prototype;
        final hasPrototypeId = _currentBytecodeModule.readBool();
        if (hasPrototypeId) {
          final prototypeId = _currentBytecodeModule.getConstString();
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
          final isSpread = _currentBytecodeModule.readBool();
          if (isSpread) {
            final HTStruct spreadingStruct = execute();
            for (final key in spreadingStruct.keys) {
              // skip internal apis
              if (key.startsWith(_lexicon.internalPrefix)) continue;
              final copiedValue = toStructValue(spreadingStruct[key]);
              struct.define(key, copiedValue);
            }
          } else {
            final key = _currentBytecodeModule.getConstString();
            final value = execute();
            struct.memberSet(key, value, recursive: false);
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
        final internalName = _currentBytecodeModule.getConstString();
        final hasExternalTypedef = _currentBytecodeModule.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _currentBytecodeModule.getConstString();
        }
        final isAsync = _currentBytecodeModule.readBool();
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
                    declType: param.declType ?? HTTypeAny(_lexicon.typeAny),
                    isOptional: param.isOptional,
                    isVariadic: param.isVariadic,
                    id: param.isNamed ? param.id : null))
                .toList(),
            returnType: returnType ?? HTTypeAny(_lexicon.typeAny));
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
            internalName: internalName,
            _currentFileName,
            _currentBytecodeModule.id,
            this,
            closure: _currentNamespace,
            category: FunctionCategory.literal,
            externalTypeId: externalTypedef,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
            declType: declType,
            isAsync: isAsync,
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
      case HTValueTypeCode.intrinsicType:
        _localValue = _handleIntrinsicType();
        break;
      case HTValueTypeCode.nominalType:
        _localValue = _handleNominalType();
        break;
      case HTValueTypeCode.functionType:
        _localValue = _handleFunctionType();
        break;
      case HTValueTypeCode.structuralType:
        _localValue = _handleStructuralType();
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

  void _handleTypeCheck({bool isNot = false}) {
    final object = _getRegVal(HTRegIdx.relationLeft);
    final type = (_localValue as HTType).resolve(_currentNamespace);
    HTType valueType;
    if (object != null) {
      final encapsulated = encapsulate(object);
      valueType = encapsulated.valueType!;
    } else {
      valueType = HTTypeNull(_lexicon.kNull);
    }
    final result = valueType.isA(type);
    _localValue = isNot ? !result : result;
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
        var left = _getRegVal(HTRegIdx.equalLeft);
        _localValue = left == _localValue;
        break;
      case HTOpCode.notEqual:
        var left = _getRegVal(HTRegIdx.equalLeft);
        _localValue = left != _localValue;
        break;
      case HTOpCode.lesser:
        var left = _getRegVal(HTRegIdx.relationLeft);
        var right = _localValue;
        if (_isZero(left)) {
          left = 0;
        }
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left < right;
        break;
      case HTOpCode.greater:
        var left = _getRegVal(HTRegIdx.relationLeft);
        var right = _localValue;
        if (_isZero(left)) {
          left = 0;
        }
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left > right;
        break;
      case HTOpCode.lesserOrEqual:
        var left = _getRegVal(HTRegIdx.relationLeft);
        var right = _localValue;
        if (_isZero(left)) {
          left = 0;
        }
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left <= right;
        break;
      case HTOpCode.greaterOrEqual:
        var left = _getRegVal(HTRegIdx.relationLeft);
        var right = _localValue;
        if (_isZero(left)) {
          left = 0;
        }
        if (_isZero(right)) {
          right = 0;
        }
        _localValue = left >= right;
        break;
      case HTOpCode.typeAs:
        final object = _getRegVal(HTRegIdx.relationLeft);
        final type =
            (_localValue as HTType).resolve(_currentNamespace) as HTNominalType;
        final klass = type.klass as HTClass;
        _localValue = HTCast(object, klass, this);
        break;
      case HTOpCode.typeIs:
        _handleTypeCheck();
        break;
      case HTOpCode.typeIsNot:
        _handleTypeCheck(isNot: true);
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

  FutureExecution? _handleUnaryPrefixOp(int op) {
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
        if (encap == HTEntity.nullValue) {
          _localValue = HTTypeNull(_lexicon.kNull);
        } else {
          final type = encap.valueType;
          if (type != null) {
            _localValue = type;
          } else {
            _localValue = HTTypeUnknown(_lexicon.typeUnknown);
          }
        }
        break;
    }
    return null;
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
      final name = _currentBytecodeModule.getConstString();
      final arg = execute();
      // final arg = execute(moveRegIndex: true);
      namedArgs[name] = arg;
    }
    final typeArgs = _localTypeArgs;

    _localValue = _call(
      callee,
      isConstructorCall: hasNewOperator,
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
      typeArgs: typeArgs,
    );
  }

  HTIntrinsicType _handleIntrinsicType() {
    final typeName = _currentBytecodeModule.getConstString();
    final isTop = _currentBytecodeModule.readBool();
    final isBottom = _currentBytecodeModule.readBool();
    if (typeName == _lexicon.typeAny) {
      return HTTypeAny(typeName);
    }
    if (typeName == _lexicon.typeUnknown) {
      return HTTypeUnknown(typeName);
    }
    if (typeName == _lexicon.typeVoid) {
      return HTTypeVoid(typeName);
    }
    if (typeName == _lexicon.typeNever) {
      return HTTypeNever(typeName);
    }
    if (typeName == _lexicon.typeFunction) {
      return HTTypeFunction(typeName);
    }
    if (typeName == _lexicon.typeNamespace) {
      return HTTypeNamespace(typeName);
    }
    // fallsafe measure, however this should not happen
    return HTIntrinsicType(typeName, isTop: isTop, isBottom: isBottom);
  }

  HTUnresolvedType _handleNominalType() {
    final typeName = _currentBytecodeModule.getConstString();
    final typeArgsLength = _currentBytecodeModule.read();
    final typeArgs = <HTUnresolvedType>[];
    for (var i = 0; i < typeArgsLength; ++i) {
      final typearg = _handleTypeExpr() as HTUnresolvedType;
      typeArgs.add(typearg);
    }
    final isNullable = (_currentBytecodeModule.read() == 0) ? false : true;
    return HTUnresolvedType(typeName,
        typeArgs: typeArgs, isNullable: isNullable);
  }

  HTFunctionType _handleFunctionType() {
    final paramsLength = _currentBytecodeModule.read();
    final parameterTypes = <HTParameterType>[];
    for (var i = 0; i < paramsLength; ++i) {
      final declType = _handleTypeExpr();
      final isOptional = _currentBytecodeModule.read() == 0 ? false : true;
      final isVariadic = _currentBytecodeModule.read() == 0 ? false : true;
      final isNamed = _currentBytecodeModule.read() == 0 ? false : true;
      String? paramId;
      if (isNamed) {
        paramId = _currentBytecodeModule.getConstString();
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
  }

  HTStructuralType _handleStructuralType() {
    final fieldsLength = _currentBytecodeModule.readUint16();
    final fieldTypes = <String, HTType>{};
    for (var i = 0; i < fieldsLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      final typeExpr = _handleTypeExpr();
      fieldTypes[id] = typeExpr;
    }
    return HTStructuralType(currentNamespace, fieldTypes: fieldTypes);
  }

  HTType _handleTypeExpr() {
    final typeType = _currentBytecodeModule.read();
    switch (typeType) {
      case HTValueTypeCode.intrinsicType:
        return _handleIntrinsicType();
      case HTValueTypeCode.nominalType:
        return _handleNominalType();
      case HTValueTypeCode.functionType:
        return _handleFunctionType();
      case HTValueTypeCode.structuralType:
        return _handleStructuralType();
      default:
        // This should never happens.
        throw HTError.unknownOpCode(typeType,
            filename: _currentFileName, line: _currentLine, column: _column);
    }
  }

  void _handleTypeAliasDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.getConstString();
    }
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && _currentNamespace.willExportAll) {
      _currentNamespace.declareExport(id);
    }
    final value = _handleTypeExpr();
    final decl = HTVariable(
      id: id,
      classId: classId,
      closure: _currentNamespace,
      documentation: documentation,
      value: value,
    );
    _currentNamespace.define(id, decl);
    _localValue = value;
  }

  void _handleConstDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.getConstString();
    }
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && _currentNamespace.willExportAll) {
      _currentNamespace.declareExport(id);
    }
    final typeIndex = _currentBytecodeModule.read();
    final type = HTConstantType.values.elementAt(typeIndex);
    final index = _currentBytecodeModule.readInt16();
    final decl = HTConstantValue(
        id: id,
        type: getConstantType(type),
        index: index,
        classId: classId,
        documentation: documentation,
        globalConstantTable: _currentBytecodeModule);
    _currentNamespace.define(id, decl, override: config.allowVariableShadowing);
    // _localValue = _currentBytecodeModule.getGlobalConstant(type, index);
  }

  void _handleVarDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.getConstString();
    }
    final isField = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isStatic = _currentBytecodeModule.readBool();
    final isMutable = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && _currentNamespace.willExportAll) {
      _currentNamespace.declareExport(id);
    }
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
        decl = HTVariable(
            id: id,
            interpreter: this,
            fileName: _currentFileName,
            moduleName: _currentBytecodeModule.id,
            classId: classId,
            closure: _currentNamespace,
            documentation: documentation,
            declType: declType,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn);
      } else {
        initValue = execute();
        decl = HTVariable(
            id: id,
            interpreter: this,
            fileName: _currentFileName,
            moduleName: _currentBytecodeModule.id,
            classId: classId,
            closure: _currentNamespace,
            documentation: documentation,
            declType: declType,
            value: initValue,
            isExternal: isExternal,
            isStatic: isStatic,
            isMutable: isMutable);
      }
    } else {
      decl = HTVariable(
          id: id,
          interpreter: this,
          fileName: _currentFileName,
          moduleName: _currentBytecodeModule.id,
          classId: classId,
          closure: _currentNamespace,
          documentation: documentation,
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
    final isTopLevel = _currentBytecodeModule.readBool();
    final idCount = _currentBytecodeModule.read();
    final ids = <String, HTType?>{};
    final omittedPrefix = '##';
    var omittedIndex = 0;
    for (var i = 0; i < idCount; ++i) {
      var id = _currentBytecodeModule.getConstString();
      // omit '_' symbols
      if (id == _lexicon.omittedMark) {
        id = omittedPrefix + (omittedIndex++).toString();
      } else {
        if (isTopLevel && _currentNamespace.willExportAll) {
          _currentNamespace.declareExport(id);
        }
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
      final decl = HTVariable(
          id: id,
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
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};
    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      final isOptional = _currentBytecodeModule.readBool();
      final isVariadic = _currentBytecodeModule.readBool();
      final isNamed = _currentBytecodeModule.readBool();
      final isInitialization = _currentBytecodeModule.readBool();
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
      paramDecls[id] = HTParameter(
        id: id,
        interpreter: this,
        fileName: _currentFileName,
        moduleName: _currentBytecodeModule.id,
        closure: _currentNamespace,
        declType: declType,
        definitionIp: definitionIp,
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isVariadic: isVariadic,
        isOptional: isOptional,
        isNamed: isNamed,
        isInitialization: isInitialization,
      );
    }
    return paramDecls;
  }

  void _handleFuncDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final internalName = _currentBytecodeModule.getConstString();
    String? id;
    final hasId = _currentBytecodeModule.readBool();
    if (hasId) {
      id = _currentBytecodeModule.getConstString();
    }
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.getConstString();
    }
    String? externalTypeId;
    final hasExternalTypedef = _currentBytecodeModule.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _currentBytecodeModule.getConstString();
    }
    final category = FunctionCategory.values[_currentBytecodeModule.read()];
    final isAsync = _currentBytecodeModule.readBool();
    final isField = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isStatic = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && _currentNamespace.willExportAll) {
      if (id != null) {
        _currentNamespace.declareExport(id);
      }
    }
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
                declType: param.declType ?? HTTypeAny(_lexicon.typeAny),
                isOptional: param.isOptional,
                isVariadic: param.isVariadic,
                id: param.isNamed ? param.id : null))
            .toList(),
        returnType: returnType ?? HTTypeAny(_lexicon.typeAny));
    RedirectingConstructor? redirCtor;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    if (category == FunctionCategory.constructor) {
      final hasRedirectingCtor = _currentBytecodeModule.readBool();
      if (hasRedirectingCtor) {
        final calleeId = _currentBytecodeModule.getConstString();
        final hasCtorName = _currentBytecodeModule.readBool();
        String? ctorName;
        if (hasCtorName) {
          ctorName = _currentBytecodeModule.getConstString();
        }
        final positionalArgIpsLength = _currentBytecodeModule.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _currentBytecodeModule.readUint16();
          positionalArgIps.add(_currentBytecodeModule.ip);
          _currentBytecodeModule.skip(argLength);
        }
        final namedArgsLength = _currentBytecodeModule.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _currentBytecodeModule.getConstString();
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
    final func = HTFunction(_currentFileName, _currentBytecodeModule.id, this,
        internalName: internalName,
        id: id,
        classId: classId,
        closure: _currentNamespace,
        documentation: documentation,
        isAsync: isAsync,
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
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isExternal = _currentBytecodeModule.readBool();
    final isAbstract = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && _currentNamespace.willExportAll) {
      _currentNamespace.declareExport(id);
    }
    final hasUserDefinedConstructor = _currentBytecodeModule.readBool();
    HTType? superType;
    final hasSuperClass = _currentBytecodeModule.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != _lexicon.globalObjectId)) {
        final HTClass object = rootClass ??
            globalNamespace.memberGet(_lexicon.globalObjectId,
                isRecursive: true);
        superType = HTNominalType(object);
      }
    }
    final isEnum = _currentBytecodeModule.readBool();
    final klass = HTClass(
      this,
      id: id,
      closure: _currentNamespace,
      documentation: documentation,
      superType: superType,
      isExternal: isExternal,
      isAbstract: isAbstract,
      isEnum: isEnum,
      hasUserDefinedConstructor: hasUserDefinedConstructor,
    );
    _currentNamespace.define(id, klass);
    _currentNamespace = klass.namespace;
  }

  void _handleExternalEnumDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && _currentNamespace.willExportAll) {
      _currentNamespace.declareExport(id);
    }
    final enumClass =
        HTExternalEnum(this, id: id, documentation: documentation);
    _currentNamespace.define(id, enumClass);
    _localValue = enumClass;
  }

  void _handleStructDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && _currentNamespace.willExportAll) {
      _currentNamespace.declareExport(id);
    }
    String? prototypeId;
    final hasPrototypeId = _currentBytecodeModule.readBool();
    if (hasPrototypeId) {
      prototypeId = _currentBytecodeModule.getConstString();
    } else if (id != _lexicon.globalPrototypeId) {
      prototypeId = _lexicon.globalPrototypeId;
    }
    final mixinIdsLength = _currentBytecodeModule.read();
    List<String> mixinIds = [];
    for (var i = 0; i < mixinIdsLength; ++i) {
      mixinIds.add(_currentBytecodeModule.getConstString());
    }
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
      documentation: documentation,
      prototypeId: prototypeId,
      mixinIds: mixinIds,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: definitionIp,
    );
    _currentNamespace.define(id, struct);
    _localValue = struct;
  }
}
