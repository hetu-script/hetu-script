import 'dart:math' as math;

import 'package:pub_semver/pub_semver.dart';
import 'package:meta/meta.dart';

import '../source/source.dart';
import '../source/source_provider.dart';
import '../binding/external_class.dart';
import '../binding/external_function.dart';
import '../binding/external_instance.dart';
import '../buildin/buildin_class.dart';
import '../buildin/buildin_function.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../type/type.dart';
import '../declaration/function/function.dart';
import '../declaration/namespace.dart';
import '../declaration/library.dart';
import '../scanner/abstract_parser.dart';
import '../buildin/hetu_lib.dart';
import '../object/object.dart';
import 'compiler.dart';

/// Mixin for classes want to use a shared interpreter referrence.
mixin InterpreterRef {
  late final AbstractInterpreter interpreter;
}

class InterpreterConfig
    implements ParserConfig, CompilerConfig, ErrorHandlerConfig {
  @override
  final SourceType sourceType;

  @override
  final bool reload;

  @override
  final bool lineInfo;

  @override
  final bool externalStackTrace;

  @override
  final bool hetuStackTrace;

  @override
  final int hetuStackTraceThreshhold;

  const InterpreterConfig(
      {this.sourceType = SourceType.module,
      this.reload = false,
      this.lineInfo = true,
      this.externalStackTrace = true,
      this.hetuStackTrace = true,
      this.hetuStackTraceThreshhold = 10});
}

/// Base class for bytecode interpreter and static analyzer of Hetu.
abstract class AbstractInterpreter<T> implements HTErrorHandler {
  static final version = Version(0, 1, 0);
  static const _anonymousScriptSignatureLength = 72;

  final stackTrace = <String>[];

  dynamic get failedResult => null;

  InterpreterConfig config;

  InterpreterConfig get curConfig => config;

  /// Current line number of execution.
  int get curLine;

  /// Current column number of execution.
  int get curColumn;

  HTNamespace get curNamespace;

  String get curModuleFullName;

  HTLibrary get curLibrary;

  late HTSourceProvider sourceProvider;

  final HTNamespace global = HTNamespace(id: SemanticNames.global);

  AbstractInterpreter(
      {this.config = const InterpreterConfig(),
      HTSourceProvider? sourceProvider}) {
    this.sourceProvider =
        sourceProvider ?? DefaultSourceProvider(errorHandler: this);
  }

  @mustCallSuper
  void init(
      {bool coreModule = true,
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) {
    try {
      // load classes and functions in core library.
      if (coreModule) {
        for (final file in coreModules.keys) {
          eval(coreModules[file]!,
              moduleFullName: file,
              namespace: global,
              config: InterpreterConfig(sourceType: SourceType.module));
        }
        for (var key in coreFunctions.keys) {
          bindExternalFunction(key, coreFunctions[key]!);
        }
        bindExternalClass(HTNumberClass());
        bindExternalClass(HTIntegerClass());
        bindExternalClass(HTFloatClass());
        bindExternalClass(HTBooleanClass());
        bindExternalClass(HTStringClass());
        bindExternalClass(HTListClass());
        bindExternalClass(HTMapClass());
        bindExternalClass(HTMathClass());
        bindExternalClass(HTSystemClass());
        bindExternalClass(HTConsoleClass());
      }

      for (var key in externalFunctions.keys) {
        bindExternalFunction(key, externalFunctions[key]!);
      }

      for (var key in externalFunctionTypedef.keys) {
        bindExternalFunctionType(key, externalFunctionTypedef[key]!);
      }

      for (var value in externalClasses) {
        bindExternalClass(value);
      }
    } catch (error, stackTrace) {
      handleError(error, externalStackTrace: stackTrace);
    }
  }

  T? evalSource(HTSource source,
      {HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  T? eval(String content,
      {String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    if (moduleFullName == null) {
      final sigBuilder = StringBuffer();
      sigBuilder.write('${SemanticNames.anonymousScript}: [');
      var firstLine = content.trimLeft().replaceAll(RegExp(r'\s+'), ' ');
      sigBuilder.write(firstLine.substring(
          0, math.min(_anonymousScriptSignatureLength, firstLine.length)));
      if (firstLine.length > _anonymousScriptSignatureLength) {
        sigBuilder.write('...');
      }
      sigBuilder.write(']');
      moduleFullName = sigBuilder.toString();
    }

    final source = HTSource(moduleFullName, content);

    final result = evalSource(source,
        // when eval string, use current namespace by default
        namespace: namespace ?? curNamespace,
        config: config,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
        errorHandled: errorHandled);

    return result;
  }

  /// 解析文件
  T? evalFile(String key,
      {bool useLastModuleFullName = false,
      String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    final module = sourceProvider.getSourceSync(key,
        from: useLastModuleFullName
            ? curModuleFullName
            : sourceProvider.workingDirectory);
    if (module == null) {
      return failedResult;
    }
    final result = evalSource(module,
        namespace: namespace,
        config: config,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
        errorHandled: true);

    return result;
  }

  /// 调用一个全局函数或者类、对象上的函数
  dynamic invoke(String funcName,
      {String? classId,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {}

  HTObject encapsulate(dynamic object) {
    if (object is HTObject) {
      return object;
    } else if ((object == null) || (object is NullThrownError)) {
      return HTObject.NULL;
    }

    late String typeString;

    if (object is bool) {
      typeString = HTLexicon.boolean;
    } else if (object is int) {
      typeString = HTLexicon.integer;
    } else if (object is double) {
      typeString = HTLexicon.float;
    } else if (object is String) {
      typeString = HTLexicon.string;
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

  /// Register a external class into scrfipt
  /// for acessing static members and constructors of this class
  /// there must be a declaraction also in script for using this
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
