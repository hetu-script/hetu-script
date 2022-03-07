import 'package:meta/meta.dart';
import 'package:characters/characters.dart';

import 'dart:math' as math;

import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../binding/external_class.dart';
import '../binding/external_function.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../grammar/lexicon.dart';
import '../type/type.dart';
import '../value/function/function.dart';
import '../parser/abstract_parser.dart';
import '../value/entity.dart';
import '../bytecode/compiler.dart';
import '../shared/stringify.dart';
import '../shared/jsonify.dart';
import 'preincludes/preinclude_functions.dart';
import '../shared/gaussian_noise.dart';
import '../shared/perlin_noise.dart';
import '../shared/math.dart';
import '../shared/uid.dart';
import '../shared/crc32b.dart';
import '../analyzer/analyzer.dart';

part 'binding/class_binding.dart';
part 'binding/instance_binding.dart';

/// Mixin for classes want to use a shared interpreter referrence.
mixin InterpreterRef {
  late final HTAbstractInterpreter interpreter;
}

class InterpreterConfig
    implements
        ParserConfig,
        AnalyzerConfig,
        CompilerConfig,
        ErrorHandlerConfig {
  @override
  final bool checkTypeErrors;

  @override
  final bool computeConstantExpressionValue;

  @override
  final bool compileWithLineInfo;

  @override
  final bool showHetuStackTrace;

  @override
  final bool showDartStackTrace;

  @override
  final int stackTraceDisplayCountLimit;

  @override
  final ErrorHanldeApproach errorHanldeApproach;

  final bool allowHotReload;

  const InterpreterConfig(
      {this.checkTypeErrors = false,
      this.computeConstantExpressionValue = false,
      this.compileWithLineInfo = true,
      this.showHetuStackTrace = true,
      this.showDartStackTrace = false,
      this.stackTraceDisplayCountLimit = kStackTraceDisplayCountLimit,
      this.errorHanldeApproach = ErrorHanldeApproach.exception,
      this.allowHotReload = true});
}

/// Base class for bytecode interpreter and static analyzer of Hetu.
///
/// Each instance of a interpreter has a independent global [HTNamespace].
abstract class HTAbstractInterpreter<T> implements HTErrorHandler {
  /// [HTResourceContext] manages imported sources.
  HTResourceContext<HTSource> get sourceContext;

  bool strictMode = false;

  /// Initialize the interpreter,
  /// prepare it with preincluded modules,
  /// bind it with HTExternalFunction, HTExternalFunctionTypedef, HTExternalClass, etc.
  @mustCallSuper
  void init({
    Map<String, Function> externalFunctions = const {},
    Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
    List<HTExternalClass> externalClasses = const [],
  }) {
    try {
      // bind externals before any eval
      for (var key in preincludeFunctions.keys) {
        bindExternalFunction(key, preincludeFunctions[key]!);
      }
      bindExternalClass(HTNumberClassBinding());
      bindExternalClass(HTIntClassBinding());
      bindExternalClass(HTBigIntClassBinding());
      bindExternalClass(HTFloatClassBinding());
      bindExternalClass(HTBooleanClassBinding());
      bindExternalClass(HTStringClassBinding());
      bindExternalClass(HTIteratorClassBinding());
      bindExternalClass(HTIterableClassBinding());
      bindExternalClass(HTListClassBinding());
      bindExternalClass(HTSetClassBinding());
      bindExternalClass(HTMapClassBinding());
      bindExternalClass(HTMathClassBinding());
      bindExternalClass(HTHashClassBinding());
      bindExternalClass(HTSystemClassBinding());
      bindExternalClass(HTFutureClassBinding());
      // bindExternalClass(HTConsoleClass());

      for (final key in externalFunctions.keys) {
        bindExternalFunction(key, externalFunctions[key]!);
      }
      for (final key in externalFunctionTypedef.keys) {
        bindExternalFunctionType(key, externalFunctionTypedef[key]!);
      }
      for (final value in externalClasses) {
        bindExternalClass(value);
      }
    } catch (error, stackTrace) {
      handleError(error, externalStackTrace: stackTrace);
    }
  }

  /// Evaluate a [HTSource].
  T? evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false});

  /// Evaluate a literal string code
  T? eval(String content,
      {String? fileName,
      String? moduleName,
      bool globallyImport = false,
      HTResourceType type = HTResourceType.hetuLiteralCode,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    final source = HTSource(content, fullName: fileName, type: type);
    final result = evalSource(source,
        moduleName: moduleName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
        errorHandled: errorHandled);
    return result;
  }

  /// Evaluate a file, [key] is a possibly relative path,
  /// file content will be searched by [sourceContext].
  T? evalFile(String key,
      {String? moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      final source = sourceContext.getResource(key);
      final result = evalSource(source,
          moduleName: moduleName,
          globallyImport: globallyImport,
          invokeFunc: invokeFunc,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs,
          errorHandled: true);
      return result;
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        handleError(error, externalStackTrace: stackTrace);
        return null;
      }
    }
  }

  /// Invoke a function in global namespace by its name.
  dynamic invoke(String funcName,
      {String? moduleName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {}

  final externClasses = <String, HTExternalClass>{};
  final externTypeReflection = <HTExternalTypeReflection>[];
  final externFuncs = <String, Function>{};
  final externFuncTypeUnwrappers = <String, HTExternalFunctionTypedef>{};

  /// Wether the interpreter has a certain external class binding.
  bool containsExternalClass(String id) => externClasses.containsKey(id);

  /// Register a external class into scrfipt.
  /// For acessing static members and constructors of this class,
  /// there must also be a declaraction in script
  void bindExternalClass(HTExternalClass externalClass,
      {bool override = false}) {
    if (externClasses.containsKey(externalClass.valueType) && !override) {
      throw HTError.definedRuntime(externalClass.valueType.toString());
    }
    externClasses[externalClass.id] = externalClass;
  }

  /// Fetch a external class instance
  HTExternalClass fetchExternalClass(String id) {
    if (!externClasses.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externClasses[id]!;
  }

  /// Bind a external class name to a abstract class name for interpreter get dart class name by reflection
  void bindExternalReflection(HTExternalTypeReflection reflection) {
    externTypeReflection.add(reflection);
  }

  /// Register a external function into scrfipt
  /// there must be a declaraction also in script for using this
  void bindExternalFunction(String id, Function function,
      {bool override = false}) {
    if (externFuncs.containsKey(id) && !override) {
      throw HTError.definedRuntime(id);
    }
    externFuncs[id] = function;
  }

  /// Fetch a external function
  Function fetchExternalFunction(String id) {
    if (!externFuncs.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externFuncs[id]!;
  }

  /// Register a external function typedef into scrfipt
  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function,
      {bool override = false}) {
    if (externFuncTypeUnwrappers.containsKey(id) && !override) {
      throw HTError.definedRuntime(id);
    }
    externFuncTypeUnwrappers[id] = function;
  }

  /// Using unwrapper to turn a script function into a external function
  Function unwrapExternalFunctionType(HTFunction func) {
    if (!externFuncTypeUnwrappers.containsKey(func.externalTypeId)) {
      throw HTError.undefinedExternal(func.externalTypeId!);
    }
    final unwrapFunc = externFuncTypeUnwrappers[func.externalTypeId]!;
    return unwrapFunc(func);
  }
}
