import 'dart:typed_data';

import 'package:pub_semver/pub_semver.dart';

import '../version.dart';
import '../ast/ast.dart';
import '../value/namespace/namespace.dart';
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

/// The config of hetu environment, this implements all config of components used by this environment.
class HetuConfig
    implements ParserConfig, AnalyzerConfig, CompilerConfig, InterpreterConfig {
  /// defaults to `true`
  bool printPerformanceStatistics;

  /// defaults to `true`
  bool normalizeImportPath;

  /// defaults to `false`
  @override
  bool explicitEndOfStatement;

  /// defaults to `false`
  @override
  bool computeConstantExpression;

  /// defaults to `false`
  @override
  bool doStaticAnalysis;

  /// defaults to `false`
  @override
  bool removeLineInfo;

  /// defaults to `false`
  @override
  bool removeAssertion;

  /// defaults to `false`
  @override
  bool removeDocumentation;

  /// defaults to `false`
  @override
  bool showDartStackTrace;

  /// defaults to `false`
  @override
  bool showHetuStackTrace;

  /// defaults to `false`
  @override
  int stackTraceDisplayCountLimit;

  /// defaults to `true`
  @override
  bool processError;

  /// defaults to `true`
  @override
  bool allowVariableShadowing;

  /// defaults to `false`
  @override
  bool allowImplicitVariableDeclaration;

  /// defaults to `false`
  @override
  bool allowImplicitNullToZeroConversion;

  /// defaults to `false`
  @override
  bool allowImplicitEmptyValueToFalseConversion;

  HetuConfig({
    this.printPerformanceStatistics = true,
    this.normalizeImportPath = true,
    this.explicitEndOfStatement = false,
    this.doStaticAnalysis = false,
    this.computeConstantExpression = false,
    this.removeLineInfo = false,
    this.removeAssertion = false,
    this.removeDocumentation = false,
    this.showDartStackTrace = false,
    this.showHetuStackTrace = false,
    this.stackTraceDisplayCountLimit = 5,
    this.processError = true,
    this.allowVariableShadowing = true,
    this.allowImplicitVariableDeclaration = false,
    this.allowImplicitNullToZeroConversion = false,
    this.allowImplicitEmptyValueToFalseConversion = false,
  });
}

/// A wrapper class for sourceContext, lexicon, parser, bundler, analyzer, compiler and interpreter to make them work together.
class Hetu {
  HetuConfig config;

  Version? verison;

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
        sourceContext = sourceContext ?? HTOverlayContext() {
    _currentParser = parser ??
        HTDefaultParser(
          config: this.config,
        );
    bundler = HTBundler(
      sourceContext: this.sourceContext,
    );
    _parsers[parserName] = _currentParser;
    analyzer = HTAnalyzer(
      config: this.config,
      sourceContext: this.sourceContext,
    );
    compiler = HTCompiler(
      config: this.config,
      lexicon: this.lexicon,
    );
    interpreter = HTInterpreter(
      config: this.config,
      sourceContext: this.sourceContext,
      lexicon: this.lexicon,
    );
  }

  /// Initialize the interpreter,
  /// prepare it with preincluded modules,
  /// bind it with HTExternalFunction, HTExternalFunctionTypedef, HTExternalClass, etc.
  ///
  /// A uninitted Hetu can still eval certain script,
  /// it cannot use any of the pre-included functions like `print` and the Dart apis on number & string, etc.
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
      interpreter.loadBytecode(
        bytes: coreModule,
        moduleName: 'hetu',
        globallyImport: true,
        printPerformanceStatistics: config.printPerformanceStatistics,
      );

      interpreter.define('kHetuVersion', kHetuVersion.toString());

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

  /// Change the current parser.
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
    if (content.trim().isEmpty) return null;
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

  /// Evaluate a file.
  /// [key] is a possibly relative path.
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

