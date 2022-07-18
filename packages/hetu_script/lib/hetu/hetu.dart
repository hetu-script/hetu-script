import 'dart:typed_data';

import 'package:hetu_script/ast/ast.dart';
import 'package:hetu_script/declarations.dart';

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
import '../lexer/lexicon.dart';
import '../lexer/lexicon_default_impl.dart';
import '../parser/parser.dart';
import '../parser/parser_default_impl.dart';
import '../resource/resource.dart';
import '../bundler/bundler.dart';
import '../error/error_handler.dart';

class HetuConfig
    implements ParserConfig, AnalyzerConfig, CompilerConfig, InterpreterConfig {
  @override
  bool explicitEndOfStatement;

  @override
  bool computeConstantExpression;

  @override
  bool doStaticAnalysis;

  @override
  bool compileWithoutLineInfo;

  @override
  bool showDartStackTrace;

  @override
  bool showHetuStackTrace;

  @override
  int stackTraceDisplayCountLimit;

  @override
  bool processError;

  @override
  bool allowVariableShadowing;

  @override
  bool allowImplicitVariableDeclaration;

  @override
  bool allowImplicitNullToZeroConversion;

  @override
  bool allowImplicitEmptyValueToFalseConversion;

  bool normalizeImportPath;

  HetuConfig({
    this.explicitEndOfStatement = false,
    this.doStaticAnalysis = false,
    this.computeConstantExpression = false,
    this.compileWithoutLineInfo = false,
    this.showDartStackTrace = false,
    this.showHetuStackTrace = false,
    this.stackTraceDisplayCountLimit = kStackTraceDisplayCountLimit,
    this.processError = true,
    this.allowVariableShadowing = true,
    this.allowImplicitVariableDeclaration = false,
    this.allowImplicitNullToZeroConversion = false,
    this.allowImplicitEmptyValueToFalseConversion = false,
    this.normalizeImportPath = true,
  });
}

/// A wrapper class for sourceContext, lexicon, parser, bundler, analyzer, compiler and interpreter to make them work together.
class Hetu {
  HetuConfig config;

  final HTResourceContext<HTSource> sourceContext;

  late final HTLexicon lexicon;

  final Map<String, HTParser> _parsers = {};

  late HTParser _currentParser;

  HTParser get parser => _currentParser;

  late final HTBundler bundler;

  late final HTAnalyzer analyzer;

  late final HTCompiler compiler;

  late final HTInterpreter interpreter;

  bool _isInitted = false;
  bool get isInitted => _isInitted;

  /// Create a Hetu environment.
  Hetu(
      {HetuConfig? config,
      HTResourceContext<HTSource>? sourceContext,
      HTLexicon? lexicon,
      String parserName = 'default',
      HTParser? parser})
      : config = config ?? HetuConfig(),
        lexicon = lexicon ?? HTDefaultLexicon(),
        sourceContext = sourceContext ?? HTOverlayContext(),
        _currentParser = parser ?? HTDefaultParser() {
    bundler = HTBundler(sourceContext: this.sourceContext);
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
    List<HTExternalTypeReflection> externalTypeReflections = const [],
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
      interpreter.bindExternalClass(HTRandomClassBinding());
      interpreter.bindExternalClass(HTMathClassBinding());
      interpreter.bindExternalClass(HTHashClassBinding());
      interpreter.bindExternalClass(HTSystemClassBinding());
      interpreter.bindExternalClass(HTFutureClassBinding());
      // bindExternalClass(HTConsoleClass());
      interpreter.bindExternalClass(HTHetuClassBinding());
      // load precompiled core module.
      final coreModule = Uint8List.fromList(hetuCoreModule);
      loadBytecode(bytes: coreModule, moduleName: 'hetu', globallyImport: true);

      interpreter.invoke('initHetuEnv', positionalArgs: [this]);

      HTInterpreter.rootClass = interpreter.globalNamespace
          .memberGet(lexicon.globalObjectId, isRecursive: true);
      HTInterpreter.rootStruct = interpreter.globalNamespace
          .memberGet(lexicon.globalPrototypeId, isRecursive: true);
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
    for (final value in externalTypeReflections) {
      interpreter.bindExternalReflection(value);
    }
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
    final result = evalSource(source,
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
    final result = evalSource(source,
        moduleName: moduleName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);
    return result;
  }

  dynamic evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    if (source.content.isEmpty) {
      return null;
    }
    final bytes = _compileSource(source, moduleName: moduleName);
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
    return _compileSource(source, moduleName: moduleName);
  }

