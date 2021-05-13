import 'package:pub_semver/pub_semver.dart';

import '../source/source_provider.dart';
import '../binding/external_class.dart';
import '../binding/external_function.dart';
import '../binding/external_instance.dart';
import '../buildin/buildin_class.dart';
import '../buildin/buildin_function.dart';
import '../error/errors.dart';
import '../error/error_handler.dart';
import '../source/source.dart';
import '../grammar/lexicon.dart';
import '../type_system/type.dart';

import 'parser.dart';
import 'namespace/namespace.dart';
import 'hetu_lib.dart';
import 'function/abstract_function.dart';
import 'object.dart';

/// Mixin for classes want to use a shared interpreter referrence.
mixin InterpreterRef {
  late final HTInterpreter interpreter;
}

class InterpreterConfig extends ParserConfig {
  final bool scriptStackTrace;
  final int scriptStackTraceMaxline;
  final bool externalStackTrace;
  final int externalStackTraceMaxline;

  const InterpreterConfig(
      {SourceType sourceType = SourceType.module,
      bool reload = false,
      bool bundle = false,
      bool lineInfo = true,
      this.scriptStackTrace = true,
      this.scriptStackTraceMaxline = 10,
      this.externalStackTrace = true,
      this.externalStackTraceMaxline = 10})
      : super(
            sourceType: sourceType,
            reload: reload,
            bundle: bundle,
            lineInfo: lineInfo);
}

/// Shared interface for a ast or bytecode interpreter of Hetu.
abstract class HTInterpreter {
  static var anonymousScriptIndex = 0;

  final version = Version(0, 1, 0);

  /// Current line number of execution.
  int get curLine;

  /// Current column number of execution.
  int get curColumn;

  String? get curModuleFullName;

  String? get curSymbol;
  String? get curObjectSymbol;

  HTNamespace get curNamespace;

  late HTErrorHandler errorHandler;
  late SourceProvider sourceProvider;

  /// 全局命名空间
  late HTNamespace global;

  HTInterpreter(
      {HTErrorHandler? errorHandler, SourceProvider? sourceProvider}) {
    this.errorHandler = errorHandler ?? DefaultErrorHandler();
    this.sourceProvider = sourceProvider ?? DefaultSourceProvider();
  }

  Future<void> init(
      {bool coreModule = true,
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) async {
    // load classes and functions in core library.
    if (coreModule) {
      for (final file in coreModules.keys) {
        await eval(coreModules[file]!, moduleFullName: file);
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
  }

  Future<dynamic> eval(String content,
      {String? moduleFullName,
      HTNamespace? namespace,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  /// 解析文件
  Future<dynamic> import(String key,
      {String? curModuleFullName,
      String? moduleName,
      InterpreterConfig config = const InterpreterConfig(),
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []});

  /// 调用一个全局函数或者类、对象上的函数
  // TODO: 调用构造函数
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  void handleError(Object error, [StackTrace? stack]);

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
      throw HTError.undefinedExtern(id);
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
      throw HTError.undefinedExtern(id);
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
  Function unwrapExternalFunctionType(String id, HTFunction function) {
    if (!_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTError.undefinedExtern(id);
    }
    final unwrapFunc = _externFuncTypeUnwrappers[id]!;
    return unwrapFunc(function);
  }
}
