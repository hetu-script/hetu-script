import 'lexicon.dart';
import 'namespace.dart';
import 'common.dart';
import 'type.dart';
import 'plugin/moduleHandler.dart';
import 'plugin/errorHandler.dart';
import 'hetu_lib.dart';
import 'extern_class.dart';
import 'errors.dart';
import 'extern_function.dart';
import 'object.dart';
import 'function.dart';
import 'class.dart';

mixin InterpreterRef {
  late final Interpreter interpreter;
}

abstract class Interpreter {
  late HTVersion scriptVersion;

  late int curLine;
  late int curColumn;
  late String curFileName;

  late bool debugMode;

  late HTErrorHandler errorHandler;
  late HTModuleHandler importHandler;

  /// 全局命名空间
  late HTNamespace global;

  /// 当前语句所在的命名空间
  late HTNamespace curNamespace;

  Interpreter({bool debugMode = false, HTErrorHandler? errorHandler, HTModuleHandler? importHandler}) {
    curNamespace = global = HTNamespace(this, id: HTLexicon.global);
    this.debugMode = debugMode;
    this.errorHandler = errorHandler ?? DefaultErrorHandler();
    this.importHandler = importHandler ?? DefaultModuleHandler();
  }

  Future<void> init(
      {Map<String, Function> externalFunctions = const {}, List<HTExternalClass> externalClasses = const []}) async {
    // load classes and functions in core library.
    // TODO: dynamic load needed core lib in script
    for (final file in coreModules.keys) {
      await eval(coreModules[file]!, fileName: file);
    }

    for (var key in HTExternalFunctions.functions.keys) {
      bindExternalFunction(key, HTExternalFunctions.functions[key]!);
    }

    bindExternalClass(HTExternClassNumber());
    bindExternalClass(HTExternClassBool());
    bindExternalClass(HTExternClassString());
    bindExternalClass(HTExternClassMath());
    bindExternalClass(HTExternClassSystem(this));
    bindExternalClass(HTExternClassConsole());

    for (var key in externalFunctions.keys) {
      bindExternalFunction(key, externalFunctions[key]!);
    }

    for (var value in externalClasses) {
      bindExternalClass(value);
    }
  }

  Future<dynamic> eval(
    String content, {
    String? fileName,
    String libName = HTLexicon.global,
    HTNamespace? namespace,
    ParseStyle style = ParseStyle.module,
    bool debugMode = false,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  Future<dynamic> import(
    String fileName, {
    String? libName,
    ParseStyle style = ParseStyle.module,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  /// Call a Hetu function or a Dart function,
  /// use several different implements according to the callee type.
  dynamic call(dynamic callee,
      [List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []]) {
    if (callee is HTFunction) {
      if (!callee.isExtern) {
        // 普通函数
        if (callee.funcType != FunctionType.constructor) {
          return callee.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
        } else {
          final className = callee.className;
          final klass = global.fetch(className!);
          if (klass is HTClass) {
            if (klass.classType != ClassType.extern) {
              // 命名构造函数
              return klass.createInstance(
                  constructorName: callee.id, positionalArgs: positionalArgs, namedArgs: namedArgs);
            } else {
              // 外部命名构造函数
              final externClass = fetchExternalClass(className);
              final constructor = externClass.fetch(callee.id);
              if (constructor is HTExternalFunction) {
                try {
                  return constructor(positionalArgs, namedArgs);
                } on RangeError {
                  throw HTErrorExternParams();
                }
              } else {
                return Function.apply(
                    constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
                // throw HTErrorExternFunc(constructor.toString());
              }
            }
          } else {
            throw HTErrorCallable(callee.toString());
          }
        }
      } else {
        final externFunc = fetchExternalFunction(callee.id);
        if (externFunc is HTExternalFunction) {
          try {
            return externFunc(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          return Function.apply(
              externFunc, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
    } else if (callee is HTClass) {
      if (callee.classType != ClassType.extern) {
        // 默认构造函数
        return callee.createInstance(positionalArgs: positionalArgs, namedArgs: namedArgs);
      } else {
        // 外部默认构造函数
        final externClass = fetchExternalClass(callee.id);
        final constructor = externClass.fetch(callee.id);
        if (constructor is HTExternalFunction) {
          try {
            return constructor(positionalArgs, namedArgs);
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          return Function.apply(
              constructor, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
    } // 外部函数
    else if (callee is Function) {
      if (callee is HTExternalFunction) {
        try {
          return callee(positionalArgs, namedArgs);
        } on RangeError {
          throw HTErrorExternParams();
        }
      } else {
        return Function.apply(callee, positionalArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        // throw HTErrorExternFunc(callee.toString());
      }
    } else {
      throw HTErrorCallable(callee.toString());
    }
  }

  /// 调用一个全局函数或者类、对象上的函数
  // TODO: 调用构造函数
  dynamic invoke(String functionName,
      {String? objectName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    var func;
    if (objectName == null) {
      func = global.fetch(functionName);
    } else {
      // 命名空间内的静态函数
      HTObject object = global.fetch(objectName);
      func = object.fetch(functionName, from: object.fullName);
    }

    return call(func, positionalArgs, namedArgs, typeArgs);
  }

  HTTypeId typeof(dynamic object);

  // void defineGlobal(String key, {HTTypeId? declType, dynamic value, bool isImmutable = false}) {
  //   globals.define(key, declType: declType, value: value, isImmutable: isImmutable);
  // }

  dynamic fetchGlobal(String key) {
    return global.fetch(key);
  }

  final _externClasses = <String, HTExternalClass>{};
  final _externFunctions = <String, Function>{};

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
}
