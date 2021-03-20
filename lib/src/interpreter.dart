import 'binding.dart';
import 'lexicon.dart';
import 'namespace.dart';
import 'parser.dart' show ParseStyle;
import 'type.dart';
import 'plugin/importHandler.dart';
import 'plugin/errorHandler.dart';
import 'core.dart';
import 'extern_class.dart';

mixin InterpreterRef {
  late final Interpreter interpreter;
}

abstract class Interpreter with BindingHandler {
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

  Interpreter({bool debugMode = false, HTErrorHandler? errorHandler, HTImportHandler? importHandler}) {
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
    for (final file in coreLibs.keys) {
      await eval(coreLibs[file]!);
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

  void defineGlobal(String key, {HTTypeId? declType, dynamic value, bool isImmutable = false}) {
    globals.define(key, declType: declType, value: value, isImmutable: isImmutable);
  }

  dynamic fetchGlobal(String key) {
    return globals.fetch(key);
  }
}
