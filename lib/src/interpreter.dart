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
      await eval(coreModules[file]!);
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

  dynamic invoke(String functionName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}});

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
