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
import '../preincludes/preinclude_functions.dart';
import '../preincludes/preinclude_module.dart';
import '../locale/locale.dart';
import '../external/external_function.dart';
import '../external/external_class.dart';
import '../binding/class_binding.dart';
import '../binding/hetu_binding.dart';
import '../lexer/lexicon2.dart';
import '../lexer/lexicon_default_impl.dart';
import '../parser/parser.dart';
import '../parser/parser_default_impl.dart';
import '../resource/resource.dart';
import '../bundler/bundler.dart';

/// A wrapper class for sourceContext, analyzer, compiler and interpreter to work together.
class Hetu {
  InterpreterConfig config;

  final HTResourceContext<HTSource> sourceContext;

  late final HTLexicon lexicon;

  final Map<String, HTParser> _parsers = {};

  late HTParser _currentParser;

  HTParser get parser => _currentParser;

  late final HTAnalyzer analyzer;

  late final HTCompiler compiler;

  late final HTInterpreter interpreter;

  bool _isInitted = false;
  bool get isInitted => _isInitted;

  Hetu(
      {InterpreterConfig? config,
      HTResourceContext<HTSource>? sourceContext,
      HTLexicon? lexicon,
      String parserName = 'default',
      HTParser? parser})
      : config = config ?? InterpreterConfig(),
        sourceContext = sourceContext ?? HTOverlayContext(),
        lexicon = lexicon ?? HTDefaultLexicon(),
        _currentParser = parser ?? HTDefaultParser() {
    _parsers[parserName] = _currentParser;
    analyzer =
        HTAnalyzer(config: this.config, sourceContext: this.sourceContext);
    compiler = HTCompiler(config: this.config, lexicon: this.lexicon);
    interpreter = HTInterpreter(
        config: this.config,
        sourceContext: this.sourceContext,
        lexicon: this.lexicon);
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
    }

    for (final key in externalFunctions.keys) {
      interpreter.bindExternalFunction(key, externalFunctions[key]!);
    }
    for (final key in externalFunctionTypedef.keys) {
      interpreter.bindExternalFunctionType(key, externalFunctionTypedef[key]!);
    }
    for (final value in externalClasses) {
      interpreter.bindExternalClass(value);
    }
    interpreter.invoke('initHetuEnv', positionalArgs: [this]);
    _isInitted = true;
  }

  void setParser(String name) {
    assert(_parsers.containsKey(name));
    _currentParser = _parsers[name]!;
  }

  /// Evaluate a string content.
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  dynamic eval(String content,
      {String? fileName,
      String? moduleName,
      bool globallyImport = false,
      HTResourceType type = HTResourceType.hetuLiteralCode,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final source = HTSource(content, fullName: fileName, type: type);
    final result = _evalSource(source,
        moduleName: moduleName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);
    return result;
  }

  /// Evaluate a file, [key] is a possibly relative path,
  /// file content will be searched by [sourceContext].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  dynamic evalFile(String key,
      {String? moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final source = sourceContext.getResource(key);
    final result = _evalSource(source,
        moduleName: moduleName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);
    return result;
  }

  dynamic _evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    if (source.content.isEmpty) {
      return null;
    }
    final bytes = _compileSource(
      source,
      moduleName: moduleName,
      config: config,
    );
    final result = interpreter.loadBytecode(
        bytes: bytes,
        moduleName: moduleName ?? source.fullName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);
    return result;
  }

  Uint8List compile(String content,
      {String? filename,
      String? moduleName,
      CompilerConfig? config,
      bool isModuleEntryScript = false}) {
    final source = HTSource(content,
        fullName: filename,
        type: isModuleEntryScript
            ? HTResourceType.hetuScript
            : HTResourceType.hetuModule);
    final result = _compileSource(source, moduleName: moduleName);
    return result;
  }

  /// Compile a script content into bytecode for later use.
  Uint8List compileFile(String key,
      {String? moduleName, CompilerConfig? config}) {
    final source = sourceContext.getResource(key);
    final bytes =
        _compileSource(source, moduleName: moduleName, config: config);
    return bytes;
  }

  /// Compile a [HTSource] into bytecode for later use.
  Uint8List _compileSource(HTSource source,
      {String? moduleName, CompilerConfig? config, bool errorHandled = false}) {
    try {
      final bundler = HTBundler(sourceContext: sourceContext);
      final compilation =
          bundler.bundle(source: source, parser: _currentParser);
      final result = analyzer.analyzeASTCompilation(compilation);
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

  dynamic run(
      {required Uint8List bytes,
      required String moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    interpreter.loadBytecode(
        bytes: bytes,
        moduleName: moduleName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);
  }
}
