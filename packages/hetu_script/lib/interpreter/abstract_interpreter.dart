import 'package:meta/meta.dart';

import 'dart:math' as math;

import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../binding/external_class.dart';
import '../binding/external_function.dart';
import '../binding/external_instance.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../grammar/lexicon.dart';
import '../type/type.dart';
import '../value/function/function.dart';
import '../value/namespace/namespace.dart';
import '../parser/abstract_parser.dart';
import '../value/entity.dart';
import '../value/instance/instance.dart';
import 'compiler.dart';
import '../value/struct/struct.dart';
import '../shared/stringify.dart';
import '../shared/jsonify.dart';

part 'preinclude/preinclude_modules.dart';
part 'preinclude/preinclude_functions.dart';
part 'preinclude/class_binding.dart';
part 'preinclude/instance_binding.dart';

/// Mixin for classes want to use a shared interpreter referrence.
mixin InterpreterRef {
  late final HTAbstractInterpreter interpreter;
}

class InterpreterConfig
    implements ParserConfig, CompilerConfig, ErrorHandlerConfig {
  @override
  final bool compileWithLineInfo;

  @override
  final bool doStaticAnalyze;

  @override
  final bool showDartStackTrace;

  @override
  final int hetuStackTraceDisplayCountLimit;

  @override
  final ErrorHanldeApproach errorHanldeApproach;

  final bool allowHotReload;

  const InterpreterConfig(
      {this.compileWithLineInfo = true,
      this.doStaticAnalyze = true,
      this.showDartStackTrace = true,
      this.hetuStackTraceDisplayCountLimit = 3,
      this.errorHanldeApproach = ErrorHanldeApproach.exception,
      this.allowHotReload = false});
}

/// Base class for bytecode interpreter and static analyzer of Hetu.
///
/// Each instance of a interpreter has a independent global [HTNamespace].
abstract class HTAbstractInterpreter<T> implements HTErrorHandler {
  List<String> get stackTrace;

  InterpreterConfig get config;

  /// Current line number of execution.
  int get line;

  /// Current column number of execution.
  int get column;

  HTNamespace get namespace;

  String get fileName;

  HTResourceContext<HTSource> get sourceContext;

  HTNamespace get global;

  @mustCallSuper
  void init({
    List<HTSource> preincludeModules = const [],
    Map<String, Function> externalFunctions = const {},
    Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
    List<HTExternalClass> externalClasses = const [],
  }) {
    try {
      // bind externals before any eval
      for (var key in preIncludeFunctions.keys) {
        bindExternalFunction(key, preIncludeFunctions[key]!);
      }
      bindExternalClass(HTNumberClass());
      bindExternalClass(HTIntClass());
      bindExternalClass(HTBigIntClass());
      bindExternalClass(HTFloatClass());
      bindExternalClass(HTBooleanClass());
      bindExternalClass(HTStringClass());
      bindExternalClass(HTListClass());
      bindExternalClass(HTMapClass());
      bindExternalClass(HTMathClass());
      bindExternalClass(HTSystemClass());
      bindExternalClass(HTFutureClass());
      // bindExternalClass(HTConsoleClass());

      // load classes and functions in core library.
      for (final file in preIncludeModules) {
        evalSource(file, globallyImport: true);
      }

      for (final file in preincludeModules) {
        evalSource(file, globallyImport: true);
      }
      for (final key in externalFunctions.keys) {
        bindExternalFunction(key, externalFunctions[key]!);
      }
      for (final key in externalFunctionTypedef.keys) {
        bindExternalFunctionType(key, externalFunctionTypedef[key]!);
      }
      for (final value in externalClasses) {
        bindExternalClass(value);
      }
    } catch (error, stackTrace) {
      handleError(error, externalStackTrace: stackTrace);
    }
  }

  T? evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      bool isStrictMode = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  T? eval(String content,
      {String? filename,
      String? moduleName,
      bool globallyImport = false,
      bool isModule = false,
      bool isStrictMode = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    final source = HTSource(content,
        name: filename,
        type: isModule ? ResourceType.hetuModule : ResourceType.hetuScript);
    final result = evalSource(source,
        moduleName: moduleName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
        errorHandled: errorHandled);
    return result;
  }

  /// 解析文件
  T? evalFile(String key,
      {String? moduleName,
      bool globallyImport = false,
      bool isStrictMode = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      final source = sourceContext.getResource(key);
      final result = evalSource(source,
          moduleName: moduleName,
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

  /// 调用一个全局函数或者类、对象上的函数
  dynamic invoke(String funcName,
      {String? moduleName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {}

  HTEntity encapsulate(dynamic object) {
    if (object is HTEntity) {
      return object;
    } else if ((object == null) || (object is NullThrownError)) {
      return HTEntity.nullValue;
    }
    late String typeString;
    if (object is bool) {
      typeString = HTLexicon.boolean;
    } else if (object is int) {
      typeString = HTLexicon.integer;
    } else if (object is double) {
      typeString = HTLexicon.float;
    } else if (object is String) {
      typeString = HTLexicon.str;
    } else if (object is List) {
      typeString = HTLexicon.list;
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
    } else if (object is Map) {
      typeString = HTLexicon.map;
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
    } else {
      var reflected = false;
      for (final reflect in _externTypeReflection) {
        final result = reflect(object);
        if (result.success) {
          reflected = true;
          typeString = result.typeString;
          break;
        }
      }
      if (!reflected) {
        typeString = object.runtimeType.toString();
        typeString = HTType.parseBaseType(typeString);
      }
    }

    return HTExternalInstance(object, this, typeString);
  }

  final _externClasses = <String, HTExternalClass>{};
  final _externTypeReflection = <HTExternalTypeReflection>[];
  final _externFuncs = <String, Function>{};
  final _externFuncTypeUnwrappers = <String, HTExternalFunctionTypedef>{};

  bool containsExternalClass(String id) => _externClasses.containsKey(id);

  /// Register a external class into scrfipt.
  /// For acessing static members and constructors of this class,
  /// there must also be a declaraction in script
  void bindExternalClass(HTExternalClass externalClass) {
    if (_externClasses.containsKey(externalClass.valueType)) {
      throw HTError.definedRuntime(externalClass.valueType.toString());
    }
    _externClasses[externalClass.id] = externalClass;
  }

  /// Fetch a external class instance
  HTExternalClass fetchExternalClass(String id) {
    if (!_externClasses.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return _externClasses[id]!;
  }

  /// Bind a external class name to a abstract class name for interpreter get dart class name by reflection
  void bindExternalReflection(HTExternalTypeReflection reflection) {
    _externTypeReflection.add(reflection);
  }

  /// Register a external function into scrfipt
  /// there must be a declaraction also in script for using this
  void bindExternalFunction(String id, Function function) {
    if (_externFuncs.containsKey(id)) {
      throw HTError.definedRuntime(id);
    }
    _externFuncs[id] = function;
  }

  /// Fetch a external function
  Function fetchExternalFunction(String id) {
    if (!_externFuncs.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return _externFuncs[id]!;
  }

  /// Register a external function typedef into scrfipt
  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function) {
    if (_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTError.definedRuntime(id);
    }
    _externFuncTypeUnwrappers[id] = function;
  }

  /// Using unwrapper to turn a script function into a external function
  Function unwrapExternalFunctionType(HTFunction func) {
    if (!_externFuncTypeUnwrappers.containsKey(func.externalTypeId)) {
      throw HTError.undefinedExternal(func.externalTypeId!);
    }
    final unwrapFunc = _externFuncTypeUnwrappers[func.externalTypeId]!;
    return unwrapFunc(func);
  }
}