  /// Evaluate a [HTSource].
  /// If [invokeFunc] is provided, will immediately
  /// call the function after evaluation completed.
  dynamic evalSource(HTSource source,
      {String? moduleName,
      bool globallyImport = false,
      String? invokeFunc,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    if (source.content.trim().isEmpty) {
      return null;
    }
    final bytes = _compileSource(source);
    final result = interpreter.loadBytecode(
      bytes: bytes,
      moduleName: moduleName ?? source.fullName,
      globallyImport: globallyImport,
      invokeFunc: invokeFunc,
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
      typeArgs: typeArgs,
      printPerformanceStatistics: config.printPerformanceStatistics,
    );
    return result;
  }

  /// Process the import declaration within several sources,
  /// generate a single [ASTCompilation] for [HTCompiler] to compile.
  ASTCompilation bundle(HTSource source,
      {Version? version, bool errorHandled = false}) {
    final compilation = bundler.bundle(
      source: source,
      parser: _currentParser,
      normalizePath: config.normalizeImportPath,
      printPerformanceStatistics: config.printPerformanceStatistics,
      version: version,
    );
    if (compilation.errors.isNotEmpty) {
      for (final error in compilation.errors) {
        if (errorHandled) {
          throw error;
        } else {
          interpreter.processError(error);
        }
      }
    }
    return compilation;
  }

  /// Compile a string into bytecode.
  /// This won't execute the code, so runtime errors will not be reported.
  Uint8List compile(
    String content, {
    String? sourceName,
    CompilerConfig? config,
    bool isModuleEntryScript = false,
    Version? version,
  }) {
    final source = HTSource(content,
        fullName: sourceName,
        type: isModuleEntryScript
            ? HTResourceType.hetuScript
            : HTResourceType.hetuModule);
    return _compileSource(
      source,
      version: version,
    );
  }

  /// Compile a source within current [sourceContext].
  /// This won't execute the code, so runtime errors will not be reported.
  Uint8List compileFile(
    String key, {
    CompilerConfig? config,
    Version? version,
  }) {
    final source = sourceContext.getResource(key);
    return _compileSource(
      source,
      version: version,
    );
  }

  /// Compile a [HTSource] into bytecode for later use.
  Uint8List _compileSource(
    HTSource source, {
    Version? version,
    bool errorHandled = false,
  }) {
    try {
      final compilation = bundle(
        source,
        version: version,
        errorHandled: true,
      );
      Uint8List bytes;
      if (config.doStaticAnalysis) {
        final result = analyzer.analyzeCompilation(
          compilation,
          printPerformanceStatistics: config.printPerformanceStatistics,
        );
        if (result.errors.isNotEmpty) {
          for (final error in result.errors) {
            if (error.severity >= ErrorSeverity.error) {
              if (errorHandled) {
                throw error;
              } else {
                interpreter.processError(error);
              }
            } else {
              print('hetu - ${error.severity}: $error');
            }
          }
        }
      }
      bytes = compiler.compile(
        compilation,
        printPerformanceStatistics: config.printPerformanceStatistics,
      );
      return bytes;
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
    final result = interpreter.loadBytecode(
      bytes: bytes,
      moduleName: moduleName,
      globallyImport: globallyImport,
      invokeFunc: invokeFunc,
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
      typeArgs: typeArgs,
      printPerformanceStatistics: config.printPerformanceStatistics,
    );
    if (config.doStaticAnalysis &&
        interpreter.currentBytecodeModule.namespaces.isNotEmpty) {
      analyzer.globalNamespace.import(
          interpreter.currentBytecodeModule.namespaces.values.last,
          idOnly: true);
    }
    return result;
  }

  /// Load a source into current bytecode dynamically.
  HTNamespace require(String path, [bool isScript = true]) {
    final key = config.normalizeImportPath
        ? sourceContext.getAbsolutePath(key: path)
        : path;

    // Search in current module first
    if (interpreter.currentBytecodeModule.namespaces.containsKey(key)) {
      return interpreter.currentBytecodeModule.namespaces[key]!;
    }

    // If the source is not in current module, then try to search it in any loaded modules.
    else {
      for (final module in interpreter.cachedModules.values) {
        for (final nsp in module.namespaces.values) {
          if (nsp.fullName == key) {
            return nsp;
          }
        }
      }
    }

    // If the source has not been evaled at all, then we have to load the source dynamically.
    final source = sourceContext.getResource(key);
    final bytes = _compileSource(source);
    final HTContext storedContext = interpreter.getContext();

    interpreter.loadBytecode(bytes: bytes, moduleName: key);

    final nsp = interpreter.currentBytecodeModule.namespaces.values.last;
    interpreter.setContext(context: storedContext);
    return nsp;
  }

  /// Add a declaration to certain namespace.
  bool define(
    String varName,
    dynamic value, {
    bool isMutable = false,
    bool override = false,
    bool throws = true,
    String? moduleName,
    String? sourceName,
  }) =>
      interpreter.define(
        varName,
        value,
        isMutable: isMutable,
        override: override,
        throws: throws,
        moduleName: moduleName,
      );

  /// Get the documentation of an identifier.
  String? help(
    dynamic id, {
    String? moduleName,
  }) =>
      interpreter.help(
        id,
        moduleName: moduleName,
      );

  /// Get a top level variable defined in a certain namespace in the interpreter.
  dynamic fetch(
    String varName, {
    String? moduleName,
  }) =>
      interpreter.fetch(
        varName,
        moduleName: moduleName,
      );

  /// Assign value to a top level variable defined in a certain namespace in the interpreter.
  void assign(
    String varName,
    dynamic value, {
    String? moduleName,
  }) =>
      interpreter.assign(
        varName,
        value,
        moduleName: moduleName,
      );

  /// Invoke a top level function defined in a certain namespace in the interpreter.
  dynamic invoke(String funcName,
          {String? moduleName,
          List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      interpreter.invoke(
        funcName,
        moduleName: moduleName,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
      );
}
