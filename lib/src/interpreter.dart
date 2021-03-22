import 'lexicon.dart';
import 'namespace.dart';
import 'common.dart';
import 'type.dart';
import 'plugin/importHandler.dart';
import 'plugin/errorHandler.dart';
import 'hetu_lib.dart';
import 'extern_class.dart';
import 'errors.dart';

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
  late HTImportHandler importHandler;

  /// 全局命名空间
  late HTNamespace global;

  /// 当前语句所在的命名空间
  late HTNamespace curNamespace;

  Interpreter({bool debugMode = false, HTErrorHandler? errorHandler, HTImportHandler? importHandler}) {
    curNamespace = global = HTNamespace(this, id: HTLexicon.global);
    this.debugMode = debugMode;
    this.errorHandler = errorHandler ?? DefaultErrorHandler();
    this.importHandler = importHandler ?? DefaultImportHandler();
  }

  Future<void> init(
      {Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalClass> externalClasses = const {}}) async {
    // load classes and functions in core library.
    // TODO: dynamic load needed core lib in script
    for (final file in coreModules.keys) {
      await eval(coreModules[file]!);
    }

    for (var key in HTExternGlobal.functions.keys) {
      bindExternalFunction(key, HTExternGlobal.functions[key]!);
    }

    bindExternalClass(HTExternGlobal.number, HTExternClassNumber());
    bindExternalClass(HTExternGlobal.boolean, HTExternClassBool());
    bindExternalClass(HTExternGlobal.string, HTExternClassString());
    bindExternalClass(HTExternGlobal.list, HTExternClassString());
    bindExternalClass(HTExternGlobal.map, HTExternClassString());
    bindExternalClass(HTExternGlobal.math, HTExternClassMath());
    bindExternalClass(HTExternGlobal.system, HTExternClassSystem(this));
    bindExternalClass(HTExternGlobal.console, HTExternClassConsole());

    for (var key in externalFunctions.keys) {
      bindExternalFunction(key, externalFunctions[key]!);
    }

    for (var key in externalClasses.keys) {
      bindExternalClass(key, externalClasses[key]!);
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
  void bindExternalClass(String id, HTExternalClass namespace) {
    if (_externClasses.containsKey(id)) {
      throw HTErrorDefinedRuntime(id);
    }
    _externClasses[id] = namespace;
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
