import 'package:pub_semver/pub_semver.dart';

import 'namespace.dart';
import 'common.dart';
import 'type.dart';
import 'hetu_lib.dart';
import 'errors.dart';
import 'function.dart';
import 'object.dart';
import 'lexicon.dart';
import 'plugin/moduleHandler.dart';
import 'plugin/errorHandler.dart';
import 'binding/external_class.dart';
import 'binding/external_function.dart';
import 'binding/external_instance.dart';
import 'core/core_class.dart';
import 'core/core_function.dart';

/// Mixin for classes want to use a shared interpreter referrence.
mixin InterpreterRef {
  late final Interpreter interpreter;
}

class InterpreterConfig {
  final bool isDebugMode;
  final bool includeHetuStackTraceInError;
  final bool includeDartStackTraceInError;

  InterpreterConfig(this.isDebugMode, this.includeHetuStackTraceInError,
      this.includeDartStackTraceInError);
}

/// Shared interface for a ast or bytecode interpreter of Hetu.
abstract class Interpreter {
  final version = Version(0, 1, 0);

  int get curLine;
  int get curColumn;
  String? get curModuleUniqueKey;

  String? get curSymbol;
  String? get curObjectSymbol;

  HTNamespace get curNamespace;

  late HTErrorHandler errorHandler;
  late HTModuleHandler moduleHandler;

  /// 全局命名空间
  late HTNamespace global;

  Interpreter({HTErrorHandler? errorHandler, HTModuleHandler? moduleHandler}) {
    this.errorHandler = errorHandler ?? DefaultErrorHandler();
    this.moduleHandler = moduleHandler ?? DefaultModuleHandler();
  }

  Future<void> init(
      {bool coreModule = true,
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) async {
    // load classes and functions in core library.
    // TODO: dynamic load needed core lib in script
    if (coreModule) {
      for (final file in coreModules.keys) {
        await eval(coreModules[file]!, moduleUniqueKey: file);
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
      {String? moduleUniqueKey,
      CodeType codeType = CodeType.module,
      HTNamespace? namespace,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  /// 解析文件
  Future<dynamic> import(String key,
      {String? curModuleUniqueKey,
      String? moduleName,
      CodeType codeType = CodeType.module,
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

    String? typeString;

    if (object is bool) {
      // return HTBoolean(object, this);
    } else if (object is int) {
      typeString = HTLexicon.integer;
      // return HTInteger(object, this);
    } else if (object is double) {
      typeString = HTLexicon.float;
      // return HTFloat(object, this);
    } else if (object is String) {
      typeString = HTLexicon.string;
      // return HTString(object, this);
    } else if (object is List) {
      typeString = HTLexicon.list;
      // var valueType = HTType.ANY;
      // if (object.isNotEmpty) {
      //   valueType = encapsulate(object.first).rtType;
      //   for (final item in object) {
      //     final value = encapsulate(item).rtType;
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
      //   keyType = encapsulate(object.keys.first).rtType;
      //   for (final item in object.keys) {
      //     final value = encapsulate(item).rtType;
      //     if (value.isNotA(keyType)) {
      //       keyType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // if (object.values.isNotEmpty) {
      //   valueType = encapsulate(object.values.first).rtType;
      //   for (final item in object.values) {
      //     final value = encapsulate(item).rtType;
      //     if (value.isNotA(valueType)) {
      //       valueType = HTType.ANY;
      //       break;
      //     }
      //   }
      // }
      // return HTMap(object, this, keyType: keyType, valueType: valueType);
    } else {
      typeString = object.runtimeType.toString();
    }

    // {
    return HTExternalInstance(object, this, typeString);
    // }
  }

  // void defineGlobal(String key, {HTType? declType, dynamic varValue, bool isImmutable = false}) {
  //   globals.define(key, declType: declType, value: value, isImmutable: isImmutable);
  // }

  dynamic fetchGlobal(String key) {
    return global.fetch(key);
  }

  final _externClasses = <String, HTExternalClass>{};
  final _externFuncs = <String, Function>{};
  final _externFuncTypeUnwrappers = <String, HTExternalFunctionTypedef>{};

  bool containsExternalClass(String id) => _externClasses.containsKey(id);

  /// 注册外部类，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalClass(HTExternalClass externalClass) {
    if (_externClasses.containsKey(externalClass.rtType)) {
      throw HTError.definedRuntime(externalClass.rtType.toString());
    }
    _externClasses[externalClass.id] = externalClass;
  }

  HTExternalClass fetchExternalClass(String id) {
    if (!_externClasses.containsKey(id)) {
      throw HTError.undefinedExtern(id);
    }
    return _externClasses[id]!;
  }

  void bindExternalFunction(String id, Function function) {
    if (_externFuncs.containsKey(id)) {
      throw HTError.definedRuntime(id);
    }
    _externFuncs[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFuncs.containsKey(id)) {
      throw HTError.undefinedExtern(id);
    }
    return _externFuncs[id]!;
  }

  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function) {
    if (_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTError.definedRuntime(id);
    }
    _externFuncTypeUnwrappers[id] = function;
  }

  Function unwrapExternalFunctionType(String id, HTFunction function) {
    if (!_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTError.undefinedExtern(id);
    }
    final unwrapFunc = _externFuncTypeUnwrappers[id]!;
    return unwrapFunc(function);
  }
}
