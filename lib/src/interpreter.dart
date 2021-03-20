import 'lexicon.dart';
import 'namespace.dart';
import 'parser.dart' show ParseStyle;
import 'type.dart';
import 'plugin/importHandler.dart';
import 'plugin/errorHandler.dart';
import 'hetu_lib.dart';
import 'extern_class.dart';
import 'errors.dart';

mixin InterpreterRef {
  late final HTInterpreter interpreter;
}

abstract class HTInterpreter {
  late int curLine;
  late int curColumn;
  late String curFileName;

  late bool debugMode;

  late HTErrorHandler errorHandler;
  late HTImportHandler importHandler;

  /// 全局命名空间
  late HTNamespace globals;

  /// 当前语句所在的命名空间
  late HTNamespace curNamespace;

  HTInterpreter({bool debugMode = false, HTErrorHandler? errorHandler, HTImportHandler? importHandler}) {
    curNamespace = globals = HTNamespace(this, id: HTLexicon.global);
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
    ParseStyle style = ParseStyle.library,
    String? invokeFunc,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  });

  Future<dynamic> import(
    String fileName, {
    String? libName,
    ParseStyle style = ParseStyle.library,
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
    return globals.fetch(key);
  }

  final _externClasses = <String, HTExternalClass>{};
  final _externFunctions = <String, Function>{};

  bool containsExternalClass(String id) => _externClasses.containsKey(id);

  /// 注册外部类，以访问外部类的构造函数和static成员
  /// 在脚本中需要存在对应的extern class声明
  void bindExternalClass(String id, HTExternalClass namespace) {
    if (_externClasses.containsKey(id)) {
      throw HTErrorDefined_Runtime(id);
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
      throw HTErrorDefined_Runtime(id);
    }
    _externFunctions[id] = function;
  }

  Function fetchExternalFunction(String id) {
    if (!_externFunctions.containsKey(id)) {
      throw HTErrorUndefined(id);
    }
    return _externFunctions[id]!;
  }

  void bindExternalVariable(String id, Function getter, Function setter) {
    if (_externFunctions.containsKey(HTLexicon.getter + id) || _externFunctions.containsKey(HTLexicon.setter + id)) {
      throw HTErrorDefined_Runtime(id);
    }
    _externFunctions[HTLexicon.getter + id] = getter;
    _externFunctions[HTLexicon.setter + id] = setter;
  }

  dynamic getExternalVariable(String id) {
    if (!_externFunctions.containsKey(HTLexicon.getter + id)) {
      throw HTErrorUndefined(HTLexicon.getter + id);
    }
    final getter = _externFunctions[HTLexicon.getter + id]!;
    return getter(const [], const {});
  }

  void setExternalVariable(String id, value) {
    if (!_externFunctions.containsKey(HTLexicon.setter + id)) {
      throw HTErrorUndefined(HTLexicon.setter + id);
    }
    final setter = _externFunctions[HTLexicon.setter + id]!;
    return setter(const [], const {});
  }
}
