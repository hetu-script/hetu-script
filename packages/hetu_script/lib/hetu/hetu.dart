import 'dart:typed_data';

import '../analyzer/analyzer.dart';
import '../interpreter/interpreter.dart';
import '../resource/resource.dart' show HTResourceType;
import '../resource/resource_context.dart';
import '../resource/overlay/overlay_context.dart';
import '../type/type.dart';
import '../source/source.dart';
import '../bytecode/compiler.dart';
import '../error/error_severity.dart';
import '../parser.dart';
import '../preincludes/preinclude_functions.dart';
import '../preincludes/preinclude_module.dart';
import '../locale/locale.dart';
import '../binding/external_function.dart';
import '../binding/external_class.dart';

class Hetu {
  InterpreterConfig config;

  final HTResourceContext<HTSource> sourceContext;

  late final HTAnalyzer analyzer;

  late final HTCompiler compiler;

  late final HTInterpreter interpreter;

  bool _isInitted = false;
  bool get isInitted => _isInitted;

  Hetu({InterpreterConfig? config, HTResourceContext<HTSource>? sourceContext})
      : config = config ?? InterpreterConfig(),
        sourceContext = sourceContext ?? HTOverlayContext() {
    analyzer =
        HTAnalyzer(config: this.config, sourceContext: this.sourceContext);
    compiler = HTCompiler(config: this.config);
    interpreter =
        HTInterpreter(config: this.config, sourceContext: this.sourceContext);
  }

  /// Initialize the interpreter,
  /// prepare it with preincluded modules,
  /// bind it with HTExternalFunction, HTExternalFunctionTypedef, HTExternalClass, etc.
  void init({
    bool useDefaultModuleAndBinding = true,
    HTLocale? locale,
    Map<String, Function> externalFunctions = const {},
    Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
    List<HTExternalClass> externalClasses = const [],
  }) {
    if (_isInitted) return;
    try {
      if (locale != null) {
        HTLocale.current = locale;
      }

      if (useDefaultModuleAndBinding) {
        // bind externals before any eval
        for (var key in preincludeFunctions.keys) {
          interpreter.bindExternalFunction(key, preincludeFunctions[key]!);
        }
        interpreter.bindExternalClass(HTNumberClassBinding());
        interpreter.bindExternalClass(HTIntClassBinding());
        interpreter.bindExternalClass(HTBigIntClassBinding());
        interpreter.bindExternalClass(HTFloatClassBinding());
        interpreter.bindExternalClass(HTBooleanClassBinding());
        interpreter.bindExternalClass(HTStringClassBinding());
        interpreter.bindExternalClass(HTIteratorClassBinding());
        interpreter.bindExternalClass(HTIterableClassBinding());
        interpreter.bindExternalClass(HTListClassBinding());
        interpreter.bindExternalClass(HTSetClassBinding());
        interpreter.bindExternalClass(HTMapClassBinding());
        interpreter.bindExternalClass(HTMathClassBinding());
        interpreter.bindExternalClass(HTHashClassBinding());
        interpreter.bindExternalClass(HTSystemClassBinding());
        interpreter.bindExternalClass(HTFutureClassBinding());
        // bindExternalClass(HTConsoleClass());
        interpreter.bindExternalClass(HTHetuClassBinding());
        // load precompiled core module.
        final coreModule = Uint8List.fromList(hetuCoreModule);
        interpreter.loadBytecode(
            bytes: coreModule, moduleName: 'core', globallyImport: true);
        interpreter.invoke('setInterpreter', positionalArgs: [interpreter]);
      }

      for (final key in externalFunctions.keys) {
        interpreter.bindExternalFunction(key, externalFunctions[key]!);
      }
      for (final key in externalFunctionTypedef.keys) {
        interpreter.bindExternalFunctionType(
            key, externalFunctionTypedef[key]!);
      }
      for (final value in externalClasses) {
        interpreter.bindExternalClass(value);
      }
      _isInitted = true;
    } catch (error, stackTrace) {
      interpreter.handleError(error, externalStackTrace: stackTrace);
    }
  }

  /// Evaluate a literal string code
  dynamic eval(String content,
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

  /// Evaluate a string content.
  /// During this process, all declarations will
  /// be defined to current [HTNamespace].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  dynamic evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    if (source.content.isEmpty) {
      return null;
    }
    try {
      final bytes = compileSource(
        source,
        moduleName: moduleName,
        config: config,
        errorHandled: true,
      );
      final result = interpreter.loadBytecode(
          bytes: bytes,
          moduleName: moduleName ?? source.fullName,
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
        interpreter.handleError(error, externalStackTrace: stackTrace);
      }
    }
  }

  /// Evaluate a file, [key] is a possibly relative path,
  /// file content will be searched by [sourceContext].
  dynamic evalFile(String key,
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
        interpreter.handleError(error, externalStackTrace: stackTrace);
        return null;
      }
    }
  }

  Uint8List? compile(String content,
      {String? filename,
      String? moduleName,
      CompilerConfig? config,
      bool isModuleEntryScript = false}) {
    final source = HTSource(content,
        fullName: filename,
        type: isModuleEntryScript
            ? HTResourceType.hetuScript
            : HTResourceType.hetuModule);
    final result = compileSource(source, moduleName: moduleName);
    return result;
  }

  /// Compile a script content into bytecode for later use.
  Uint8List? compileFile(String key,
      {String? moduleName, CompilerConfig? config}) {
    final source = sourceContext.getResource(key);
    final bytes = compileSource(source, moduleName: moduleName, config: config);
    return bytes;
  }

  /// Compile a [HTSource] into bytecode for later use.
  Uint8List compileSource(HTSource source,
      {String? moduleName, CompilerConfig? config, bool errorHandled = false}) {
    try {
      final parser = HTParser(sourceContext: sourceContext);
      final compilation = parser.parseToModule(source);
      final result = analyzer.analyzeCompilation(compilation);
      if (result.errors.isNotEmpty) {
        for (final error in result.errors) {
          if (error.severity >= ErrorSeverity.error) {
            if (errorHandled) {
              throw error;
            } else {
              interpreter.handleError(error);
            }
          } else {
            print('${error.severity}: $error');
          }
        }
      }
      return compiler.compile(result.compilation);
    } catch (error) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error);
        return Uint8List.fromList([]);
      }
    }
  }
}
