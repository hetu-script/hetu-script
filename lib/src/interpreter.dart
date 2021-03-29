import 'lexicon.dart';
import 'namespace.dart';
import 'common.dart';
import 'type.dart';
import 'hetu_lib.dart';
import 'extern_class.dart';
import 'errors.dart';
import 'extern_function.dart';
import 'function.dart';
import 'class.dart';
import 'declaration.dart';
import 'plugin/moduleHandler.dart';
import 'plugin/errorHandler.dart';

mixin InterpreterRef {
  late final Interpreter interpreter;
}

abstract class Interpreter {
  late HTVersion scriptVersion;

  int get curLine;
  int get curColumn;
  String get curModuleName;

  late bool debugMode;

  late HTErrorHandler errorHandler;
  late HTModuleHandler moduleHandler;

  /// 全局命名空间
  late HTNamespace global;

  /// 当前语句所在的命名空间
  HTNamespace get curNamespace;

  Interpreter({bool debugMode = false, HTErrorHandler? errorHandler, HTModuleHandler? moduleHandler}) {
    this.debugMode = debugMode;
    this.errorHandler = errorHandler ?? DefaultErrorHandler();
    this.moduleHandler = moduleHandler ?? DefaultModuleHandler();
  }

  Future<void> init(
      {bool coreModule = true,
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {}}) async {
    // load classes and functions in core library.
    // TODO: dynamic load needed core lib in script
    if (coreModule) {
      for (final file in coreModules.keys) {
        await eval(coreModules[file]!, moduleName: file);
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
      {String? moduleName,
      ParseStyle style = ParseStyle.module,
      bool debugMode = true,
      HTNamespace? namespace,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []});

  /// 解析文件
  Future<dynamic> import(String key,
      {String? moduleName,
      ParseStyle style = ParseStyle.module,
      bool debugMode = true,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) async {
    dynamic result;

    final module =
        await moduleHandler.import(key, !curModuleName.startsWith(HTLexicon.anonymousScript) ? curModuleName : null);

    if (module.duplicate) return;

    HTNamespace? library_namespace;
    if ((moduleName != null) && (moduleName != HTLexicon.global)) {
      library_namespace = HTNamespace(this, id: moduleName, closure: global);
      global.define(HTDeclaration(moduleName, value: library_namespace));
    }

    result = await eval(module.content,
        moduleName: module.key,
        namespace: library_namespace,
        style: style,
        debugMode: debugMode,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);

    return result;
  }

  /// Call a Hetu function or a Dart function,
  /// use several different implements according to the callee type.
  dynamic call(dynamic callee,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      if (callee is HTFunction) {
        HTFunction.callStack.add('#${HTFunction.callStack.length} ${callee.id} - ($curModuleName:$curLine:$curColumn)');

        return callee.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
      } // 外部函数
      else if (callee is Function) {
        if (callee is HTExternalFunction) {
          return callee(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
        } else {
          return Function.apply(callee, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(callee.toString());
        }
      } else if (callee is HTClass) {
        if (callee.classType != ClassType.extern) {
          // 默认构造函数
          return callee.createInstance(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
        } else {
          // 外部默认构造函数
          final externClass = fetchExternalClass(callee.id);
          final constructor = externClass.memberGet(callee.id);
          if (constructor is HTExternalFunction) {
            return constructor(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
          } else {
            return Function.apply(
                constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
            // throw HTErrorExternFunc(constructor.toString());
          }
        }
      } else {
        throw HTErrorCallable(callee.toString());
      }
    } catch (e, stack) {
      if (!errorHandled) {
        var sb = StringBuffer();
        for (var funcName in HTFunction.callStack) {
          sb.writeln('  $funcName');
        }
        sb.writeln('\n$stack');
        var callStack = sb.toString();

        if (e is! HTInterpreterError) {
          HTInterpreterError newErr;
          if (e is HTError) {
            newErr = HTInterpreterError(
                '${e.message}\nHetu call stack:\n$callStack', e.type, curModuleName, curLine, curColumn);
          } else {
            newErr = HTInterpreterError(
                '$e\nHetu call stack:\n$callStack', HTErrorType.other, curModuleName, curLine, curColumn);
          }

          errorHandler.handle(newErr);
        } else {
          errorHandler.handle(e);
        }
      } else {
        rethrow;
      }
    }
  }

  /// 调用一个全局函数或者类、对象上的函数
  // TODO: 调用构造函数
  dynamic invoke(String funcName,
      {String? className,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = false});

  HTTypeId typeof(dynamic object) {
    if ((object == null) || (object is NullThrownError)) {
      return HTTypeId.NULL;
    } // Class, Object, external class
    else if (object is HTType) {
      return object.typeid;
    } else if (object is num) {
      return HTTypeId.number;
    } else if (object is bool) {
      return HTTypeId.boolean;
    } else if (object is String) {
      return HTTypeId.string;
    } else if (object is List) {
      var valType = HTTypeId.ANY;
      if (object.isNotEmpty) {
        valType = typeof(object.first);
        for (final item in object) {
          if (typeof(item) != valType) {
            valType = HTTypeId.ANY;
            break;
          }
        }
      }

      return HTTypeId(HTLexicon.list, arguments: [valType]);
    } else if (object is Map) {
      var keyType = HTTypeId.ANY;
      var valType = HTTypeId.ANY;
      if (object.keys.isNotEmpty) {
        keyType = typeof(object.keys.first);
        for (final key in object.keys) {
          if (typeof(key) != keyType) {
            keyType = HTTypeId.ANY;
            break;
          }
        }
      }
      if (object.values.isNotEmpty) {
        valType = typeof(object.values.first);
        for (final value in object.values) {
          if (typeof(value) != valType) {
            valType = HTTypeId.ANY;
            break;
          }
        }
      }
      return HTTypeId(HTLexicon.map, arguments: [keyType, valType]);
    } else {
      var typeid = object.runtimeType.toString();
      if (typeid.contains('<')) {
        typeid = typeid.substring(0, typeid.indexOf('<'));
      }
      if (containsExternalClass(typeid)) {
        final externClass = fetchExternalClass(typeid);
        return HTTypeId(externClass.id);
      }
      return HTTypeId.unknown;
    }
  }

  // void defineGlobal(String key, {HTTypeId? declType, dynamic value, bool isImmutable = false}) {
  //   globals.define(key, declType: declType, value: value, isImmutable: isImmutable);
  // }

  dynamic fetchGlobal(String key) {
    return global.memberGet(key);
  }

  final _externClasses = <String, HTExternalClass>{};
  final _externFunctions = <String, Function>{};
  final _externFunctionTypeUnwraps = <String, HTExternalFunctionTypedef>{};

  bool containsExternalClass(String id) => _externClasses.containsKey(id);

  /// 注册外部类，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalClass(HTExternalClass externalClass) {
    if (_externClasses.containsKey(externalClass.id)) {
      throw HTErrorDefinedRuntime(externalClass.id);
    }
    _externClasses[externalClass.id] = externalClass;
  }

  HTExternalClass fetchExternalClass(String id) {
    if (!_externClasses.containsKey(id)) {
      throw HTErrorUndefined(id);
    }
    return _externClasses[id]!;
  }

  void bindExternalFunction(String id, Function function) {
    if (_externFunctions.containsKey(id)) {
      throw HTErrorDefinedRuntime(id);
    }
    _externFunctions[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFunctions.containsKey(id)) {
      throw HTErrorUndefined(id);
    }
    return _externFunctions[id]!;
  }

  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function) {
    if (_externFunctionTypeUnwraps.containsKey(id)) {
      throw HTErrorDefinedRuntime(id);
    }
    _externFunctionTypeUnwraps[id] = function;
  }

  Function unwrapExternalFunctionType(String id, HTFunction function) {
    if (!_externFunctionTypeUnwraps.containsKey(id)) {
      throw HTErrorUndefined(id);
    }
    final unwrapFunc = _externFunctionTypeUnwraps[id]!;
    return unwrapFunc(function);
  }
}
