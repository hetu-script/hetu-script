import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:hetu_script/declaration/declaration.dart';
import 'package:hetu_script/declaration/variable/variable_declaration.dart';
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
import '../type/function.dart';
import '../type/nominal.dart';
import '../type/structural.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../bytecode/shared.dart';
import '../bytecode/bytecode_module.dart';
import '../bytecode/compiler.dart';
import '../version.dart';
import '../value/unresolved_import.dart';
import '../locale/locale.dart';
import '../common/internal_identifier.dart';
import '../common/function_category.dart';

/// Mixin for classes that want to hold a ref of a bytecode interpreter
mixin InterpreterRef {
  late final HTInterpreter interpreter;
}

/// Collection of config of bytecode interpreter.
class InterpreterConfig implements ErrorHandlerConfig {
  @override
  bool showDartStackTrace;

  @override
  bool showHetuStackTrace;

  @override
  int stackTraceDisplayCountLimit;

  @override
  bool processError;

  bool allowVariableShadowing;

  bool allowImplicitVariableDeclaration;

  bool allowImplicitNullToZeroConversion;

  bool allowImplicitEmptyValueToFalseConversion;

  bool printPerformanceStatistics;

  bool checkTypeAnnotationAtRuntime;

  bool resolveExternalFunctionsDynamically;

  InterpreterConfig({
    this.showDartStackTrace = false,
    this.showHetuStackTrace = false,
    this.stackTraceDisplayCountLimit = 5,
    this.processError = true,
    this.allowVariableShadowing = true,
    this.allowImplicitVariableDeclaration = false,
    this.allowImplicitNullToZeroConversion = false,
    this.allowImplicitEmptyValueToFalseConversion = false,
    this.printPerformanceStatistics = false,
    this.checkTypeAnnotationAtRuntime = false,
    this.resolveExternalFunctionsDynamically = false,
  });
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
  final String? file;
  final String? module;
  final HTNamespace? namespace;
  final int? ip;
  final int? line;
  final int? column;

  HTContext({
    this.file,
    this.module,
    this.namespace,
    this.ip,
    this.line,
    this.column,
  });
}