  /// Compile a script content into bytecode for later use.
  Uint8List compileFile(String key,
      {String? moduleName, CompilerConfig? config}) {
    final source = sourceContext.getResource(key);
    return _compileSource(source, moduleName: moduleName);
  }

  ASTCompilation bundle(HTSource source) {
    final compilation = bundler.bundle(
        source: source,
        parser: _currentParser,
        normalizePath: config.normalizeImportPath);
    return compilation;
  }

  /// Compile a [HTSource] into bytecode for later use.
  Uint8List _compileSource(HTSource source,
      {String? moduleName, bool errorHandled = false}) {
    try {
      final compilation = bundle(source);
      if (config.doStaticAnalysis) {
        final result = analyzer.analyzeCompilation(compilation);
        if (result.errors.isNotEmpty) {
          for (final error in result.errors) {
            if (error.severity >= ErrorSeverity.error) {
              if (errorHandled) {
                throw error;
              } else {
                interpreter.processError(error);
              }
            } else {
              print('${error.severity}: $error');
            }
          }
        }
        return compiler.compile(result.compilation);
      } else {
        if (compilation.errors.isNotEmpty) {
          for (final error in compilation.errors) {
            if (error.severity >= ErrorSeverity.error) {
              if (errorHandled) {
                throw error;
              } else {
                interpreter.processError(error);
              }
            } else {
              print('${error.severity}: $error');
            }
          }
        }
        return compiler.compile(compilation);
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.processError(error, stackTrace);
        return Uint8List.fromList([]);
      }
    }
  }

  /// Load a bytecode module and immediately run a function in it.
  dynamic loadBytecode(
      {required Uint8List bytes,
      required String moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    interpreter.loadBytecode(
        bytes: bytes,
        moduleName: moduleName,
        globallyImport: globallyImport,
        invokeFunc: invokeFunc,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);
    if (interpreter.currentBytecodeModule.namespaces.isNotEmpty) {
      analyzer.globalNamespace.import(
          interpreter.currentBytecodeModule.namespaces.values.last,
          idOnly: true);
    }
  }

  /// Load a source into current bytecode dynamically.
  HTNamespace require(String path) {
    final key = config.normalizeImportPath
        ? sourceContext.getAbsolutePath(key: path)
        : path;

    // Search in current module first
    if (interpreter.currentBytecodeModule.namespaces.containsKey(key)) {
      return interpreter.currentBytecodeModule.namespaces[key]!;
    }
    // Then try to search it in any loaded modules.
    else {
      for (final module in interpreter.cachedModules.values) {
        for (final nsp in module.namespaces.values) {
          if (nsp.fullName == key) {
            return nsp;
          }
        }
      }
    }

    // Then we have to load the source dynamically
    final source = sourceContext.getResource(key);
    // Because we are loading it dynamically, it has to be a script rather than a module.
    source.type = HTResourceType.hetuScript;
    final bytes = _compileSource(source, moduleName: key);
    final HTContext storedContext = interpreter.getContext();
    interpreter.loadBytecode(bytes: bytes, moduleName: key);
    final nsp = interpreter.currentBytecodeModule.namespaces.values.last;
    interpreter.setContext(context: storedContext);
    return nsp;
  }

  dynamic invoke(String funcName,
          {String? moduleName,
          String? sourceName,
          List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      interpreter.invoke(
        funcName,
        moduleName: moduleName,
        sourceName: sourceName,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
      );
}
