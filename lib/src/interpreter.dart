import 'package:pub_semver/pub_semver.dart';

import 'namespace.dart';
import 'common.dart';
import 'type.dart';
import 'hetu_lib.dart';
import 'extern_class.dart';
import 'errors.dart';
import 'extern_function.dart';
import 'function.dart';
import 'extern_object.dart';
import 'object.dart';
import 'plugin/moduleHandler.dart';
import 'plugin/errorHandler.dart';

mixin InterpreterRef {
  late final Interpreter interpreter;
}

abstract class Interpreter {
  final version = Version(0, 1, 0);

  int get curLine;
  int get curColumn;
  String? get curModuleUniqueKey;

  String? get curSymbol;
  String? get curObjectSymbol;

  late bool debugMode;

  late HTErrorHandler errorHandler;
  late HTModuleHandler moduleHandler;

  /// 全局命名空间
  late HTNamespace global;

  Interpreter(
      {bool debugMode = false,
      HTErrorHandler? errorHandler,
      HTModuleHandler? moduleHandler}) {
    this.debugMode = debugMode;
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
      bindExternalClass(HTExternClassNumber());
      bindExternalClass(HTExternClassBool());
      bindExternalClass(HTExternClassString());
      bindExternalClass(HTExternClassMath());
      bindExternalClass(HTExternClassSystem(this));
      bindExternalClass(HTExternClassConsole());
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
      bool debugMode = true,
      HTNamespace? namespace,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []});

  /// 解析文件
  Future<dynamic> import(String key,
      {String? curModuleUniqueKey,
      String? moduleName,
      CodeType codeType = CodeType.module,
      bool debugMode = true,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []});

  /// 调用一个全局函数或者类、对象上的函数
  // TODO: 调用构造函数
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = false});

  void handleError(Object error, [StackTrace? stack]);

  HTObject encapsulate(dynamic object) {
    if (object is HTObject) {
      return object;
    } else if ((object == null) || (object is NullThrownError)) {
      return HTObject.NULL;
    } else if (object is num) {
      return HTNumber(object);
    } else if (object is bool) {
      return HTBoolean(object);
    } else if (object is String) {
      return HTString(object);
    } else if (object is List) {
      var valueType = HTTypeId.ANY;
      if (object.isNotEmpty) {
        valueType = encapsulate(object.first).typeid;
        for (final item in object) {
          final value = encapsulate(item).typeid;
          if (value.isNotA(valueType)) {
            valueType = HTTypeId.ANY;
            break;
          }
        }
      }

      return HTList(object, valueType: valueType);
    } else if (object is Map) {
      var keyType = HTTypeId.ANY;
      var valueType = HTTypeId.ANY;
      if (object.keys.isNotEmpty) {
        keyType = encapsulate(object.keys.first).typeid;
        for (final item in object.keys) {
          final value = encapsulate(item).typeid;
          if (value.isNotA(keyType)) {
            keyType = HTTypeId.ANY;
            break;
          }
        }
      }
      if (object.values.isNotEmpty) {
        valueType = encapsulate(object.values.first).typeid;
        for (final item in object.values) {
          final value = encapsulate(item).typeid;
          if (value.isNotA(valueType)) {
            valueType = HTTypeId.ANY;
            break;
          }
        }
      }

      return HTMap(object, keyType: keyType, valueType: valueType);
    } else {
      final typeString = object.runtimeType.toString();
      final id = HTTypeId.parseBaseTypeId(typeString);
      if (containsExternalClass(id)) {
        // try {
        // final externClass = fetchExternalClass(typeid.id);
        return HTExternObject(object, typeid: HTTypeId(id));
        // } on HTErrorUndefined {
        //   return HTExternObject(object);
        // }
      }

      return HTExternObject(object);
    }
  }

  // void defineGlobal(String key, {HTTypeId? declType, dynamic value, bool isImmutable = false}) {
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
    if (_externClasses.containsKey(externalClass.typeid)) {
      throw HTErrorDefinedRuntime(externalClass.typeid.toString());
    }
    _externClasses[externalClass.typename] = externalClass;
  }

  HTExternalClass fetchExternalClass(String id) {
    if (!_externClasses.containsKey(id)) {
      throw HTErrorUndefinedExtern(id);
    }
    return _externClasses[id]!;
  }

  void bindExternalFunction(String id, Function function) {
    if (_externFuncs.containsKey(id)) {
      throw HTErrorDefinedRuntime(id);
    }
    _externFuncs[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFuncs.containsKey(id)) {
      throw HTErrorUndefinedExtern(id);
    }
    return _externFuncs[id]!;
  }

  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function) {
    if (_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTErrorDefinedRuntime(id);
    }
    _externFuncTypeUnwrappers[id] = function;
  }

  Function unwrapExternalFunctionType(String id, HTFunction function) {
    if (!_externFuncTypeUnwrappers.containsKey(id)) {
      throw HTErrorUndefinedExtern(id);
    }
    final unwrapFunc = _externFuncTypeUnwrappers[id]!;
    return unwrapFunc(function);
  }
}