/// A wrapper class for the bytecode interpreter
/// to run a certain task in a future.
/// This is only used internally.
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

  int tik = 0;

  List<dynamic> positionalArgs = const [];
  Map<String, dynamic> namedArgs = const {};
  List<HTType> typeArgs = const [];

  bool _scriptMode = false, _globallyImport = false;

  String? _invoke;

  late Version compilerVersion;

  final stackTraceList = <String>[];

  final cachedModules = <String, HTBytecodeModule>{};

  InterpreterConfig config;

  late final HTLexicon _lexicon;
  HTLexicon get lexicon => _lexicon;

  HTResourceContext<HTSource> sourceContext;

  ErrorHandlerConfig get errorConfig => config;

  late final HTNamespace globalNamespace;

  late HTNamespace currentNamespace;

  String _currentFile = '';
  String get currentFile => _currentFile;

  late HTResourceType _currentFileResourceType;

  late HTBytecodeModule _currentBytecodeModule;
  HTBytecodeModule get currentBytecodeModule => _currentBytecodeModule;

  var _currentLine = 0;
  int get currentLine => _currentLine;

  var _currentColumn = 0;
  int get currentColumn => _currentColumn;

  /// Register values are stored by groups.
  /// Every group have 16 values, they are HTRegIdx.
  /// A such group can be understanded as the stack frame of a runtime function.
  final _stackFrames = [List<dynamic>.filled(HTRegIdx.length, null)];
  List<dynamic> getCurrentStackFrame() => _stackFrames.last;

  void _setRegVal(int index, dynamic value) => _stackFrames.last[index] = value;
  dynamic _getRegVal(int index) => _stackFrames.last[index];
  set _localValue(dynamic value) => _stackFrames.last[HTRegIdx.value] = value;
  dynamic get _localValue => _stackFrames.last[HTRegIdx.value];
  set _localSymbol(String? value) =>
      _stackFrames.last[HTRegIdx.identifier] = value;
  String? get localSymbol => _stackFrames.last[HTRegIdx.identifier];
  set _localTypeArgs(List<HTType> value) =>
      _stackFrames.last[HTRegIdx.typeArgs] = value;
  List<HTType> get _localTypeArgs =>
      _stackFrames.last[HTRegIdx.typeArgs] ?? const [];
  set _loopCount(int value) => _stackFrames.last[HTRegIdx.loopCount] = value;
  int get _loopCount => _stackFrames.last[HTRegIdx.loopCount] ?? 0;
  set _anchorCount(int value) =>
      _stackFrames.last[HTRegIdx.anchorCount] = value;
  int get _anchorCount => _stackFrames.last[HTRegIdx.anchorCount] ?? 0;

  /// Loop point is stored as stack form.
  /// Break statement will jump to the last loop point,
  /// and remove it from this stack.
  /// Return statement will clear loop points by
  /// [_loopCount] in current stack frame.
  final _loops = <_LoopInfo>[];

  final _anchors = <int>[];

  /// A bytecode interpreter.
  HTInterpreter(
      {InterpreterConfig? config,
      required this.sourceContext,
      HTLexicon? lexicon})
      : config = config ?? InterpreterConfig(),
        _lexicon = lexicon ?? HTLexiconHetu() {
    globalNamespace =
        HTNamespace(lexicon: _lexicon, id: InternalIdentifier.global);
    currentNamespace = globalNamespace;
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
        filename: error.filename ?? currentFile,
        line: error.line ?? currentLine,
        column: error.column ?? currentColumn,
      );
      throw wrappedError;
    } else {
      final hetuError = HTError.extern(
        _lexicon.stringify(error),
        extra: stackTraceString,
        filename: currentFile,
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
        final resolvedType = callee.resolve(currentNamespace) as HTNominalType;
        // if (resolvedType is! HTNominalType) {
        //   throw HTError.notCallable(callee.toString(),
        //       filename: _fileName, line: _line, column: _column);
        // }
        klass = resolvedType.klass as HTClass;
      } else {
        klass = callee;
      }
      if (klass.isAbstract) {
        throw HTError.abstracted(klass.id!,
            filename: _currentFile, line: _currentLine, column: _currentColumn);
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
            filename: _currentFile, line: _currentLine, column: _currentColumn);
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
            filename: _currentFile, line: _currentLine, column: _currentColumn);
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
          return callee(currentNamespace,
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
            filename: _currentFile,
            line: _currentLine,
            column: _currentColumn);
      }
    }
  }

  /// Get a namespace in certain module with a certain name.
  HTNamespace getNamespace({String? module}) {
    HTNamespace nsp = globalNamespace;
    if (module != null) {
      final bytecodeModule = cachedModules[module]!;
      assert(bytecodeModule.namespaces.isNotEmpty);
      nsp = bytecodeModule.namespaces.values.last;
    }
    return nsp;
  }

  /// Add a declaration to certain namespace.
  /// if the value is not a declaration, will create one with [isMutable] value.
  /// if not, the [isMutable] will be ignored.
  bool define(
    String id,
    dynamic value, {
    bool isMutable = false,
    bool override = false,
    bool throws = true,
    String? module,
  }) {
    final nsp = getNamespace(module: module);
    if (value is HTDeclaration) {
      return nsp.define(id, value, override: override, throws: throws);
    } else {
      final decl = HTVariable(
        id: id,
        interpreter: this,
        value: value,
        isMutable: isMutable,
        closure: nsp,
        isPrivate: _lexicon.isPrivate(id),
      );
      return nsp.define(id, decl, override: override, throws: throws);
    }
  }

  /// Get the documentation of a declaration in a certain namespace.
  String? help(dynamic id, {String? module}) {
    try {
      if (id is HTDeclaration) {
        return id.documentation;
      } else if (id is String) {
        HTNamespace nsp = getNamespace(module: module);
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
  dynamic fetch(String id, {String? module}) {
    try {
      HTNamespace nsp = getNamespace(module: module);
      final result = nsp.memberGet(id, isRecursive: false);
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
  void assign(String id, dynamic value, {String? module}) {
    try {
      final savedModuleName = _currentBytecodeModule.id;
      HTNamespace nsp = getNamespace(module: module);
      nsp.memberSet(id, value, isRecursive: false);
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
  dynamic invoke(
    String func, {
    String? namespace,
    String? module,
    bool isConstructor = false,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const [],
  }) {
    try {
      stackTraceList.clear();
      final savedModuleName = _currentBytecodeModule.id;
      HTNamespace nsp;
      if (module != null) {
        nsp = globalNamespace;
        if (_currentBytecodeModule.id != module) {
          _currentBytecodeModule = cachedModules[module]!;
        }
        assert(_currentBytecodeModule.namespaces.isNotEmpty);
        nsp = _currentBytecodeModule.namespaces.values.last;
      } else {
        nsp = currentNamespace;
      }

      dynamic callee;
      if (namespace != null) {
        HTEntity fromNsp = nsp.memberGet(namespace, isRecursive: true);
        callee = fromNsp.memberGet(func);
      } else {
        callee = nsp.memberGet(func, isRecursive: true);
      }
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

  /// Bind an external class name to a abstract class name
  /// for interpreter getting dart class name by reflection
  void bindExternalReflection(HTExternalTypeReflection reflection) {
    externTypeReflection.add(reflection);
  }

  /// Register an external function into script
  /// include external function within non-external class & struct & namespace
  /// there must be a declaraction also in script for using this
  void bindExternalFunction(String id, Function function,
      {bool override = true}) {
    if (externFunctions.containsKey(id) && !override) {
      throw HTError.defined(id, ErrorType.runtimeError);
    }
    externFunctions[id] = function;
  }

  /// Fetch an external function
  Function fetchExternalFunction(String id) {
    if (!externFunctions.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externFunctions[id]!;
  }

  /// Register a external function typedef into scrfipt
  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function,
      {bool override = true}) {
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

  void switchModule(String module) {
    assert(cachedModules.containsKey(module));
    setContext(context: HTContext(module: module));
  }

  HTBytecodeModule? getBytecode(String module) {
    assert(cachedModules.containsKey(module));
    return cachedModules[module];
  }

  String stringify(dynamic object) {
    return _lexicon.stringify(object);
  }

  /// Get a object's type at runtime.
  HTType typeof(dynamic object) {
    final encap = encapsulate(object);
    HTType type;
    if (encap == HTEntity.nullValue) {
      type = HTTypeNull(_lexicon.kNull);
    } else if (encap is HTType) {
      type = HTTypeType(_lexicon.kType);
    } else {
      type = encap.valueType ?? HTTypeUnknown(_lexicon.kUnknown);
    }
    return type;
  }

  HTType decltypeof(String id) {
    final HTDeclaration decl =
        currentNamespace.memberGet(id, isRecursive: true, asDeclaration: true);
    decl.resolve();
    var decltype = decl.declType;

    if (decltype != null) {
      return decltype;
    } else if (decl is HTVariableDeclaration) {
      return HTTypeAny(lexicon.kAny);
    } else {
      return HTTypeUnknown(lexicon.kUnknown);
    }
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
      typeString = _lexicon.kBoolean;
    } else if (object is int) {
      typeString = _lexicon.kInteger;
    } else if (object is double) {
      typeString = _lexicon.kFloat;
    } else if (object is String) {
      typeString = _lexicon.kString;
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

  void _handleNamespaceImport(HTNamespace nsp, UnresolvedImport importDecl) {
    final importedNamespace =
        _currentBytecodeModule.namespaces[importDecl.fromPath]!;

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

    if (importDecl.alias == null) {
      if (importDecl.showList.isEmpty) {
        nsp.import(importedNamespace, export: importDecl.isExported);
      } else {
        for (final id in importDecl.showList) {
          HTDeclaration decl;
          if (importedNamespace.symbols.containsKey(id)) {
            decl = importedNamespace.symbols[id]!;
          } else if (importedNamespace.exports.contains(id)) {
            decl = importedNamespace.importedSymbols[id]!;
          } else {
            throw HTError.undefined(id);
          }
          nsp.defineImport(id, decl, importDecl.fromPath);
        }
      }
    } else {
      if (importDecl.showList.isEmpty) {
        nsp.defineImport(
            importDecl.alias!, importedNamespace, importDecl.fromPath);
      } else {
        final aliasNamespace = HTNamespace(
            lexicon: _lexicon, id: importDecl.alias!, closure: nsp.closure);
        for (final id in importDecl.showList) {
          if (!importedNamespace.symbols.containsKey(id)) {
            throw HTError.undefined(id);
          }
          final decl = importedNamespace.symbols[id]!;
          assert(!decl.isPrivate);
          aliasNamespace.define(id, decl);
        }
        nsp.defineImport(
            importDecl.alias!, aliasNamespace, importDecl.fromPath);
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

  /// Load a pre-compiled bytecode module.
  /// If [invoke] is true, execute the bytecode immediately.
  dynamic loadBytecode({
    required Uint8List bytes,
    required String module,
    bool globallyImport = false,
    String? invoke,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const [],
  }) {
    try {
      _globallyImport = globallyImport;
      _invoke = invoke;
      this.positionalArgs = positionalArgs;
      this.namedArgs = namedArgs;
      this.typeArgs = typeArgs;

      tik = DateTime.now().millisecondsSinceEpoch;
      if (cachedModules.containsKey(module)) {
        _currentBytecodeModule = cachedModules[module]!;
      } else {
        _currentBytecodeModule = HTBytecodeModule(id: module, bytes: bytes);
        cachedModules[_currentBytecodeModule.id] = _currentBytecodeModule;
      }
      _currentBytecodeModule.ip = 0;

      final signature = _currentBytecodeModule.readUint32();
      if (signature != HTCompiler.hetuSignature) {
        throw HTError.bytecode(
            filename: _currentFile, line: _currentLine, column: _currentColumn);
      }
      // compare the version of the compiler of the bytecode to my version.
      compilerVersion = _handleVersion();
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
          filename: _currentFile,
          line: _currentLine,
          column: _currentColumn,
        );
      }
      // read the version of the bytecode.
      final hasVersion = _currentBytecodeModule.readBool();
      if (hasVersion) {
        _currentBytecodeModule.version = _handleVersion();
      }
      _currentBytecodeModule.compiledAt =
          _currentBytecodeModule.readUtf8String();
      _currentFile = _currentBytecodeModule.readUtf8String();
      final sourceType =
          HTResourceType.values.elementAt(_currentBytecodeModule.read());
      _scriptMode = (sourceType == HTResourceType.hetuScript) ||
          (sourceType == HTResourceType.hetuLiteralCode) ||
          (sourceType == HTResourceType.json);
      // TODO: import binary file
      dynamic result = execute();
      if (result is FutureExecution) {
        result = waitFutureExucution(result);
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

  /// Get the current context of the interpreter,
  /// parameter determines wether to store certain items.
  /// For example, if you set ip to false,
  /// the context you get from this method will leave ip as null.
  HTContext getContext({
    bool file = true,
    bool module = true,
    bool namespace = true,
    bool ip = true,
    bool line = true,
    bool column = true,
  }) {
    return HTContext(
      file: file ? currentFile : null,
      module: module ? currentBytecodeModule.id : null,
      namespace: namespace ? currentNamespace : null,
      ip: ip ? currentBytecodeModule.ip : null,
      line: line ? currentLine : null,
      column: column ? currentColumn : null,
    );
  }

  void _createStackFrame() {
    _stackFrames.add(List<dynamic>.filled(HTRegIdx.length, null));
  }

  void _retractStackFrame() {
    dynamic localValue;
    if (_stackFrames.isNotEmpty) {
      localValue = _localValue;
      _stackFrames.removeLast();
    }
    if (_stackFrames.isEmpty) {
      _createStackFrame();
    }
    _localValue = localValue;
  }

  /// Change the current context of the bytecode interpreter to a new one.
  void setContext(
      {StackFrameStrategy stackFrameStrategy = StackFrameStrategy.none,
      List<dynamic>? stackFrame,
      HTContext? context}) {
    if (context != null) {
      var libChanged = false;
      if (context.file != null) {
        _currentFile = context.file!;
      }
      if (context.module != null &&
          (_currentBytecodeModule.id != context.module)) {
        assert(cachedModules.containsKey(context.module));
        _currentBytecodeModule = cachedModules[context.module]!;
        libChanged = true;
      }
      if (context.namespace != null) {
        currentNamespace = context.namespace!;
      } else if (libChanged) {
        currentNamespace = _currentBytecodeModule.namespaces.values.last;
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
        _currentColumn = context.column!;
      } else if (libChanged) {
        _currentColumn = 0;
      }
    }
    if (stackFrameStrategy == StackFrameStrategy.retract) {
      _retractStackFrame();
    } else if (stackFrameStrategy == StackFrameStrategy.create) {
      _createStackFrame();
    } else if (stackFrame != null) {
      _stackFrames.add(stackFrame);
    }
  }

  /// Interpret a loaded module with the key of [module]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current expression value
  /// when encountered [OpCode.endOfExec] or [OpCode.endOfFunc].
  ///
  /// Changing library will create new stack frame for new register values.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute({
    bool createStackFrame = true,
    bool retractStackFrame = true,
    HTContext? context,
    List<dynamic>? stackFrame,
    dynamic localValue,
    // void Function()? endOfFileHandler,
    // dynamic Function()? endOfModuleHandler,
  }) {
    final savedContext = getContext(
      file: context?.file != null,
      module: context?.module != null,
      namespace: context?.namespace != null,
      ip: context?.ip != null,
      line: context?.line != null,
      column: context?.column != null,
    );
    setContext(
      stackFrameStrategy: createStackFrame
          ? StackFrameStrategy.create
          : StackFrameStrategy.none,
      context: context,
      stackFrame: stackFrame,
    );
    if (localValue != null) _localValue = localValue;
    final result = _execute(
        // endOfFileHandler, endOfModuleHandler
        );
    setContext(
        stackFrameStrategy: (retractStackFrame || stackFrame != null)
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

  dynamic _execute(
      // void Function()? endOfFileHandler,
      // dynamic Function()? endOfModuleHandler,
      ) {
    int instruction;
    do {
      instruction = _currentBytecodeModule.read();
      switch (instruction) {
        case OpCode.lineInfo:
          _currentLine = _currentBytecodeModule.readUint16();
          _currentColumn = _currentBytecodeModule.readUint16();
        // store a local value in interpreter
        case OpCode.local:
          _storeLocal();
        // store current local value to a register position
        case OpCode.register:
          final index = _currentBytecodeModule.read();
          _setRegVal(index, _localValue);
        case OpCode.skip:
          final distance = _currentBytecodeModule.readInt16();
          _currentBytecodeModule.ip += distance;
        case OpCode.file:
          _currentFile = _currentBytecodeModule.getConstString();
          final resourceTypeIndex = _currentBytecodeModule.read();
          _currentFileResourceType =
              HTResourceType.values.elementAt(resourceTypeIndex);
          if (_currentFileResourceType != HTResourceType.hetuLiteralCode) {
            currentNamespace = HTNamespace(
                lexicon: _lexicon, id: _currentFile, closure: globalNamespace);
          }
          // literal code will use current namespace as it is when run.
          else {
            currentNamespace = globalNamespace;
          }
        // store the loop jump point
        case OpCode.loopPoint:
          final continueLength = _currentBytecodeModule.readUint16();
          final breakLength = _currentBytecodeModule.readUint16();
          _loops.add(_LoopInfo(
              _currentBytecodeModule.ip,
              _currentBytecodeModule.ip + continueLength,
              _currentBytecodeModule.ip + breakLength,
              currentNamespace));
          ++_loopCount;
        case OpCode.breakLoop:
          _currentBytecodeModule.ip = _loops.last.breakIp;
          currentNamespace = _loops.last.namespace;
          _loops.removeLast();
          --_loopCount;
        case OpCode.continueLoop:
          _currentBytecodeModule.ip = _loops.last.continueIp;
        // store the goto jump point
        case OpCode.anchor:
          _anchors.add(_currentBytecodeModule.ip);
          ++_anchorCount;
        case OpCode.clearAnchor:
          assert(_anchors.isNotEmpty);
          _anchors.removeLast();
          --_anchorCount;
        case OpCode.goto:
          assert(_anchors.isNotEmpty);
          final distance = _currentBytecodeModule.readUint16();
          _currentBytecodeModule.ip = _anchors.last + distance;
        case OpCode.assertion:
          assert(_localValue is bool);
          final text = _currentBytecodeModule.getConstString();
          if (!_localValue) {
            throw HTError.assertionFailed(text);
          }
        case OpCode.throws:
          throw HTError.scriptThrows(_lexicon.stringify(_localValue));
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case OpCode.codeBlock:
          final id = _currentBytecodeModule.getConstString();
          currentNamespace =
              HTNamespace(lexicon: _lexicon, id: id, closure: currentNamespace);
        case OpCode.endOfCodeBlock:
          currentNamespace = currentNamespace.closure!;
        // 语句结束
        case OpCode.endOfStmt:
          _clearLocals();
        case OpCode.endOfExec:
          return _localValue;
        case OpCode.endOfFunc:
          for (var i = 0; i < _loopCount; ++i) {
            _loops.removeLast();
          }
          _loopCount = 0;
          for (var i = 0; i < _anchorCount; ++i) {
            _anchors.removeLast();
          }
          _anchorCount = 0;
          return _localValue;
        case OpCode.createStackFrame:
          _createStackFrame();
        case OpCode.retractStackFrame:
          _retractStackFrame();
        case OpCode.constIntTable:
          final int64Length = _currentBytecodeModule.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _currentBytecodeModule
                .addGlobalConstant<int>(_currentBytecodeModule.readInt64());
            // _bytecodeModule.addInt(_bytecodeModule.readInt64());
          }
        case OpCode.constFloatTable:
          final float64Length = _currentBytecodeModule.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _currentBytecodeModule.addGlobalConstant<double>(
                _currentBytecodeModule.readFloat64());
            // _bytecodeModule.addFloat(_bytecodeModule.readFloat64());
          }
        case OpCode.constStringTable:
          final utf8StringLength = _currentBytecodeModule.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _currentBytecodeModule.addGlobalConstant<String>(
                _currentBytecodeModule.readUtf8String());
          }
        case OpCode.endOfFile:
          if (_currentFileResourceType == HTResourceType.json) {
            final jsonSource = HTJsonSource(
              fullName: _currentFile,
              module: _currentBytecodeModule.id,
              value: _localValue,
            );
            _currentBytecodeModule.jsonSources[jsonSource.fullName] =
                jsonSource;
          } else if (_currentFileResourceType == HTResourceType.hetuModule) {
            _currentBytecodeModule.namespaces[currentNamespace.id!] =
                currentNamespace;
          }
        // endOfFileHandler?.call();
        case OpCode.endOfModule:
          if (!_scriptMode) {
            /// deal with import statement within every namespace of this module.
            for (final nsp in _currentBytecodeModule.namespaces.values) {
              for (final decl in nsp.imports.values) {
                _handleNamespaceImport(nsp, decl);
              }
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
          if (config.printPerformanceStatistics) {
            final tok = DateTime.now().millisecondsSinceEpoch;
            var message =
                'hetu: ${tok - tik}ms\tto load module\t${_currentBytecodeModule.id}';
            if (_currentBytecodeModule.version != null) {
              message += '@${_currentBytecodeModule.version}';
            }
            message +=
                ' (compiled at ${_currentBytecodeModule.compiledAt} UTC with hetu@$compilerVersion)';
            print(message);
          }
          if (_globallyImport && currentNamespace != globalNamespace) {
            globalNamespace.import(currentNamespace);
          }
          dynamic r;
          if (_invoke != null) {
            r = invoke(
              _invoke!,
              // module: scriptMode ? null : _currentBytecodeModule.id,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs,
            );
            return r;
          } else if (_scriptMode) {
            r = _stackFrames.last.first;
          }
          return r;
        case OpCode.importExportDecl:
          _handleImportExport();
        case OpCode.typeAliasDecl:
          _handleTypeAliasDecl();
        case OpCode.funcDecl:
          _handleFuncDecl();
        case OpCode.classDecl:
          _handleClassDecl();
        case OpCode.classDeclEnd:
          assert(currentNamespace is HTClassNamespace);
          final klass = (currentNamespace as HTClassNamespace).klass;
          currentNamespace = currentNamespace.closure!;
          // Add default constructor if there's none.
          if (!klass.isAbstract &&
              !klass.hasUserDefinedConstructor &&
              !klass.isExternal) {
            final ctorType =
                HTFunctionType(returnType: HTNominalType(id: klass.id!));
            final ctor = HTFunction(
              _currentFile,
              _currentBytecodeModule.id,
              this,
              internalName: InternalIdentifier.defaultConstructor,
              classId: klass.id,
              closure: klass.namespace,
              category: FunctionCategory.constructor,
              declType: ctorType,
            );
            klass.namespace.define(InternalIdentifier.defaultConstructor, ctor);
          }
          _localValue = klass;
        case OpCode.externalEnumDecl:
          _handleExternalEnumDecl();
        case OpCode.structDecl:
          _handleStructDecl();
        case OpCode.varDecl:
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
          final isPrivate = _currentBytecodeModule.readBool();
          final isField = _currentBytecodeModule.readBool();
          final isExternal = _currentBytecodeModule.readBool();
          final isStatic = _currentBytecodeModule.readBool();
          final isMutable = _currentBytecodeModule.readBool();
          final isTopLevel = _currentBytecodeModule.readBool();
          if (isTopLevel && currentNamespace.willExportAll) {
            currentNamespace.declareExport(id);
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
          FutureExecution? futureExecution;
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
                file: _currentFile,
                module: _currentBytecodeModule.id,
                classId: classId,
                closure: currentNamespace,
                documentation: documentation,
                declType: declType,
                isPrivate: isPrivate,
                isExternal: isExternal,
                isStatic: isStatic,
                isMutable: isMutable,
                isField: isField,
                ip: definitionIp,
                line: definitionLine,
                column: definitionColumn,
              );
            } else {
              final length = _currentBytecodeModule.readUint16();
              final definitionIp = _currentBytecodeModule.ip;
              initValue = execute();
              if (initValue is FutureExecution) {
                _currentBytecodeModule.ip = definitionIp + length;
                decl = HTVariable(
                  id: id,
                  interpreter: this,
                  file: _currentFile,
                  module: _currentBytecodeModule.id,
                  classId: classId,
                  closure: currentNamespace,
                  documentation: documentation,
                  declType: declType,
                  isPrivate: _lexicon.isPrivate(id),
                  isExternal: isExternal,
                  isStatic: isStatic,
                  isMutable: isMutable,
                  isField: isField,
                );
                final savedContext = getContext();
                futureExecution = FutureExecution(
                  context: savedContext,
                  future: waitFutureExucution(initValue).then((value) {
                    decl.value = value;
                  }),
                );
              } else {
                decl = HTVariable(
                  id: id,
                  interpreter: this,
                  file: _currentFile,
                  module: _currentBytecodeModule.id,
                  classId: classId,
                  closure: currentNamespace,
                  documentation: documentation,
                  declType: declType,
                  value: initValue,
                  isPrivate: isPrivate,
                  isExternal: isExternal,
                  isStatic: isStatic,
                  isMutable: isMutable,
                  isField: isField,
                );
              }
            }
          } else {
            decl = HTVariable(
              id: id,
              interpreter: this,
              file: _currentFile,
              module: _currentBytecodeModule.id,
              classId: classId,
              closure: currentNamespace,
              documentation: documentation,
              declType: declType,
              isPrivate: isPrivate,
              isExternal: isExternal,
              isStatic: isStatic,
              isMutable: isMutable,
              isField: isField,
              lateFinalize: lateFinalize,
            );
          }
          if (!isField) {
            currentNamespace.define(id, decl,
                override: config.allowVariableShadowing);
          }
          _localValue = initValue;
          if (futureExecution != null) {
            return futureExecution;
          }
        case OpCode.destructuringDecl:
          _handleDestructuringDecl();
        case OpCode.constDecl:
          _handleConstDecl();
        case OpCode.namespaceDecl:
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
          final isPrivate = _currentBytecodeModule.readBool();
          final isTopLevel = _currentBytecodeModule.readBool();
          currentNamespace = HTNamespace(
            lexicon: _lexicon,
            id: id,
            classId: classId,
            closure: currentNamespace,
            documentation: documentation,
            isPrivate: isPrivate,
            isTopLevel: isTopLevel,
          );
        case OpCode.namespaceDeclEnd:
          final nsp = currentNamespace;
          _localValue = nsp;
          assert(nsp.closure != null);
          currentNamespace = nsp.closure!;
          assert(nsp.id != null);
          currentNamespace.define(nsp.id!, nsp);
        case OpCode.delete:
          final deletingType = _currentBytecodeModule.read();
          if (deletingType == HTDeletingTypeCode.member) {
            final object = execute();
            if (object is HTStruct) {
              final symbol = _currentBytecodeModule.getConstString();
              object.delete(symbol);
            } else {
              throw HTError.delete(
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else if (deletingType == HTDeletingTypeCode.sub) {
            final object = execute();
            if (object is HTStruct) {
              final symbol = execute().toString();
              object.delete(symbol);
            } else {
              throw HTError.delete(
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            final symbol = _currentBytecodeModule.getConstString();
            currentNamespace.delete(symbol);
          }
        case OpCode.ifStmt:
          final thenBranchLength = _currentBytecodeModule.readUint16();
          final truthValue = _truthy(_localValue);
          if (!truthValue) {
            _currentBytecodeModule.skip(thenBranchLength);
            _clearLocals();
          }
        case OpCode.whileStmt:
          final truthValue = _truthy(_localValue);
          if (!truthValue) {
            _currentBytecodeModule.ip = _loops.last.breakIp;
            currentNamespace = _loops.last.namespace;
            _loops.removeLast();
            --_loopCount;
            _clearLocals();
          }
        case OpCode.doStmt:
          final hasCondition = _currentBytecodeModule.readBool();
          final truthValue = hasCondition ? _truthy(_localValue) : false;
          if (truthValue) {
            _currentBytecodeModule.ip = _loops.last.startIp;
          } else {
            _currentBytecodeModule.ip = _loops.last.breakIp;
            currentNamespace = _loops.last.namespace;
            _loops.removeLast();
            --_loopCount;
            _clearLocals();
          }
        case OpCode.switchStmt:
          _handleSwitch();
        case OpCode.assign:
          final value = _getRegVal(HTRegIdx.assignRight);
          assert(localSymbol != null);
          final id = localSymbol!;
          final result = currentNamespace.memberSet(id, value,
              isRecursive: true, throws: false);
          if (!result) {
            if (config.allowImplicitVariableDeclaration) {
              final decl = HTVariable(
                  id: id,
                  interpreter: this,
                  file: _currentFile,
                  module: _currentBytecodeModule.id,
                  closure: currentNamespace,
                  value: value,
                  isPrivate: _lexicon.isPrivate(id),
                  isMutable: true);
              currentNamespace.define(id, decl);
            } else {
              throw HTError.undefined(id);
            }
          }
          _localValue = value;
        case OpCode.ifNull:
          final left = _getRegVal(HTRegIdx.orLeft);
          final rightValueLength = _currentBytecodeModule.readUint16();
          if (left != null) {
            _currentBytecodeModule.skip(rightValueLength);
            _localValue = left;
          } else {
            final right = execute();
            _localValue = right;
          }
        case OpCode.logicalOr:
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
        case OpCode.logicalAnd:
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
        case OpCode.equal:
          var left = _getRegVal(HTRegIdx.equalLeft);
          _localValue = left == _localValue;
        case OpCode.notEqual:
          var left = _getRegVal(HTRegIdx.equalLeft);
          _localValue = left != _localValue;
        case OpCode.lesser:
          var left = _getRegVal(HTRegIdx.relationLeft);
          var right = _localValue;
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          _localValue = left < right;
        case OpCode.greater:
          var left = _getRegVal(HTRegIdx.relationLeft);
          var right = _localValue;
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          _localValue = left > right;
        case OpCode.lesserOrEqual:
          var left = _getRegVal(HTRegIdx.relationLeft);
          var right = _localValue;
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          _localValue = left <= right;
        case OpCode.greaterOrEqual:
          var left = _getRegVal(HTRegIdx.relationLeft);
          var right = _localValue;
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          _localValue = left >= right;
        case OpCode.typeAs:
          final object = _getRegVal(HTRegIdx.relationLeft);
          final type = (_localValue as HTType).resolve(currentNamespace)
              as HTNominalType;
          final klass = type.klass as HTClass;
          _localValue = HTCast(object, klass, this);
        case OpCode.typeIs:
          _handleTypeCheck();
        case OpCode.typeIsNot:
          _handleTypeCheck(isNot: true);
        case OpCode.add:
          var left = _getRegVal(HTRegIdx.addLeft);
          if (_isZero(left)) {
            left = 0;
          }
          var right = _localValue;
          if (_isZero(right)) {
            right = 0;
          }
          _localValue = left + right;
        case OpCode.subtract:
          var left = _getRegVal(HTRegIdx.addLeft);
          if (_isZero(left)) {
            left = 0;
          }
          var right = _localValue;
          if (_isZero(right)) {
            right = 0;
          }
          _localValue = left - right;
        case OpCode.multiply:
          var left = _getRegVal(HTRegIdx.multiplyLeft);
          if (_isZero(left)) {
            left = 0;
          }
          var right = _localValue;
          if (_isZero(right)) {
            right = 0;
          }
          _localValue = left * right;
        case OpCode.devide:
          var left = _getRegVal(HTRegIdx.multiplyLeft);
          if (_isZero(left)) {
            left = 0;
          }
          final right = _localValue;
          _localValue = left / right;
        case OpCode.truncatingDevide:
          var left = _getRegVal(HTRegIdx.multiplyLeft);
          if (_isZero(left)) {
            left = 0;
          }
          final right = _localValue;
          _localValue = left ~/ right;
        case OpCode.modulo:
          var left = _getRegVal(HTRegIdx.multiplyLeft);
          if (_isZero(left)) {
            left = 0;
          }
          final right = _localValue;
          _localValue = left % right;
        case OpCode.negative:
          _localValue = -_localValue;
        case OpCode.logicalNot:
          final truthValue = _truthy(_localValue);
          _localValue = !truthValue;
        case OpCode.typeOf:
          _localValue = typeof(_localValue);
        case OpCode.decltypeOf:
          final symbol = localSymbol;
          assert(symbol != null);
          _localValue = decltypeof(symbol!);
        case OpCode.awaitedValue:
          // handle the possible future execution request raised by await keyword and Future value.
          if (_localValue is Future) {
            final HTContext savedContext = getContext();
            return FutureExecution(future: _localValue, context: savedContext);
          }
        case OpCode.memberGet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _currentBytecodeModule.readBool();
          // final keyBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              // _currentBytecodeModule.skip(keyBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.getter,
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            // final key = execute();
            final key = _getRegVal(HTRegIdx.postfixKey);
            _localSymbol = key;
            final encap = encapsulate(object);
            if (encap is HTNamespace) {
              _localValue = encap.memberGet(key,
                  from: currentNamespace.fullName, isRecursive: false);
            } else {
              _localValue =
                  encap.memberGet(key, from: currentNamespace.fullName);
            }
          }
        case OpCode.subGet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _currentBytecodeModule.readBool();
          // final keyBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              // _currentBytecodeModule.skip(keyBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.subGetter,
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            // final key = execute();
            final key = _localValue;
            if (object is HTEntity) {
              _localValue = object.subGet(key, from: currentNamespace.fullName);
            } else {
              if (object is List) {
                if (key is! num) {
                  throw HTError.subGetKey(key,
                      filename: _currentFile,
                      line: _currentLine,
                      column: _currentColumn);
                }
                final intValue = key.toInt();
                if (intValue != key) {
                  throw HTError.subGetKey(key,
                      filename: _currentFile,
                      line: _currentLine,
                      column: _currentColumn);
                }
                _localValue = object[intValue];
              } else {
                _localValue = object[key];
              }
            }
          }
        case OpCode.memberSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _currentBytecodeModule.readBool();
          // final valueBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              // _currentBytecodeModule.skip(valueBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.setter,
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            final key = _getRegVal(HTRegIdx.postfixKey);
            final value = _getRegVal(HTRegIdx.assignRight);
            _localValue = value;
            final encap = encapsulate(object);
            if (encap is HTNamespace) {
              encap.memberSet(key, value,
                  from: currentNamespace.fullName, isRecursive: false);
            } else {
              encap.memberSet(key, value, from: currentNamespace.fullName);
            }
          }
        case OpCode.subSet:
          final object = _getRegVal(HTRegIdx.postfixObject);
          final isNullable = _currentBytecodeModule.readBool();
          // final keyAndValueBytesLength = _currentBytecodeModule.readUint16();
          if (object == null) {
            if (isNullable) {
              // _currentBytecodeModule.skip(keyAndValueBytesLength);
              _localValue = null;
            } else {
              throw HTError.nullObject(
                  localSymbol ?? _lexicon.kNull, InternalIdentifier.subSetter,
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            final key = _localValue;
            final value = _getRegVal(HTRegIdx.assignRight);
            _localValue = value;
            if (object is HTEntity) {
              object.subSet(key, value);
            } else {
              if (object is HTEntity) {
                object.subSet(key, value, from: currentNamespace.fullName);
              } else {
                if (object is List) {
                  if (key is! num) {
                    throw HTError.subGetKey(key,
                        filename: _currentFile,
                        line: _currentLine,
                        column: _currentColumn);
                  }
                  final intValue = key.toInt();
                  if (intValue != key) {
                    throw HTError.subGetKey(key,
                        filename: _currentFile,
                        line: _currentLine,
                        column: _currentColumn);
                  }
                  object[intValue] = value;
                } else {
                  object[key] = value;
                }
              }
            }
          }
        case OpCode.call:
          _handleCallExpr();
        default:
          throw HTError.unknownOpCode(instruction,
              filename: _currentFile,
              line: _currentLine,
              column: _currentColumn);
      }
    } while (instruction != OpCode.endOfCode);
  }

  Future<dynamic> waitFutureExucution(
    FutureExecution futureExecution, {
    HTContext? context,
    List<dynamic>? stackFrame,
  }) async {
    final value = await futureExecution.future.then((v) async {
      final f = execute(
        createStackFrame: false,
        retractStackFrame: false,
        context: context ?? futureExecution.context,
        stackFrame: stackFrame,
        localValue: v,
      );
      if (f is FutureExecution) {
        final r = await waitFutureExucution(
          f,
          context: f.context,
          stackFrame: getCurrentStackFrame(),
        );
        return r;
      } else {
        _retractStackFrame();
        return f;
      }
    });
    return value;
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
        currentNamespace.declareExport(id);
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

    // If the import path starts with 'module:', then the module should be
    // already loaded by the loadBytecode() method.
    if (isPreloadedModule) {
      assert(fromPath != null);
      assert(cachedModules.containsKey(fromPath));
      if (cachedModules.containsKey(fromPath)) {
        final importedModule = cachedModules[fromPath]!;
        final importedNamespace = importedModule.namespaces.values.last;
        if (showList.isEmpty) {
          currentNamespace.defineImport(
              alias!, importedNamespace, 'module:${importedModule.id}');
        } else {
          final aliasNamespace = HTNamespace(
              lexicon: _lexicon, id: alias!, closure: currentNamespace.closure);
          for (final id in showList) {
            final decl = importedNamespace.symbols[id]!;
            assert(!decl.isPrivate);
            aliasNamespace.define(id, decl);
          }
          currentNamespace.defineImport(
              alias, aliasNamespace, 'module:${importedModule.id}');
        }
      }
    }
    // TODO: If the import path starts with 'package:', will try to fetch the source file from '.hetu_packages' under root.
    else {
      if (fromPath != null) {
        final ext = path.extension(fromPath);
        if (ext != HTResource.hetuModule && ext != HTResource.hetuScript) {
          // TODO: import binary bytes
          assert(_currentBytecodeModule.jsonSources.containsKey(fromPath));
          if (_currentBytecodeModule.jsonSources.containsKey(fromPath)) {
            final jsonSource = _currentBytecodeModule.jsonSources[fromPath];
            currentNamespace.defineImport(
              alias!,
              HTVariable(
                id: alias,
                interpreter: this,
                value: jsonSource!.value,
                closure: currentNamespace,
                isPrivate: _lexicon.isPrivate(alias),
              ),
              jsonSource.fullName,
            );
            if (isExported) {
              currentNamespace.declareExport(alias);
            }
          }
        } else {
          final decl = UnresolvedImport(fromPath,
              alias: alias, showList: showList, isExported: isExported);
          if (_currentFileResourceType == HTResourceType.hetuModule) {
            currentNamespace.declareImport(decl);
          } else {
            _handleNamespaceImport(currentNamespace, decl);
          }
        }
      } else {
        // If it's an export statement regarding this namespace self,
        // It will be handled immediately since it does not needed resolve.
        assert(isExported);
        if (showList.isNotEmpty) {
          currentNamespace.willExportAll = false;
          currentNamespace.exports.addAll(showList);
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
      case HTValueTypeCode.boolean:
        (_currentBytecodeModule.read() == 0)
            ? _localValue = false
            : _localValue = true;
      case HTValueTypeCode.constInt:
        final index = _currentBytecodeModule.readUint16();
        _localValue = _currentBytecodeModule.getGlobalConstant(int, index);
      case HTValueTypeCode.constFloat:
        final index = _currentBytecodeModule.readUint16();
        _localValue = _currentBytecodeModule.getGlobalConstant(double, index);
      case HTValueTypeCode.constString:
        final index = _currentBytecodeModule.readUint16();
        _localValue = _currentBytecodeModule.getGlobalConstant(String, index);
      case HTValueTypeCode.string:
        _localValue = _currentBytecodeModule.readUtf8String();
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
      case HTValueTypeCode.identifier:
        final symbol = _localSymbol = _currentBytecodeModule.getConstString();
        final isLocal = _currentBytecodeModule.readBool();
        if (isLocal) {
          _localValue = currentNamespace.memberGet(symbol, isRecursive: true);
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
      case HTValueTypeCode.group:
        _localValue = execute();
      case HTValueTypeCode.list:
        final list = [];
        final length = _currentBytecodeModule.readUint16();
        for (var i = 0; i < length; ++i) {
          final isSpread = _currentBytecodeModule.readBool();
          if (!isSpread) {
            final listItem = execute();
            list.add(listItem);
          } else {
            final Iterable spreadValue = execute();
            list.addAll(spreadValue);
          }
        }
        _localValue = list;
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
          prototype = currentNamespace.memberGet(prototypeId,
              from: currentNamespace.fullName, isRecursive: true);
        }
        final struct = HTStruct(this,
            id: id,
            prototype: prototype,
            isRootPrototype: id == _lexicon.globalPrototypeId,
            closure: currentNamespace);
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
                    declType: param.declType ?? HTTypeAny(_lexicon.kAny),
                    isOptional: param.isOptional,
                    isVariadic: param.isVariadic,
                    id: param.isNamed ? param.id : null))
                .toList(),
            returnType: returnType ?? HTTypeAny(_lexicon.kAny));
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
            _currentFile,
            _currentBytecodeModule.id,
            this,
            closure: currentNamespace,
            category: FunctionCategory.literal,
            externalTypeId: externalTypedef,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
            declType: declType,
            isPrivate: true,
            isAsync: isAsync,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            ip: definitionIp,
            line: line,
            column: column,
            namespace: currentNamespace);
        if (!hasExternalTypedef) {
          _localValue = func;
        } else {
          final externalFunc = unwrapExternalFunctionType(func);
          _localValue = externalFunc;
        }
      case HTValueTypeCode.intrinsicType:
        _localValue = _handleIntrinsicType();
      case HTValueTypeCode.nominalType:
        _localValue = _handleNominalType();
      case HTValueTypeCode.functionType:
        _localValue = _handleFunctionType();
      case HTValueTypeCode.structuralType:
        _localValue = _handleStructuralType();
      default:
        throw HTError.unkownValueType(
          valueType,
          filename: _currentFile,
          line: _currentLine,
          column: _currentColumn,
        );
    }
  }

  void _handleSwitch() {
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
      if (caseType == HTSwitchCaseTypeCode.equals) {
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
      } else if (caseType == HTSwitchCaseTypeCode.eigherEquals) {
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
      } else if (caseType == HTSwitchCaseTypeCode.elementIn) {
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
    final rightType = (_localValue as HTType).resolve(currentNamespace);
    HTType leftType;
    if (object != null) {
      if (object is HTType) {
        leftType = object;
      } else {
        final encapsulated = encapsulate(object);
        leftType = encapsulated.valueType!;
      }
    } else {
      leftType = HTTypeNull(_lexicon.kNull);
    }
    final result = leftType.isA(rightType);
    _localValue = isNot ? !result : result;
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
            filename: _currentFile, line: _currentLine, column: _currentColumn);
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
    if (typeName == _lexicon.kAny) {
      return HTTypeAny(typeName);
    } else if (typeName == _lexicon.kUnknown) {
      return HTTypeUnknown(typeName);
    } else if (typeName == _lexicon.kVoid) {
      return HTTypeVoid(typeName);
    } else if (typeName == _lexicon.kNever) {
      return HTTypeNever(typeName);
    } else if (typeName == _lexicon.kType) {
      return HTTypeType(typeName);
    } else if (lexicon.kFunctions.contains(typeName)) {
      return HTTypeFunction(lexicon.kFunction);
    } else if (typeName == _lexicon.kNamespace) {
      return HTTypeNamespace(typeName);
    }
    // fallsafe measure, however this should not happen
    return HTIntrinsicType(typeName, isTop: isTop, isBottom: isBottom);
  }

  HTNominalType _handleNominalType() {
    final typeName = _currentBytecodeModule.getConstString();
    final namespacesLength = _currentBytecodeModule.read();
    final namespacesWithin = <String>[];
    for (var i = 0; i < namespacesLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      namespacesWithin.add(id);
    }
    final typeArgsLength = _currentBytecodeModule.read();
    final typeArgs = <HTType>[];
    for (var i = 0; i < typeArgsLength; ++i) {
      final typearg = _handleTypeExpr();
      typeArgs.add(typearg);
    }
    final isNullable = (_currentBytecodeModule.read() == 0) ? false : true;
    return HTNominalType(
      id: typeName,
      typeArgs: typeArgs,
      isNullable: isNullable,
      namespacesWithin: namespacesWithin,
    );
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
    return HTStructuralType(fieldTypes: fieldTypes, closure: currentNamespace);
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
            filename: _currentFile, line: _currentLine, column: _currentColumn);
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
    final isPrivate = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    final value = _handleTypeExpr();
    final decl = HTVariable(
      id: id,
      interpreter: this,
      classId: classId,
      closure: currentNamespace,
      documentation: documentation,
      value: value,
      isPrivate: isPrivate,
    );
    currentNamespace.define(id, decl);
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
    final isPrivate = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    final typeIndex = _currentBytecodeModule.read();
    final type = HTConstantType.values.elementAt(typeIndex);
    final index = _currentBytecodeModule.readUint16();
    final decl = HTConstantValue(
      id: id,
      type: getConstantType(type),
      index: index,
      classId: classId,
      documentation: documentation,
      globalConstantTable: _currentBytecodeModule,
      isPrivate: isPrivate,
    );
    currentNamespace.define(id, decl, override: config.allowVariableShadowing);
    // _localValue = _currentBytecodeModule.getGlobalConstant(type, index);
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
        if (isTopLevel && currentNamespace.willExportAll) {
          currentNamespace.declareExport(id);
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
        file: _currentFile,
        module: _currentBytecodeModule.id,
        closure: currentNamespace,
        declType: ids[id],
        value: initValue,
        isPrivate: _lexicon.isPrivate(id),
        isMutable: isMutable,
      );
      currentNamespace.define(id, decl,
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
        file: _currentFile,
        module: _currentBytecodeModule.id,
        closure: currentNamespace,
        declType: declType,
        ip: definitionIp,
        line: definitionLine,
        column: definitionColumn,
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
    final isPrivate = _currentBytecodeModule.readBool();
    final isAsync = _currentBytecodeModule.readBool();
    final isField = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isStatic = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      if (id != null) {
        currentNamespace.declareExport(id);
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
                declType: param.declType ?? HTTypeAny(_lexicon.kAny),
                isOptional: param.isOptional,
                isVariadic: param.isVariadic,
                id: param.isNamed ? param.id : null))
            .toList(),
        returnType: returnType ?? HTTypeAny(_lexicon.kAny));
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
    final func = HTFunction(
      _currentFile,
      _currentBytecodeModule.id,
      this,
      internalName: internalName,
      id: id,
      classId: classId,
      closure: currentNamespace,
      documentation: documentation,
      isPrivate: isPrivate,
      isAbstract: !hasDefinition && !isExternal,
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
      ip: definitionIp,
      line: line,
      column: column,
      redirectingConstructor: redirCtor,
    );
    if (!isField) {
      if ((category != FunctionCategory.constructor) || isStatic) {
        func.namespace = currentNamespace;
      }
      currentNamespace.define(func.internalName, func);
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
    final isPrivate = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isAbstract = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
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
        superType = HTNominalType(klass: object);
      }
    }
    final isEnum = _currentBytecodeModule.readBool();
    final klass = HTClass(
      this,
      id: id,
      closure: currentNamespace,
      documentation: documentation,
      superType: superType,
      isPrivate: isPrivate,
      isExternal: isExternal,
      isAbstract: isAbstract,
      isEnum: isEnum,
      hasUserDefinedConstructor: hasUserDefinedConstructor,
    );
    currentNamespace.define(id, klass);
    currentNamespace = klass.namespace;
  }

  void _handleExternalEnumDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    final enumClass =
        HTExternalEnum(this, id: id, documentation: documentation);
    currentNamespace.define(id, enumClass);
    _localValue = enumClass;
  }

  void _handleStructDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isPrivate = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
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
      file: _currentFile,
      module: _currentBytecodeModule.id,
      closure: currentNamespace,
      documentation: documentation,
      isPrivate: isPrivate,
      isTopLevel: isTopLevel,
      prototypeId: prototypeId,
      mixinIds: mixinIds,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: definitionIp,
    );
    currentNamespace.define(id, struct);
    _localValue = struct;
  }
}
