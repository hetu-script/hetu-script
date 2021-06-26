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
import '../scanner/parser.dart';
import 'compiler.dart';

/// Mixin for classes want to use a shared interpreter referrence.
mixin InterpreterRef {
  late final AbstractInterpreter interpreter;
}

class InterpreterConfig implements ParserConfig, CompilerConfig {
  @override
  final SourceType sourceType;

  @override
  final bool reload;

  @override
  final bool lineInfo;

  final bool scriptStackTrace;
  final int scriptStackTraceThreshhold;
  final bool externalStackTrace;

  const InterpreterConfig(
      {this.sourceType = SourceType.module,
      this.reload = false,
      this.lineInfo = true,
      this.scriptStackTrace = true,
      this.scriptStackTraceThreshhold = 10,
      this.externalStackTrace = true});
}

/// Base class for bytecode interpreter and static analyzer of Hetu.
abstract class AbstractInterpreter {
  static final version = Version(0, 1, 0);
  static const _anonymousScriptSignatureLength = 72;

  final scriptStackTrace = <String>[];

  InterpreterConfig config;

  InterpreterConfig get curConfig => config;

  /// Current line number of execution.
  int get curLine;

  /// Current column number of execution.
  int get curColumn;

  HTNamespace get curNamespace;

  String get curModuleFullName;

  HTLibrary get curLibrary;

  HTErrorHandler errorHandler;

  HTSourceProvider sourceProvider;

  final HTNamespace global = HTNamespace(id: SemanticNames.global);

  AbstractInterpreter(
      {this.config = const InterpreterConfig(),
      HTErrorHandler? errorHandler,
      HTSourceProvider? sourceProvider})
      : errorHandler = errorHandler ?? DefaultErrorHandler(),
        sourceProvider = sourceProvider ?? DefaultSourceProvider();

  @mustCallSuper
  Future<void> init(
      {bool coreModule = true,
      List<HTExternalClass> externalClasses = const [],
      Map<String, Function> externalFunctions = const {},
      Map<String, HTExternalFunctionTypedef> externalFunctionTypedef =
          const {}}) async {
    try {
      // load classes and functions in core library.
      if (coreModule) {
        for (final file in coreModules.keys) {
          await eval(coreModules[file]!,
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
      handleError(error, dartStackTrace: stackTrace);
    }
  }

  Future<dynamic> evalSource(HTSource source,
      {HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  Future<dynamic> eval(String content,
      {String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    if (moduleFullName == null) {
      final sigBuilder = StringBuffer();
      sigBuilder.write('${SemanticNames.anonymousScript}: ');
      var firstLine = content.trimLeft().replaceAll(RegExp(r'\s'), '');
      sigBuilder.write(firstLine);
      sigBuilder.write(firstLine.substring(
          0, math.min(_anonymousScriptSignatureLength, firstLine.length)));
      if (firstLine.length > _anonymousScriptSignatureLength) {
        sigBuilder.write('...');
      }
      moduleFullName = sigBuilder.toString();
    }

    final source = HTSource(moduleFullName, content);

    return await evalSource(source,
        // when eval string, use current namespace by default
        namespace: namespace ?? curNamespace,
        config: config,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
        errorHandled: errorHandled);
  }

  /// 解析文件
  Future<dynamic> evalFile(String key,
      {bool useLastModuleFullName = false,
      bool reload = false,
      String? moduleFullName,
      String? libraryName,
      HTNamespace? namespace,
      InterpreterConfig? config,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) async {
    try {
      final fullName = sourceProvider.resolveFullName(key);

      if (reload || !sourceProvider.hasModule(fullName)) {
        final module = sourceProvider.getSourceSync(key,
            from: useLastModuleFullName
                ? curModuleFullName
                : sourceProvider.workingDirectory);

        final result = await evalSource(module,
            namespace: namespace,
            config: config,
            invokeFunc: invokeFunc,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs,
            errorHandled: true);

        return result;
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, dartStackTrace: stackTrace);
      }
    }
  }

  /// 调用一个全局函数或者类、对象上的函数
  dynamic invoke(String funcName,
      {String? classId,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {}

  /// Handle a error thrown by other funcion in Hetu.
  void handleError(Object error,
      {StackTrace? dartStackTrace, HTAstParser? parser, HTCompiler? compiler}) {
    final sb = StringBuffer();
    if (curConfig.scriptStackTrace) {
      if (scriptStackTrace.length > curConfig.scriptStackTraceThreshhold * 2) {
        for (var i = scriptStackTrace.length - 1;
            i >=
                scriptStackTrace.length -
                    1 -
                    curConfig.scriptStackTraceThreshhold;
            --i) {
          sb.writeln(
              '#${scriptStackTrace.length - 1 - i}\t${scriptStackTrace[i]}');
        }
        sb.writeln('...\n...');
        for (var i = curConfig.scriptStackTraceThreshhold - 1; i >= 0; --i) {
          sb.writeln(
              '#${scriptStackTrace.length - 1 - i}\t${scriptStackTrace[i]}');
        }
      } else {
        for (var i = scriptStackTrace.length - 1; i >= 0; --i) {
          sb.writeln(
              '#${scriptStackTrace.length - 1 - i}\t${scriptStackTrace[i]}');
        }
      }
      sb.writeln('Dart stack trace:\n$dartStackTrace');
    }
    final stackTraceString = sb.toString();

    if (error is HTError) {
      if (config.scriptStackTrace) {
        error.message =
            '${error.message}\nHetu stack trace:\n$stackTraceString';
      }
      if (error.type == ErrorType.syntacticError) {
        error.moduleFullName = parser!.curModuleFullName;
        error.line = parser.curLine;
        error.column = parser.curColumn;
      } else if (error.type == ErrorType.compileTimeError) {
        error.moduleFullName = compiler!.curModuleFullName;
        error.line = compiler.curLine;
        error.column = compiler.curColumn;
      } else {
        error.moduleFullName = curModuleFullName;
        error.line = curLine;
        error.column = curColumn;
      }
      errorHandler.handle(error);
    } else {
      var message = error.toString();
      if (config.scriptStackTrace) {
        message = '$message\nCall stack:\n$stackTraceString';
      }
      final hetuError = HTError(ErrorCode.extern, ErrorType.externalError,
          message: message,
          moduleFullName: curModuleFullName,
          line: curLine,
          column: curColumn);
      errorHandler.handle(hetuError);
    }
  }

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
