import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:hetu_script/declaration/declaration.dart';
import 'package:hetu_script/declaration/variable/variable_declaration.dart';
import 'package:hetu_script/value/instance/instance.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

import '../value/class/class_namespace.dart';
import '../value/namespace/namespace.dart';
import '../value/struct/named_struct.dart';
import '../value/object.dart';
import '../value/class/class.dart';
import '../value/instance/cast.dart';
import '../value/function/function.dart';
import '../value/function/parameter.dart';
import '../value/variable/variable.dart';
import '../value/struct/struct.dart';
import '../value/external_enum/external_enum.dart';
import '../value/constant.dart';
import '../external/external_class.dart';
import '../external/external_function.dart';
import '../external/external_instance.dart';
import '../type/type.dart';
import '../type/function.dart';
import '../type/nominal.dart';
import '../type/structural.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../source/source.dart';
import '../resource/resource.dart';
import '../resource/resource_context.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../bytecode/op_code.dart';
import '../bytecode/bytecode_module.dart';
import '../bytecode/compiler.dart';
import '../version.dart';
import '../value/unresolved_import.dart';
import '../locale/locale.dart';
import '../common/internal_identifier.dart';
import '../common/function_category.dart';

const kConsoleColorYellow = '\x1B[33m';

/// Mixin for classes that want to hold a ref of a bytecode interpreter
mixin InterpreterRef {
  late final HTInterpreter interpreter;
}

/// Collection of config of bytecode interpreter.
class InterpreterConfig implements ErrorHandlerConfig {
  @override
  bool showDartStackTrace;

  @override
  bool showHetuStackTrace;

  @override
  int stackTraceDisplayCountLimit;

  @override
  bool processError;

  @override
  bool debugMode;

  bool allowVariableShadowing;

  bool allowImplicitVariableDeclaration;

  bool allowImplicitNullToZeroConversion;

  bool allowImplicitEmptyValueToFalseConversion;

  bool allowInitializationExpresssionHaveValue;

  bool printPerformanceStatistics;

  bool checkTypeAnnotationAtRuntime;

  bool resolveExternalFunctionsDynamically;

  InterpreterConfig({
    this.showDartStackTrace = false,
    this.showHetuStackTrace = false,
    this.stackTraceDisplayCountLimit = 5,
    this.processError = true,
    this.debugMode = false,
    this.allowVariableShadowing = true,
    this.allowImplicitVariableDeclaration = false,
    this.allowImplicitNullToZeroConversion = false,
    this.allowImplicitEmptyValueToFalseConversion = false,
    this.allowInitializationExpresssionHaveValue = false,
    this.printPerformanceStatistics = false,
    this.checkTypeAnnotationAtRuntime = false,
    this.resolveExternalFunctionsDynamically = false,
  });
}

class HTInterpreterLoopInfo {
  final int startIp;
  final int continueIp;
  final int breakIp;
  final HTNamespace namespace;
  HTInterpreterLoopInfo(
      this.startIp, this.continueIp, this.breakIp, this.namespace);
}

/// Determines how the interepreter deal with stack frame information when context are changed.
enum StackFrameStrategy {
  none,
  retract,
  create,
  reset,
}

/// The exucution context of the bytecode interpreter.
class HTContext {
  final String? file;
  final String? module;
  final HTNamespace? namespace;
  final int? ip;
  final int? line;
  final int? column;

  HTContext({
    this.file,
    this.module,
    this.namespace,
    this.ip,
    this.line,
    this.column,
  });
}

/// A wrapper class for the bytecode interpreter
/// to run a certain task in a future.
/// This is only used internally.
class FutureExecution {
  Future future;
  HTContext context;
  HTStackFrame stack;

  FutureExecution({
    required this.future,
    required this.context,
    required this.stack,
  });
}

/// A sub-expression evaluation frame.
/// Used to replace recursive execute() calls for compound expressions
/// (list, struct, string interpolation, function call arguments, switch cases, etc.)
/// Each frame tracks partially-built state and processes the value
/// when OpCode.endOfExec fires.
abstract class HTSubEvalFrame {
  bool isComplete = false;
  void handleEndOfExec(HTInterpreter i);
}

// --- Concrete SubEvalFrame implementations ---

class HTAssertionEval extends HTSubEvalFrame {
  final bool assertionValue;
  final String text;
  HTAssertionEval({required this.assertionValue, required this.text});

  @override
  void handleEndOfExec(HTInterpreter i) {
    final description = i.stack.pop();
    if (!assertionValue) {
      throw HTError.assertionFailed(
          '\'$text\', ${i.lexicon.stringify(description)}');
    }
    isComplete = true;
  }
}

class HTListEval extends HTSubEvalFrame {
  final List<dynamic> items = [];
  int index = 0;
  final int length;
  bool _currentIsSpread = false;

  HTListEval({required this.length, required bool firstIsSpread}) {
    _currentIsSpread = firstIsSpread;
  }

  @override
  void handleEndOfExec(HTInterpreter i) {
    final value = i.stack.pop();
    if (_currentIsSpread) {
      items.addAll(value as Iterable);
    } else {
      items.add(value);
    }
    index++;
    if (index >= length) {
      i.stack.push(items);
      isComplete = true;
    } else {
      _currentIsSpread = i.currentBytecodeModule.readBool();
    }
  }
}

class HTStructEval extends HTSubEvalFrame {
  final HTStruct struct;
  int index = 0;
  final int fieldsCount;
  bool _currentIsSpread = false;
  String? _currentKey;

  HTStructEval({required this.struct, required this.fieldsCount});

  @override
  void handleEndOfExec(HTInterpreter i) {
    final value = i.stack.pop();
    if (_currentIsSpread) {
      if (value is Map || value is HTStruct) {
        for (final key in value.keys) {
          if (key.startsWith(i.lexicon.internalPrefix)) continue;
          struct.define(key, i.toStructValue(value[key]));
        }
      } else {
        throw HTError.notSpreadableObj(
          filename: i.currentFile,
          line: i.currentLine,
          column: i.currentColumn,
        );
      }
    } else {
      struct.memberSet(_currentKey!, value);
    }
    index++;
    if (index >= fieldsCount) {
      i.stack.push(struct);
      isComplete = true;
    } else {
      _currentIsSpread = i.currentBytecodeModule.readBool();
      if (!_currentIsSpread) {
        _currentKey = i.currentBytecodeModule.getConstString();
      }
    }
  }
}

class HTGroupEval extends HTSubEvalFrame {
  @override
  void handleEndOfExec(HTInterpreter i) {
    // value is already on the operand stack, nothing to do
    isComplete = true;
  }
}

class HTStringInterpEval extends HTSubEvalFrame {
  String literal;
  int index = 0;
  final int length;
  final String interpStart;
  final String interpEnd;
  HTStringInterpEval({
    required this.literal,
    required this.length,
    required this.interpStart,
    required this.interpEnd,
  });

  @override
  void handleEndOfExec(HTInterpreter i) {
    final value = i.stack.pop();
    literal = literal.replaceAll(
        '$interpStart$index$interpEnd', i.lexicon.stringify(value));
    index++;
    if (index >= length) {
      i.stack.push(literal);
      isComplete = true;
    }
  }
}

class HTCallArgsEval extends HTSubEvalFrame {
  final dynamic callee;
  final String? objectId;
  final bool hasNewOperator;
  final List<dynamic> positionalArgs = [];
  final Map<String, dynamic> namedArgs = {};
  int positionalIndex = 0;
  int positionalLength = 0;
  int namedIndex = 0;
  int namedLength = 0;
  int _phase = 0; // 0=positional, 1=named
  bool _currentIsSpread = false;
  String? _currentNamedKey;

  HTCallArgsEval({
    required this.callee,
    this.objectId,
    required this.hasNewOperator,
  });

  @override
  void handleEndOfExec(HTInterpreter i) {
    final value = i.stack.pop();
    if (_phase == 0) {
      // Positional arg
      if (_currentIsSpread) {
        positionalArgs.addAll(value as List);
      } else {
        positionalArgs.add(value);
      }
      positionalIndex++;
      if (positionalIndex < positionalLength) {
        _currentIsSpread = i.currentBytecodeModule.readBool();
      } else {
        // Transition to named args
        namedLength = i.currentBytecodeModule.read();
        if (namedLength > 0) {
          _phase = 1;
          _currentNamedKey = i.currentBytecodeModule.getConstString();
          i.stack.localSymbol = _currentNamedKey;
        } else {
          _finishCall(i);
        }
      }
    } else {
      // Named arg
      namedArgs[_currentNamedKey!] = value;
      namedIndex++;
      if (namedIndex < namedLength) {
        _currentNamedKey = i.currentBytecodeModule.getConstString();
        i.stack.localSymbol = _currentNamedKey;
      } else {
        _finishCall(i);
      }
    }
  }

  void _finishCall(HTInterpreter i) {
    i.stack.push(i._call(
      callee,
      calleeId: objectId,
      isConstructorCall: hasNewOperator,
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    ));
    isComplete = true;
  }
}

class HTVarDeclInitEval extends HTSubEvalFrame {
  // varDecl metadata
  final String id;
  final String? classId;
  final bool isPrivate;
  final bool isField;
  final bool isExternal;
  final bool isStatic;
  final bool isMutable;
  final bool isTopLevel;
  final String? documentation;
  final HTType? declType;
  final bool lateFinalize;

  HTVarDeclInitEval({
    required this.id,
    this.classId,
    required this.isPrivate,
    required this.isField,
    required this.isExternal,
    required this.isStatic,
    required this.isMutable,
    required this.isTopLevel,
    this.documentation,
    this.declType,
    required this.lateFinalize,
  });

  @override
  void handleEndOfExec(HTInterpreter i) {
    final initValue = i.stack.pop();
    final decl = HTVariable(
      id: id,
      interpreter: i,
      file: i.currentFile,
      module: i.currentBytecodeModule.id,
      classId: classId,
      closure: i.currentNamespace,
      documentation: documentation,
      declType: declType,
      value: initValue,
      isPrivate: isPrivate,
      isExternal: isExternal,
      isStatic: isStatic,
      isMutable: isMutable,
      isField: isField,
    );
    if (!isField) {
      i.currentNamespace
          .define(id, decl, override: i.config.allowVariableShadowing);
    }
    if (i.config.allowInitializationExpresssionHaveValue) {
      i.stack.push(initValue);
    } else {
      i.stack.push(null);
    }
    isComplete = true;
  }
}

class HTDestructuringEval extends HTSubEvalFrame {
  final Map<String, HTType?> ids;
  final bool isVector;
  final bool isMutable;
  HTDestructuringEval({
    required this.ids,
    required this.isVector,
    required this.isMutable,
  });

  @override
  void handleEndOfExec(HTInterpreter i) {
    final collection = i.stack.pop();
    final omittedPrefix = '##';
    // var omittedIndex = 0;
    for (var idx = 0; idx < ids.length; ++idx) {
      var id = ids.keys.elementAt(idx);
      dynamic initValue;
      if (isVector) {
        if (id.startsWith(omittedPrefix)) continue;
        initValue = (collection as Iterable).elementAt(idx);
      } else {
        if (collection is HTObject) {
          initValue = collection.memberGet(id);
        } else {
          initValue = collection[id];
        }
      }
      final decl = HTVariable(
        id: id,
        interpreter: i,
        file: i.currentFile,
        module: i.currentBytecodeModule.id,
        closure: i.currentNamespace,
        declType: ids[id],
        value: initValue,
        isPrivate: i.lexicon.isPrivate(id),
        isMutable: isMutable,
      );
      i.currentNamespace
          .define(id, decl, override: i.config.allowVariableShadowing);
    }
    isComplete = true;
  }
}

class HTDeleteEval extends HTSubEvalFrame {
  final int deletingType;
  dynamic _object;

  HTDeleteEval({required this.deletingType});

  @override
  void handleEndOfExec(HTInterpreter i) {
    if (deletingType == HTDeletingTypeCode.member) {
      final object = i.stack.pop();
      if (object is HTStruct) {
        final symbol = i.currentBytecodeModule.getConstString();
        object.remove(symbol);
      } else {
        throw HTError.delete(
            filename: i.currentFile,
            line: i.currentLine,
            column: i.currentColumn);
      }
      isComplete = true;
    } else {
      // sub
      if (_object == null) {
        _object = i.stack.pop();
        // Not complete - main loop evaluates key next
      } else {
        final key = i.stack.pop().toString();
        if (_object is HTStruct || _object is Map) {
          _object.remove(key);
        } else {
          throw HTError.delete(
              filename: i.currentFile,
              line: i.currentLine,
              column: i.currentColumn);
        }
        isComplete = true;
      }
    }
  }
}

class HTSwitchEval extends HTSubEvalFrame {
  final dynamic condition;
  final bool hasCondition;
  final int casesCount;
  int caseIndex = 0;

  HTSwitchEval({
    required this.condition,
    required this.hasCondition,
    required this.casesCount,
  });

  @override
  void handleEndOfExec(HTInterpreter i) {
    final value = i.stack.pop();
    final caseType = _currentCaseType;
    bool matched = false;

    if (caseType == HTSwitchCaseTypeCode.equals) {
      if (hasCondition) {
        matched = (condition is HTType && value is HTType)
            ? condition.isA(value)
            : condition == value;
      } else {
        matched = value == true;
      }
      if (!matched) {
        i.currentBytecodeModule.skip(3); // skip jump to branch
      }
    } else if (caseType == HTSwitchCaseTypeCode.eigherEquals) {
      // value list was already collected; check match
      final values = _eitherValues ?? [value];
      matched = (condition is HTType)
          ? values.any((v) => v is HTType && condition.isA(v))
          : values.contains(condition);
      if (!matched) {
        i.currentBytecodeModule.skip(3);
      }
    } else if (caseType == HTSwitchCaseTypeCode.elementIn) {
      final Iterable iterable = value;
      matched = (condition is HTType)
          ? iterable.any((v) => v is HTType && condition.isA(v))
          : iterable.contains(condition);
      if (!matched) {
        i.currentBytecodeModule.skip(3);
      }
    }

    caseIndex++;
    if (caseIndex >= casesCount || matched) {
      isComplete = true;
    }
  }

  // HACK: These are set by the switch handler before each case evaluation
  int _currentCaseType = 0;
  List<dynamic>? _eitherValues;

  void startCase(int caseType) {
    _currentCaseType = caseType;
    _eitherValues = null;
  }
}

class HTStackFrame {
  /// Operand stack — replaces the old localValue + registerValues design.
  final List<dynamic> operandStack = [];

  /// Sub-expression evaluation frames — replaces recursive execute() calls.
  final List<HTSubEvalFrame> subEvalFrames = [];

  String? localSymbol;

  /// Loop point is stored as stack form.
  /// Break statement will jump to the last loop point,
  /// and remove it from this stack.
  /// Return statement will clear loop points by
  /// [loopCount] in current stack frame.
  final List<HTInterpreterLoopInfo> loops = [];
  final List<int> anchors = [];

  void push(dynamic v) => operandStack.add(v);
  dynamic pop() => operandStack.removeLast();
  dynamic get top => operandStack.last;
}

/// A bytecode implementation of Hetu Script interpreter
class HTInterpreter {
  static HTClass? classRoot;
  static HTStruct? structRoot;

  final cachedModules = <String, HTBytecodeModule>{};
  InterpreterConfig config;

  final HTLexicon _lexicon;
  HTLexicon get lexicon => _lexicon;

  HTResourceContext<HTSource> sourceContext;

  ErrorHandlerConfig get errorConfig => config;

  late final HTNamespace globalNamespace;

  bool scriptMode = false;
  bool globallyImport = false;
  Version compilerVersion = Version.none;
  List<String> stackTraceList = [];

  late HTNamespace currentNamespace;

  String _currentFile = '';
  String get currentFile => _currentFile;
  late HTResourceType _currentFileResourceType;

  late HTBytecodeModule _currentBytecodeModule;
  HTBytecodeModule get currentBytecodeModule => _currentBytecodeModule;

  var _currentLine = 0;
  var _currentColumn = 0;

  int get currentLine => _currentLine;

  int get currentColumn => _currentColumn;

  /// Register values are stored by groups.
  /// Every group have 16 values, they are HTRegIdx.
  /// A such group can be understanded as the stack frame of a runtime function.
  final List<HTStackFrame> _stackFrames = [HTStackFrame()];
  HTStackFrame get stack => _stackFrames.last;

  bool isInitted = false;

  /// A bytecode interpreter.
  HTInterpreter(
      {InterpreterConfig? config,
      required this.sourceContext,
      HTLexicon? lexicon})
      : config = config ?? InterpreterConfig(),
        _lexicon = lexicon ?? HTLexiconHetu() {
    globalNamespace =
        HTNamespace(lexicon: _lexicon, id: InternalIdentifier.global);
    currentNamespace = globalNamespace;

    _currentBytecodeModule =
        HTBytecodeModule(id: 'uninitialized', bytes: Uint8List.fromList([]));
    cachedModules[_currentBytecodeModule.id] = _currentBytecodeModule;
  }

  /// inexpicit type conversion for zero or null values
  bool _isZero(dynamic condition) {
    if (config.allowImplicitNullToZeroConversion) {
      return condition == 0 || condition == null;
    } else {
      return condition == 0;
    }
  }

  /// inexpicit type conversion for truthy values
  bool truthy(dynamic condition) {
    if (config.allowImplicitEmptyValueToFalseConversion) {
      if (condition == false ||
          condition == null ||
          condition == 0 ||
          condition == '' ||
          condition == 'false' ||
          (condition is Iterable && condition.isEmpty) ||
          (condition is Map && condition.isEmpty) ||
          (condition is HTStruct && condition.isEmpty)) {
        return false;
      } else {
        return true;
      }
    } else {
      return condition;
    }
  }

  /// Catch errors throwed by other code, and wrap them with detailed informations.
  void processError(Object error, [Object? externalStackTrace]) {
    final buffer = StringBuffer();

    void handleStackTrace(List<String> stackTrace,
        {bool withLineNumber = false}) {
      if (errorConfig.stackTraceDisplayCountLimit > 0) {
        if (stackTrace.length > errorConfig.stackTraceDisplayCountLimit) {
          for (var i = stackTrace.length - 1;
              i >= stackTrace.length - errorConfig.stackTraceDisplayCountLimit;
              --i) {
            if (withLineNumber) {
              buffer.write('#${stackTrace.length - 1 - i}\t');
            }
            buffer.writeln(stackTrace[i]);
          }
          buffer.writeln(
              '...(and other ${stackTrace.length - errorConfig.stackTraceDisplayCountLimit} messages)');
        } else {
          for (var i = stackTrace.length - 1; i >= 0; --i) {
            if (withLineNumber) {
              buffer.write('#${stackTrace.length - 1 - i}\t');
            }
            buffer.writeln(stackTrace[i]);
          }
        }
      } else if (errorConfig.stackTraceDisplayCountLimit < 0) {
        for (var i = stackTrace.length - 1; i >= 0; --i) {
          if (withLineNumber) {
            buffer.write('#${stackTrace.length - 1 - i}\t');
          }
          buffer.writeln(stackTrace[i]);
        }
      }
    }

    if (stackTraceList.isNotEmpty && errorConfig.showHetuStackTrace) {
      buffer.writeln(HTLocale.current.scriptStackTrace);
      handleStackTrace(stackTraceList, withLineNumber: true);
    }
    if (externalStackTrace != null && errorConfig.showDartStackTrace) {
      buffer.writeln(HTLocale.current.externalStackTrace);
      final externalStackTraceList =
          externalStackTrace.toString().trim().split('\n').reversed.toList();
      handleStackTrace(externalStackTraceList);
    }

    final stackTraceString = buffer.toString().trimRight();
    if (error is HTError) {
      final wrappedError = HTError(
        error.code,
        error.type,
        message: error.message,
        extra: stackTraceString,
        filename: error.filename ?? currentFile,
        line: error.line ?? currentLine,
        column: error.column ?? currentColumn,
      );
      throw wrappedError;
    } else {
      final hetuError = HTError.extern(
        error.toString(),
        extra: stackTraceString,
        filename: currentFile,
        line: currentLine,
        column: currentColumn,
      );
      throw hetuError;
    }
  }

  /// handler for various kinds of invocations.
  dynamic _call(
    dynamic callee, {
    String? calleeId,
    bool isConstructorCall = false,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    dynamic handleClassConstructor(dynamic callee) {
      late HTClass klass;
      if (callee is HTType) {
        final resolvedType = callee.resolve(currentNamespace) as HTNominalType;
        // if (resolvedType is! HTNominalType) {
        //   throw HTError.notCallable(callee.toString(),
        //       filename: _fileName, line: _line, column: _column);
        // }
        klass = resolvedType.klass as HTClass;
      } else {
        klass = callee;
      }
      if (klass.isAbstract) {
        throw HTError.abstracted(klass.id!,
            filename: _currentFile, line: _currentLine, column: _currentColumn);
      }
      if (klass.contains(InternalIdentifier.defaultConstructor)) {
        final constructor = klass
            .memberGet(InternalIdentifier.defaultConstructor) as HTFunction;
        return constructor.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
        );
      } else {
        throw HTError.notCallable(klass.id!,
            filename: _currentFile, line: _currentLine, column: _currentColumn);
      }
    }

    if (callee == null) {
      throw HTError.callNullObject(
          calleeId ?? stack.localSymbol ?? _lexicon.kNull,
          filename: _currentFile,
          line: _currentLine,
          column: _currentColumn);
    } else {
      if (isConstructorCall) {
        if ((callee is HTClass) || (callee is HTType)) {
          return handleClassConstructor(callee);
        } else if (callee is HTStruct && callee.declaration != null) {
          return callee.declaration!.createObject(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            // typeArgs: typeArgs,
          );
        } else {
          throw HTError.notNewable(_lexicon.stringify(callee),
              filename: _currentFile,
              line: _currentLine,
              column: _currentColumn);
        }
      } else {
        // calle is a script function
        if (callee is HTFunction) {
          return callee.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            // typeArgs: typeArgs,
          );
        }
        // calle is a dart function
        else if (callee is Function) {
          if (callee is HTExternalFunction) {
            return callee(
              // namespace: currentNamespace,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              // typeArgs: typeArgs,
            );
          } else {
            return Function.apply(
                callee,
                positionalArgs,
                namedArgs.map<Symbol, dynamic>(
                    (key, value) => MapEntry(Symbol(key), value)));
          }
        } else if ((callee is HTClass) || (callee is HTType)) {
          return handleClassConstructor(callee);
        } else if (callee is HTStruct && callee.declaration != null) {
          return callee.declaration!.createObject(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            // typeArgs: typeArgs,
          );
        } else {
          throw HTError.notCallable(
              _lexicon.stringify(callee, asStringLiteral: true),
              filename: _currentFile,
              line: _currentLine,
              column: _currentColumn);
        }
      }
    }
  }

  /// Get a namespace in certain module with a certain name.
  HTObject _fetchNamespace<T extends HTObject>(
      {String? namespace, String? module}) {
    HTObject nsp = globalNamespace;
    HTBytecodeModule byteModule = _currentBytecodeModule;
    if (module != null) {
      byteModule = cachedModules[module]!;
      assert(byteModule.namespaces.isNotEmpty);
      nsp = byteModule.namespaces.values.last;
    }
    if (namespace != null) {
      nsp = nsp.memberGet(namespace, isRecursive: true);
    }
    return nsp;
  }

  /// Add a declaration to certain namespace.
  /// if the value is not a declaration, will create one with [isMutable] value.
  /// if not, the [isMutable] will be ignored.
  void define(
    String id,
    dynamic value, {
    bool isMutable = false,
    bool override = false,
    bool throws = true,
    String? module,
    String? namespace,
  }) {
    final nsp = _fetchNamespace(namespace: namespace, module: module);
    nsp.define(id, value, override: override);
  }

  /// Get the documentation of a declaration in a certain namespace.
  String? help(dynamic object, {String? module}) {
    try {
      StringBuffer buffer = StringBuffer();
      final encap = encapsulate(object);
      if (object is HTDeclaration) {
        if (object.documentation != null) {
          buffer.write(object.documentation);
        }
      }
      if (encap == null) {
        buffer.write(globalNamespace.help());
      } else if (encap is HTTypeObject) {
        buffer.writeln('type ${object.id}');
        buffer.write(lexicon.stringify(object));
      } else if (encap is HTNamespace) {
        buffer.write(encap.help());
      } else if (encap is HTFunction) {
        buffer.write(encap.help());
      } else if (encap is HTClass) {
        buffer.write(encap.help());
      } else if (encap is HTInstance) {
        buffer.write(encap.help());
      } else if (encap is HTStruct) {
        buffer.write(encap.help());
      } else if (encap is HTExternalInstance) {
        buffer.write(encap.help());
      } else {
        buffer.writeln('found no help information on object: $object');
      }
      return buffer.toString();
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
        return null;
      } else {
        rethrow;
      }
    }
  }

  /// Get a top level variable defined in a certain namespace.
  dynamic fetch(String id,
      {String? namespace, String? module, bool ignoreUndefined = false}) {
    try {
      final nsp = _fetchNamespace(namespace: namespace, module: module);
      final result = nsp.memberGet(id, ignoreUndefined: ignoreUndefined);
      return result;
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  /// Assign value to a top level variable defined in a certain namespace in the interpreter.
  void assign(String id, dynamic value,
      {String? namespace, String? module, bool defineIfAbsent = false}) {
    try {
      final savedModuleName = _currentBytecodeModule.id;
      final nsp = _fetchNamespace(namespace: namespace, module: module);
      nsp.memberSet(id, value, defineIfAbsent: defineIfAbsent);
      if (_currentBytecodeModule.id != savedModuleName) {
        _currentBytecodeModule = cachedModules[savedModuleName]!;
      }
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  /// Invoke a top level function defined in a certain namespace.
  /// It's possible to use this method to invoke a [HTClass] or [HTNamedStruct]
  /// name as a contruct call, you will get a [HTInstance] or [HTStruct] as return value.
  dynamic invoke(
    String func, {
    bool ignoreUndefined = false,
    String? namespace,
    String? module,
    bool isConstructor = false,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    // List<HTType> typeArgs = const [],
  }) {
    try {
      stackTraceList.clear();
      final savedModuleName = _currentBytecodeModule.id;
      HTNamespace nsp;
      if (module != null) {
        nsp = globalNamespace;
        if (_currentBytecodeModule.id != module) {
          _currentBytecodeModule = cachedModules[module]!;
        }
        assert(_currentBytecodeModule.namespaces.isNotEmpty);
        nsp = _currentBytecodeModule.namespaces.values.last;
      } else {
        nsp = currentNamespace;
      }

      dynamic callee;
      if (namespace != null) {
        HTObject fromNsp = nsp.memberGet(namespace, isRecursive: true);
        callee = fromNsp.memberGet(func, ignoreUndefined: ignoreUndefined);
      } else {
        callee = nsp.memberGet(func,
            isRecursive: true, ignoreUndefined: ignoreUndefined);
      }
      if (callee == null) {
        if (ignoreUndefined == false) {
          throw HTError.callNullObject(func);
        } else if (ignoreUndefined == true) {
          if (config.debugMode) {
            print('${kConsoleColorYellow}hetu: $func is not defined.');
          }
        }
      } else {
        final result = _call(
          callee,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          // typeArgs: typeArgs,
        );
        if (_currentBytecodeModule.id != savedModuleName) {
          _currentBytecodeModule = cachedModules[savedModuleName]!;
        }
        return result;
      }
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  final externalFunctions = <String, Function>{};
  final externalMethods = <String, Function>{};
  final externalFunctionTypedefs = <String, HTExternalFunctionTypedef>{};
  final externalClasses = <String, HTExternalClass>{};
  final externalTypeReflection = <HTExternalTypeReflection>[];

  /// Wether the interpreter has a certain external class binding.
  bool containsExternalClass(String id) => externalClasses.containsKey(id);

  /// Register a external class into scrfipt.
  /// For acessing static members and constructors of this class,
  /// there must also be a declaraction in script
  void bindExternalClass(HTExternalClass externalClass,
      {bool override = false}) {
    if (externalClasses.containsKey(externalClass.id) && !override) {
      throw HTError.defined(externalClass.id, HTErrorType.runtimeError);
    }
    externalClasses[externalClass.id] = externalClass;
  }

  /// Fetch a external class instance
  HTExternalClass fetchExternalClass(String id) {
    if (!externalClasses.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externalClasses[id]!;
  }

  /// Bind an external class name to a abstract class name
  /// for interpreter getting dart class name by reflection
  void bindExternalReflection(HTExternalTypeReflection reflection) {
    externalTypeReflection.add(reflection);
  }

  /// Register an external function in script
  /// there must be a declaraction also in script for using this
  /// the function here can be either a pure dart function or a [HTExternalFunction]
  /// we use a conventions to distinguish different types of functions here:
  /// 1. for toplevel external functions, use id like '$functionId'
  /// 2. for static method or contructor of a class, use id like '$classId.$functionId'
  /// 3. for external functions within a explicity declared namespace, use id like '$namespaceId::$functionId'
  void bindExternalFunction(String id, Function function,
      {bool override = true}) {
    if (externalFunctions.containsKey(id) && !override) {
      throw HTError.defined(id, HTErrorType.runtimeError);
    }
    externalFunctions[id] = function;
  }

  /// Fetch an external function or a method
  Function fetchExternalFunction(String id) {
    if (!externalFunctions.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externalFunctions[id]!;
  }

  /// Register a external method in scrfipt
  /// there must be a declaraction also in script for using this
  /// the function here must be a [HTExternalMethod]
  /// use id like '$classId::$functionId'
  void bindExternalMethod(String id, Function method, {bool override = true}) {
    assert(method is HTExternalMethod);
    assert(id.contains('::'));

    if (externalMethods.containsKey(id) && !override) {
      throw HTError.defined(id, HTErrorType.runtimeError);
    }
    externalMethods[id] = method;
  }

  /// Fetch an external method
  Function fetchExternalMethod(String id) {
    if (!externalMethods.containsKey(id)) {
      throw HTError.undefinedExternal(id);
    }
    return externalMethods[id]!;
  }

  /// Register a external function typedef into scrfipt
  void bindExternalFunctionType(String id, HTExternalFunctionTypedef function,
      {bool override = true}) {
    if (externalFunctionTypedefs.containsKey(id) && !override) {
      throw HTError.defined(id, HTErrorType.runtimeError);
    }
    externalFunctionTypedefs[id] = function;
  }

  /// Using unwrapper to turn a script function into a external function
  Function unwrapExternalFunctionType(HTFunction func) {
    if (!externalFunctionTypedefs.containsKey(func.externalTypeId)) {
      throw HTError.undefinedExternal(func.externalTypeId!);
    }
    final unwrapFunc = externalFunctionTypedefs[func.externalTypeId]!;
    return unwrapFunc(func);
  }

  void switchModule(String module) {
    assert(cachedModules.containsKey(module));
    setContext(HTContext(module: module));
  }

  HTBytecodeModule? getBytecode(String module) {
    assert(cachedModules.containsKey(module));
    return cachedModules[module];
  }

  String stringify(dynamic object) {
    return _lexicon.stringify(object);
  }

  /// Get a object's type value at runtime.
  HTType typeOf(dynamic object) {
    final encap = encapsulate(object);
    HTType type;
    if (encap == null) {
      type = HTTypeNull(_lexicon.kNull);
    } else if (encap is HTType) {
      type = HTTypeType(_lexicon.kType);
    } else {
      type = encap.valueType ?? HTTypeUnknown(_lexicon.kUnknown);
    }
    return type;
  }

  HTType decltypeof(String id) {
    final HTDeclaration decl =
        currentNamespace.memberGet(id, isRecursive: true, asDeclaration: true);
    decl.resolve();
    var decltype = decl.declType;

    if (decltype != null) {
      return decltype;
    } else if (decl is HTVariableDeclaration) {
      return HTTypeAny(lexicon.kAny);
    } else {
      return HTTypeUnknown(lexicon.kUnknown);
    }
  }

  /// Encapsulate any value to a Hetu object, for members accessing and type check.
  HTObject? encapsulate(dynamic object) {
    if (object == null) {
      return null;
    } else if (object is HTObject) {
      return object;
    } else if (object is HTType) {
      return HTTypeObject(object);
    }

    late String typeString;
    if (object is bool) {
      typeString = _lexicon.idBoolean;
    } else if (object is int) {
      typeString = _lexicon.idInteger;
    } else if (object is double) {
      typeString = _lexicon.idFloat;
    } else if (object is String) {
      typeString = _lexicon.idString;
    } else if (object is List) {
      typeString = 'List';
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
    } else if (object is Set) {
      typeString = 'Set';
    } else if (object is Map) {
      typeString = 'Map';
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
    } else if (object is Iterable) {
      typeString = 'Iterable';
    } else if (object is Iterator) {
      typeString = 'Iterator';
    } else if (object is math.Random) {
      typeString = 'Random';
    } else {
      var reflected = false;
      for (final reflect in externalTypeReflection) {
        final result = reflect(object);
        if (result != null) {
          reflected = true;
          typeString = result;
          break;
        }
      }
      if (!reflected) {
        typeString = object.runtimeType.toString();
        typeString = _lexicon.getBaseTypeId(typeString);
      }
    }

    return HTExternalInstance(object, this, typeString);
  }

  dynamic toStructValue(dynamic value) {
    if (value is Iterable) {
      final list = [];
      for (final item in value) {
        final result = toStructValue(item);
        list.add(result);
      }
      return list;
    } else if (value is Map) {
      final HTStruct prototype = structRoot ??
          globalNamespace.memberGet(_lexicon.idGlobalPrototype,
              isRecursive: true);
      final struct =
          HTStruct(this, prototype: prototype, closure: currentNamespace);
      for (final key in value.keys) {
        final fieldKey = key.toString();
        final fieldValue = toStructValue(value[key]);
        struct.define(fieldKey, fieldValue);
      }
      return struct;
    } else if (value is HTStruct) {
      return value.clone();
    } else {
      return value;
    }
  }

  HTStruct createStructfromJSON(Map<dynamic, dynamic> jsonData) {
    final HTStruct prototype = structRoot ??
        globalNamespace.memberGet(_lexicon.idGlobalPrototype,
            isRecursive: true);
    final struct =
        HTStruct(this, prototype: prototype, closure: currentNamespace);
    for (final key in jsonData.keys) {
      var value = toStructValue(jsonData[key]);
      struct.define(key.toString(), value);
    }
    return struct;
  }

  void _handleNamespaceImport(HTNamespace nsp, UnresolvedImport importDecl) {
    final importedNamespace =
        _currentBytecodeModule.namespaces[importDecl.fromPath]!;

    // for script and literal code, namespaces are resolved immediately.
    if (_currentFileResourceType == HTResourceType.hetuScript ||
        _currentFileResourceType == HTResourceType.hetuLiteralCode) {
      for (final importDecl in importedNamespace.imports.values) {
        _handleNamespaceImport(importedNamespace, importDecl);
      }
    }

    if (importDecl.alias == null) {
      if (importDecl.showList.isEmpty) {
        nsp.import(importedNamespace, export: importDecl.isExported);
      } else {
        for (final id in importDecl.showList) {
          dynamic decl;
          if (importedNamespace.symbols.containsKey(id)) {
            decl = importedNamespace.symbols[id]!;
          } else if (importedNamespace.exports.contains(id)) {
            decl = importedNamespace.importedSymbols[id]!;
          } else {
            throw HTError.undefined(id);
          }
          nsp.defineImport(id, decl, importDecl.fromPath);
        }
      }
    } else {
      if (importDecl.showList.isEmpty) {
        nsp.defineImport(
            importDecl.alias!, importedNamespace, importDecl.fromPath);
      } else {
        final aliasNamespace = HTNamespace(
            lexicon: _lexicon, id: importDecl.alias!, closure: nsp.closure);
        for (final id in importDecl.showList) {
          if (!importedNamespace.symbols.containsKey(id)) {
            throw HTError.undefined(id);
          }
          final decl = importedNamespace.symbols[id]!;
          aliasNamespace.define(id, decl);
        }
        nsp.defineImport(
            importDecl.alias!, aliasNamespace, importDecl.fromPath);
      }
    }
  }

  /// Trigger eager initialization for all [HTVariable]s and [HTNamedStruct]s within [nsp] that
  /// have lazy-initialization bytecode (ip != null) but haven't been
  /// initialized yet (_value == null).
  ///
  /// This must be called while the interpreter is not evaluating any
  /// expression — typically during module loading when the stack is clean.
  void warmUpNamespaces() {
    for (final nsp in _currentBytecodeModule.namespaces.values) {
      for (final entry in nsp.symbols.entries) {
        final decl = entry.value;
        if (decl is HTVariable) {
          decl.initialize();
        } else if (decl is HTNamedStruct) {
          decl.initialize();
        }
      }
      for (final entry in nsp.importedSymbols.entries) {
        final decl = entry.value;
        if (decl is HTVariable) {
          decl.initialize();
        } else if (decl is HTNamedStruct) {
          decl.initialize();
        }
      }
    }
  }

  Version _handleVersion() {
    final major = _currentBytecodeModule.read();
    final minor = _currentBytecodeModule.read();
    final patch = _currentBytecodeModule.readUint16();
    final preReleaseLength = _currentBytecodeModule.read();
    String? preRelease;
    for (var i = 0; i < preReleaseLength; ++i) {
      preRelease ??= '';
      preRelease += _currentBytecodeModule.readUtf8String();
    }
    final buildLength = _currentBytecodeModule.read();
    String? build;
    for (var i = 0; i < buildLength; ++i) {
      build ??= '';
      build += _currentBytecodeModule.readUtf8String();
    }
    return Version(major, minor, patch, pre: preRelease, build: build);
  }

  /// Load a pre-compiled bytecode module.
  /// If [invoke] is true, run the bytecode immediately.
  dynamic loadBytecode({
    required Uint8List bytes,
    required String module,
    bool globallyImport = false,
    String? invoke,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    // List<HTType> typeArgs = const [],
  }) {
    try {
      this.globallyImport = globallyImport;

      if (cachedModules.containsKey(module)) {
        _currentBytecodeModule = cachedModules[module]!;
      } else {
        _currentBytecodeModule = HTBytecodeModule(id: module, bytes: bytes);
        cachedModules[_currentBytecodeModule.id] = _currentBytecodeModule;
      }
      _currentBytecodeModule.init(
        invoke: invoke,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
      );

      final signature = _currentBytecodeModule.readUint32();
      if (signature != HTCompiler.hetuSignature) {
        throw HTError.bytecode(
            filename: _currentFile, line: _currentLine, column: _currentColumn);
      }
      // compare the version of the compiler of the bytecode to my version.
      compilerVersion = _handleVersion();
      var incompatible = false;
      if (compilerVersion.major > 0) {
        if (compilerVersion.major > kHetuVersion.major) {
          incompatible = true;
        }
      } else {
        if (compilerVersion != kHetuVersion) {
          incompatible = true;
        }
      }
      if (incompatible) {
        throw HTError.version(
          _currentBytecodeModule.version.toString(),
          kHetuVersion.toString(),
          filename: _currentFile,
          line: _currentLine,
          column: _currentColumn,
        );
      }
      // read the version of the bytecode.
      final hasVersion = _currentBytecodeModule.readBool();
      if (hasVersion) {
        _currentBytecodeModule.version = _handleVersion();
      }
      _currentBytecodeModule.compiledAt =
          _currentBytecodeModule.readUtf8String();
      _currentFile = _currentBytecodeModule.readUtf8String();
      final sourceType =
          HTResourceType.values.elementAt(_currentBytecodeModule.read());
      scriptMode = (sourceType == HTResourceType.hetuScript) ||
          (sourceType == HTResourceType.hetuLiteralCode) ||
          (sourceType == HTResourceType.json);
      // TODO: import binary file
      dynamic result = execute();
      if (result is FutureExecution) {
        result = waitFutureExucution(result);
      }
      return result;
    } catch (error, stackTrace) {
      if (config.processError) {
        processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  /// Get the current context of the interpreter,
  HTContext getContext() {
    return HTContext(
      file: currentFile,
      module: currentBytecodeModule.id,
      namespace: currentNamespace,
      ip: currentBytecodeModule.ip,
      line: currentLine,
      column: currentColumn,
    );
  }

  void _createStackFrame() {
    _stackFrames.add(HTStackFrame());
  }

  /// Remove the top stack frame without propagating its value.
  void _retractStackFrame() {
    if (_stackFrames.isNotEmpty) {
      _stackFrames.removeLast();
    }
    if (_stackFrames.isEmpty) {
      _createStackFrame();
    }
  }

  /// Remove the top stack frame and propagate its top value to the parent.
  void _retractStackFrameAndPropagate() {
    dynamic topValue;
    bool hadValue = false;
    if (_stackFrames.isNotEmpty) {
      final lastFrame = _stackFrames.last;
      hadValue = lastFrame.operandStack.isNotEmpty;
      topValue = hadValue ? lastFrame.operandStack.last : null;
      _stackFrames.removeLast();
    }
    if (_stackFrames.isEmpty) {
      _createStackFrame();
    }
    if (hadValue) stack.push(topValue);
  }

  /// Change the current context of the bytecode interpreter to a new one.
  void setContext(HTContext? context) {
    if (context == null) return;

    var libChanged = false;
    if (context.file != null) {
      _currentFile = context.file!;
    }
    if (context.module != null &&
        (_currentBytecodeModule.id != context.module)) {
      assert(cachedModules.containsKey(context.module));
      _currentBytecodeModule = cachedModules[context.module]!;
      libChanged = true;
    }
    if (context.namespace != null) {
      currentNamespace = context.namespace!;
    } else if (libChanged) {
      currentNamespace = _currentBytecodeModule.namespaces.values.last;
    }
    if (context.ip != null) {
      _currentBytecodeModule.ip = context.ip!;
    } else if (libChanged) {
      _currentBytecodeModule.ip = 0;
    }
    if (context.line != null) {
      _currentLine = context.line!;
    } else if (libChanged) {
      _currentLine = 0;
    }
    if (context.column != null) {
      _currentColumn = context.column!;
    } else if (libChanged) {
      _currentColumn = 0;
    }
    // if (context.stackFrames != null) {
    //   _stackFrames = context.stackFrames!;
    // }
  }

  /// Interpret a loaded module with the key of [module]
  /// Starting from the instruction pointer of [ip]
  /// This function will return current expression value
  /// when encountered [OpCode.endOfExec] or [OpCode.endOfFunc].
  ///
  /// Changing library will create new stackframe.
  /// Such as currrent value, current symbol, current line & column, etc.
  dynamic execute({
    bool createStackFrame = true,
    bool propagateValue = true,
    HTContext? context,
    HTStackFrame? stackFrame,
    dynamic localValue,
  }) {
    createStackFrame = createStackFrame || context != null;

    HTContext? savedContext;
    if (context != null) {
      savedContext = getContext();
      setContext(context);
    }
    if (createStackFrame) {
      _createStackFrame();
    } else if (stackFrame != null) {
      _stackFrames.add(stackFrame);
    }
    if (localValue != null) stack.push(localValue);
    final result = _execute();
    if (context != null) {
      setContext(savedContext);
    }
    // Always remove frames we created (prevent leaks), but only propagate when requested.
    if (createStackFrame || stackFrame != null) {
      if (propagateValue) {
        _retractStackFrameAndPropagate();
      } else {
        _retractStackFrame();
      }
    }
    return result;
  }

  void _clearLocals() {
    stack.operandStack.clear();
    stack.localSymbol = null;
  }

  dynamic _execute(
      // void Function()? endOfFileHandler,
      // dynamic Function()? endOfModuleHandler,
      ) {
    int instruction;
    do {
      instruction = _currentBytecodeModule.read();
      switch (instruction) {
        case OpCode.lineInfo:
          _currentLine = _currentBytecodeModule.readUint16();
          _currentColumn = _currentBytecodeModule.readUint16();
        // store a local value in interpreter
        case OpCode.local:
          _storeLocal();
        case OpCode.skip:
          final distance = _currentBytecodeModule.readInt16();
          _currentBytecodeModule.ip += distance;
        case OpCode.file:
          _currentFile = _currentBytecodeModule.getConstString();
          final resourceTypeIndex = _currentBytecodeModule.read();
          _currentFileResourceType =
              HTResourceType.values.elementAt(resourceTypeIndex);
          if (_currentFileResourceType != HTResourceType.hetuLiteralCode) {
            currentNamespace = HTNamespace(
                lexicon: _lexicon, id: _currentFile, closure: globalNamespace);
          }
          // literal code will use current namespace as it is when run.
          else {
            currentNamespace = globalNamespace;
          }
        // store the loop jump point
        case OpCode.loopPoint:
          final continueLength = _currentBytecodeModule.readUint16();
          final breakLength = _currentBytecodeModule.readUint16();
          stack.loops.add(HTInterpreterLoopInfo(
              _currentBytecodeModule.ip,
              _currentBytecodeModule.ip + continueLength,
              _currentBytecodeModule.ip + breakLength,
              currentNamespace));
        case OpCode.breakLoop:
          assert(stack.loops.isNotEmpty);
          _currentBytecodeModule.ip = stack.loops.last.breakIp;
          currentNamespace = stack.loops.last.namespace;
          stack.loops.removeLast();
        case OpCode.continueLoop:
          assert(stack.loops.isNotEmpty);
          _currentBytecodeModule.ip = stack.loops.last.continueIp;
        // store the goto jump point
        case OpCode.anchor:
          stack.anchors.add(_currentBytecodeModule.ip);
        case OpCode.clearAnchor:
          assert(stack.anchors.isNotEmpty);
          stack.anchors.removeLast();
        case OpCode.goto:
          assert(stack.anchors.isNotEmpty);
          final distance = _currentBytecodeModule.readUint16();
          _currentBytecodeModule.ip = stack.anchors.last + distance;
        case OpCode.assertion:
          final assertionValue = stack.pop() as bool;
          final text = _currentBytecodeModule.readUtf8String();
          final hasDescription = _currentBytecodeModule.readBool();
          if (hasDescription) {
            stack.subEvalFrames.add(
                HTAssertionEval(assertionValue: assertionValue, text: text));
          } else if (!assertionValue) {
            throw HTError.assertionFailed('\'$text\', ');
          }
        case OpCode.throws:
          throw HTError.scriptThrows(_lexicon.stringify(stack.pop()));
        // 匿名语句块，blockStart 一定要和 blockEnd 成对出现
        case OpCode.codeBlock:
          final id = _currentBytecodeModule.getConstString();
          currentNamespace =
              HTNamespace(lexicon: _lexicon, id: id, closure: currentNamespace);
        case OpCode.endOfCodeBlock:
          currentNamespace = currentNamespace.closure!;
        // 语句结束
        case OpCode.endOfStmt:
          _clearLocals();
        case OpCode.endOfExec:
          if (stack.subEvalFrames.isNotEmpty) {
            final frame = stack.subEvalFrames.last;
            frame.handleEndOfExec(this);
            if (frame.isComplete) stack.subEvalFrames.removeLast();
            break; // Always continue main loop when frames were involved
          }
          return stack.operandStack.isNotEmpty ? stack.operandStack.last : null;
        case OpCode.endOfFunc:
          stack.loops.clear();
          stack.anchors.clear();
          if (stack.subEvalFrames.isNotEmpty) {
            final frame = stack.subEvalFrames.last;
            frame.handleEndOfExec(this);
            if (frame.isComplete) stack.subEvalFrames.removeLast();
            break;
          }
          return stack.operandStack.isNotEmpty ? stack.operandStack.last : null;
        case OpCode.createStackFrame:
          _createStackFrame();
        case OpCode.retractStackFrame:
          _retractStackFrameAndPropagate();
        case OpCode.constIntTable:
          final int64Length = _currentBytecodeModule.readUint16();
          for (var i = 0; i < int64Length; ++i) {
            _currentBytecodeModule
                .addGlobalConstant<int>(_currentBytecodeModule.readInt64());
            // _bytecodeModule.addInt(_bytecodeModule.readInt64());
          }
        case OpCode.constFloatTable:
          final float64Length = _currentBytecodeModule.readUint16();
          for (var i = 0; i < float64Length; ++i) {
            _currentBytecodeModule.addGlobalConstant<double>(
                _currentBytecodeModule.readFloat64());
            // _bytecodeModule.addFloat(_bytecodeModule.readFloat64());
          }
        case OpCode.constStringTable:
          final utf8StringLength = _currentBytecodeModule.readUint16();
          for (var i = 0; i < utf8StringLength; ++i) {
            _currentBytecodeModule.addGlobalConstant<String>(
                _currentBytecodeModule.readUtf8String());
          }
        case OpCode.endOfFile:
          if (_currentFileResourceType == HTResourceType.json) {
            final jsonSource = HTJsonSource(
              fullName: _currentFile,
              module: _currentBytecodeModule.id,
              value: stack.pop(),
            );
            _currentBytecodeModule.jsonSources[jsonSource.fullName] =
                jsonSource;
          } else if (_currentFileResourceType == HTResourceType.hetuModule) {
            _currentBytecodeModule.namespaces[currentNamespace.id!] =
                currentNamespace;
          }
        case OpCode.endOfModule:
          if (!scriptMode) {
            /// deal with import statement within every namespace of this module.
            for (final nsp in _currentBytecodeModule.namespaces.values) {
              for (final decl in nsp.imports.values) {
                _handleNamespaceImport(nsp, decl);
              }
            }
          }
          if (config.printPerformanceStatistics) {
            var message =
                'hetu: ${DateTime.now().millisecondsSinceEpoch - currentBytecodeModule.timestamp}ms\tto load module\t${_currentBytecodeModule.id}';
            if (_currentBytecodeModule.version != null) {
              message += '@${_currentBytecodeModule.version}';
            }
            message +=
                ' (compiled at ${_currentBytecodeModule.compiledAt} UTC with hetu@$compilerVersion)';
            print(message);
          }
          if (globallyImport && currentNamespace != globalNamespace) {
            globalNamespace.import(currentNamespace);
          }
          dynamic r;
          if (_currentBytecodeModule.invoke != null) {
            r = invoke(
              _currentBytecodeModule.invoke!,
              // module: scriptMode ? null : _currentBytecodeModule.id,
              positionalArgs: _currentBytecodeModule.positionalArgs,
              namedArgs: _currentBytecodeModule.namedArgs,
            );
            return r;
          } else if (scriptMode) {
            r = _stackFrames.last.operandStack.isNotEmpty
                ? _stackFrames.last.operandStack.last
                : null;
          }
          return r;
        case OpCode.importExportDecl:
          _handleImportExport();
        case OpCode.typeAliasDecl:
          _handleTypeAliasDecl();
        case OpCode.funcDecl:
          _handleFuncDecl();
        case OpCode.classDecl:
          _handleClassDecl();
        case OpCode.classDeclEnd:
          assert(currentNamespace is HTClassNamespace);
          final klass = (currentNamespace as HTClassNamespace).klass;
          currentNamespace = currentNamespace.closure!;
          // Add default constructor if there's none.
          if (!klass.isAbstract &&
              !klass.hasUserDefinedConstructor &&
              !klass.isExternal) {
            final ctorType =
                HTFunctionType(returnType: HTNominalType(id: klass.id!));
            final ctor = HTFunction(
              _currentFile,
              _currentBytecodeModule.id,
              this,
              internalName: InternalIdentifier.defaultConstructor,
              classId: klass.id,
              closure: klass.namespace,
              category: FunctionCategory.constructor,
              declType: ctorType,
            );
            klass.namespace.define(InternalIdentifier.defaultConstructor, ctor);
          }
          stack.push(klass);
        case OpCode.externalEnumDecl:
          _handleExternalEnumDecl();
        case OpCode.structDecl:
          _handleStructDecl();
        case OpCode.varDecl:
          final hasDoc = _currentBytecodeModule.readBool();
          String? documentation;
          if (hasDoc) {
            documentation = _currentBytecodeModule.readUtf8String();
          }
          final id = _currentBytecodeModule.getConstString();
          String? classId;
          final hasClassId = _currentBytecodeModule.readBool();
          if (hasClassId) {
            classId = _currentBytecodeModule.getConstString();
          }
          final isPrivate = _currentBytecodeModule.readBool();
          final isField = _currentBytecodeModule.readBool();
          final isExternal = _currentBytecodeModule.readBool();
          final isStatic = _currentBytecodeModule.readBool();
          final isMutable = _currentBytecodeModule.readBool();
          final isTopLevel = _currentBytecodeModule.readBool();
          if (isTopLevel && currentNamespace.willExportAll) {
            currentNamespace.declareExport(id);
          }
          final lateFinalize = _currentBytecodeModule.readBool();
          final lateInitialize = _currentBytecodeModule.readBool();
          HTType? declType;
          final hasTypeDecl = _currentBytecodeModule.readBool();
          if (hasTypeDecl) {
            declType = _handleTypeExpr();
          }
          HTVariable? decl;
          dynamic initValue;
          // FutureExecution? futureExecution;
          final hasInitializer = _currentBytecodeModule.readBool();
          if (hasInitializer) {
            if (lateInitialize) {
              final definitionLine = _currentBytecodeModule.readUint16();
              final definitionColumn = _currentBytecodeModule.readUint16();
              final length = _currentBytecodeModule.readUint16();
              final definitionIp = _currentBytecodeModule.ip;
              _currentBytecodeModule.skip(length);
              decl = HTVariable(
                id: id,
                interpreter: this,
                file: _currentFile,
                module: _currentBytecodeModule.id,
                classId: classId,
                closure: currentNamespace,
                documentation: documentation,
                declType: declType,
                isPrivate: isPrivate,
                isExternal: isExternal,
                isStatic: isStatic,
                isMutable: isMutable,
                isField: isField,
                ip: definitionIp,
                line: definitionLine,
                column: definitionColumn,
              );
            } else {
              // Use SubEvalFrame to evaluate initializer inline
              stack.subEvalFrames.add(HTVarDeclInitEval(
                id: id,
                classId: classId,
                isPrivate: isPrivate,
                isField: isField,
                isExternal: isExternal,
                isStatic: isStatic,
                isMutable: isMutable,
                isTopLevel: isTopLevel,
                documentation: documentation,
                declType: declType,
                lateFinalize: lateFinalize,
              ));
              break; // Main loop evaluates initializer; endOfExec triggers frame
            }
            if (hasInitializer && !lateInitialize) break; // Frame handles rest
          } else {
            decl = HTVariable(
              id: id,
              interpreter: this,
              file: _currentFile,
              module: _currentBytecodeModule.id,
              classId: classId,
              closure: currentNamespace,
              documentation: documentation,
              declType: declType,
              isPrivate: isPrivate,
              isExternal: isExternal,
              isStatic: isStatic,
              isMutable: isMutable,
              isField: isField,
              lateFinalize: lateFinalize,
            );
          }
          if (config.allowInitializationExpresssionHaveValue) {
            if (!hasInitializer || lateInitialize) stack.push(initValue);
          } else {
            stack.push(null);
          }
          if (!isField) {
            currentNamespace.define(id, decl,
                override: config.allowVariableShadowing);
          }
        // if (futureExecution != null) {
        //   return futureExecution;
        // }
        case OpCode.destructuringDecl:
          _handleDestructuringDecl();
        case OpCode.constDecl:
          _handleConstDecl();
        case OpCode.namespaceDecl:
          final hasDoc = _currentBytecodeModule.readBool();
          String? documentation;
          if (hasDoc) {
            documentation = _currentBytecodeModule.readUtf8String();
          }
          final id = _currentBytecodeModule.getConstString();
          String? classId;
          final hasClassId = _currentBytecodeModule.readBool();
          if (hasClassId) {
            classId = _currentBytecodeModule.getConstString();
          }
          final isPrivate = _currentBytecodeModule.readBool();
          final isTopLevel = _currentBytecodeModule.readBool();
          currentNamespace = HTNamespace(
            lexicon: _lexicon,
            id: id,
            classId: classId,
            closure: currentNamespace,
            documentation: documentation,
            isPrivate: isPrivate,
            isTopLevel: isTopLevel,
          );
        case OpCode.namespaceDeclEnd:
          final nsp = currentNamespace;
          stack.push(null);
          assert(nsp.closure != null);
          currentNamespace = nsp.closure!;
          assert(nsp.id != null);
          currentNamespace.define(nsp.id!, nsp);
        case OpCode.delete:
          final deletingType = _currentBytecodeModule.read();
          if (deletingType == HTDeletingTypeCode.local) {
            final symbol = _currentBytecodeModule.getConstString();
            currentNamespace.delete(symbol);
          } else {
            stack.subEvalFrames.add(HTDeleteEval(deletingType: deletingType));
            break; // Main loop evaluates object (and key for sub) inline
          }
        case OpCode.ifStmt:
          final thenBranchLength = _currentBytecodeModule.readUint16();
          final truthValue = truthy(stack.pop());
          if (!truthValue) {
            // Peek at elseBranchLength (int16) — it sits right after
            // thenBranch + OpCode.skip (1 byte), i.e. at
            // ip + thenBranchLength - 2.
            final elseLenOffset =
                _currentBytecodeModule.ip + thenBranchLength - 2;
            final elseBranchLength =
                _currentBytecodeModule.bytes.buffer
                    .asByteData()
                    .getInt16(elseLenOffset);
            _currentBytecodeModule.skip(thenBranchLength);
            if (elseBranchLength == 0) {
              stack.push(null);
            }
          }
        case OpCode.whileStmt:
          final truthValue = truthy(stack.pop());
          if (!truthValue) {
            assert(stack.loops.isNotEmpty);
            _currentBytecodeModule.ip = stack.loops.last.breakIp;
            currentNamespace = stack.loops.last.namespace;
            stack.loops.removeLast();
            _clearLocals();
          }
        case OpCode.doStmt:
          final hasCondition = _currentBytecodeModule.readBool();
          bool truthValue = false;
          if (hasCondition) {
            truthValue = truthy(stack.pop());
          }
          assert(stack.loops.isNotEmpty);
          if (truthValue) {
            _currentBytecodeModule.ip = stack.loops.last.startIp;
          } else {
            _currentBytecodeModule.ip = stack.loops.last.breakIp;
            currentNamespace = stack.loops.last.namespace;
            stack.loops.removeLast();
            _clearLocals();
          }
        case OpCode.switchStmt:
          _handleSwitch();
        case OpCode.assign:
          stack.pop(); // discard left identifier result (old value / symbol)
          final value = stack.pop(); // the right-side value to assign
          assert(stack.localSymbol != null);
          final id = stack.localSymbol!;
          final result = currentNamespace.memberSet(id, value,
              isRecursive: true, ignoreUndefined: true);
          if (!result) {
            if (config.allowImplicitVariableDeclaration) {
              final decl = HTVariable(
                  id: id,
                  interpreter: this,
                  file: _currentFile,
                  module: _currentBytecodeModule.id,
                  closure: currentNamespace,
                  value: value,
                  isPrivate: _lexicon.isPrivate(id),
                  isMutable: true);
              currentNamespace.define(id, decl);
            } else {
              throw HTError.undefined(id);
            }
          }
          stack.push(value);
        case OpCode.ifNull:
          final left = stack.pop();
          final rightValueLength = _currentBytecodeModule.readUint16();
          if (left != null) {
            _currentBytecodeModule.skip(rightValueLength);
            stack.push(left);
          }
        case OpCode.truthyValue:
          stack.push(truthy(stack.pop()));
        case OpCode.logicalOr:
          final left = stack.pop();
          final leftTruthValue = truthy(left);
          final rightValueLength = _currentBytecodeModule.readUint16();
          if (leftTruthValue) {
            _currentBytecodeModule.skip(rightValueLength);
            stack.push(leftTruthValue);
          }
        case OpCode.logicalAnd:
          final left = stack.pop();
          final leftTruthValue = truthy(left);
          final rightValueLength = _currentBytecodeModule.readUint16();
          if (!leftTruthValue) {
            _currentBytecodeModule.skip(rightValueLength);
            stack.push(false);
          }
        case OpCode.equal:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left == right);
        case OpCode.notEqual:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left != right);
        case OpCode.lesser:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          stack.push(left < right);
        case OpCode.greater:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          stack.push(left > right);
        case OpCode.lesserOrEqual:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          stack.push(left <= right);
        case OpCode.greaterOrEqual:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          stack.push(left >= right);
        case OpCode.typeAs:
          final type = (stack.pop() as HTType).resolve(currentNamespace)
              as HTNominalType;
          final object = stack.pop();
          final klass = type.klass as HTClass;
          stack.push(HTCast(object, klass, this));
        case OpCode.typeIs:
          _handleTypeCheck();
        case OpCode.typeIsNot:
          _handleTypeCheck(isNot: true);
        case OpCode.bitwiseOr:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left | right);
        case OpCode.bitwiseXor:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left ^ right);
        case OpCode.bitwiseAnd:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left & right);
        case OpCode.leftShift:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left << right);
        case OpCode.rightShift:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left >> right);
        case OpCode.unsignedRightShift:
          final right = stack.pop();
          final left = stack.pop();
          stack.push(left >>> right);
        case OpCode.add:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          stack.push(left + right);
        case OpCode.subtract:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          stack.push(left - right);
        case OpCode.multiply:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          if (_isZero(right)) {
            right = 0;
          }
          stack.push(left * right);
        case OpCode.devide:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          stack.push(left / right);
        case OpCode.truncatingDevide:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          stack.push(left ~/ right);
        case OpCode.modulo:
          var right = stack.pop();
          var left = stack.pop();
          if (_isZero(left)) {
            left = 0;
          }
          stack.push(left % right);
        case OpCode.negative:
          stack.push(-stack.pop());
        case OpCode.logicalNot:
          final value = stack.pop();
          final truthValue = truthy(value);
          stack.push(!truthValue);
        case OpCode.bitwiseNot:
          stack.push(~stack.pop());
        case OpCode.typeValueOf:
          stack.push(typeOf(stack.pop()));
        case OpCode.decltypeOf:
          final symbol = stack.localSymbol;
          assert(symbol != null);
          stack.push(decltypeof(symbol!));
        case OpCode.awaitedValue:
          // handle the possible future execution request raised by await keyword and Future value.
          if (stack.top is Future) {
            final HTContext savedContext = getContext();
            return FutureExecution(
              future: stack.top as Future,
              context: savedContext,
              stack: stack,
            );
          }
        case OpCode.memberGet:
          final key = stack.pop();
          final object = stack.pop();
          stack.localSymbol = key;
          final isNullable = _currentBytecodeModule.readBool();
          final hasObjectId = _currentBytecodeModule.readBool();
          String? objectId;
          if (hasObjectId) {
            objectId = _currentBytecodeModule.readUtf8String();
          }
          if (object == null) {
            if (isNullable) {
              // _currentBytecodeModule.skip(keyBytesLength);
              stack.push(null);
            } else {
              throw HTError.visitMemberOfNullObject(
                  objectId ?? _lexicon.kNull, key,
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            final encap = encapsulate(object);
            if (encap is HTNamespace) {
              stack.push(encap.memberGet(key,
                  from: currentNamespace.fullName, isRecursive: false));
            } else {
              stack
                  .push(encap?.memberGet(key, from: currentNamespace.fullName));
            }
          }

        case OpCode.subGet:
          final key = stack.pop();
          final object = stack.pop();
          final isNullable = _currentBytecodeModule.readBool();
          final hasObjectId = _currentBytecodeModule.readBool();
          String? objectId;
          if (hasObjectId) {
            objectId = _currentBytecodeModule.readUtf8String();
          }
          if (object == null) {
            if (isNullable) {
              // _currentBytecodeModule.skip(keyBytesLength);
              stack.push(null);
            } else {
              throw HTError.visitMemberOfNullObject(
                  objectId ?? _lexicon.kNull, _lexicon.stringify(key),
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            if (object is HTObject) {
              stack.push(object.subGet(key, from: currentNamespace.fullName));
            } else {
              if (object is List) {
                if (key is! num) {
                  throw HTError.subGetKey(key,
                      filename: _currentFile,
                      line: _currentLine,
                      column: _currentColumn);
                }
                final intValue = key.toInt();
                if (intValue != key) {
                  throw HTError.subGetKey(key,
                      filename: _currentFile,
                      line: _currentLine,
                      column: _currentColumn);
                }
                stack.push(object[intValue]);
              } else {
                stack.push(object[key]);
              }
            }
          }
        case OpCode.memberSet:
          final key = stack.pop();
          final object = stack.pop();
          final value = stack.pop();
          final isNullable = _currentBytecodeModule.readBool();
          final hasObjectId = _currentBytecodeModule.readBool();
          String? objectId;
          if (hasObjectId) {
            objectId = _currentBytecodeModule.readUtf8String();
          }
          if (object == null) {
            if (isNullable) {
              stack.push(null);
            } else {
              throw HTError.visitMemberOfNullObject(
                  objectId ?? _lexicon.kNull, _lexicon.stringify(key),
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            stack.push(value);
            final encap = encapsulate(object);
            if (encap is HTNamespace) {
              encap.memberSet(key, value,
                  from: currentNamespace.fullName, isRecursive: false);
            } else {
              encap?.memberSet(key, value, from: currentNamespace.fullName);
            }
          }
        case OpCode.subSet:
          final key = stack.pop();
          final object = stack.pop();
          final value = stack.pop();
          final isNullable = _currentBytecodeModule.readBool();
          final hasObjectId = _currentBytecodeModule.readBool();
          String? objectId;
          if (hasObjectId) {
            objectId = _currentBytecodeModule.readUtf8String();
          }
          if (object == null) {
            if (isNullable) {
              stack.push(null);
            } else {
              throw HTError.visitMemberOfNullObject(
                  objectId ?? _lexicon.kNull, _lexicon.stringify(key),
                  filename: _currentFile,
                  line: _currentLine,
                  column: _currentColumn);
            }
          } else {
            stack.push(value);
            if (object is HTObject) {
              object.subSet(key, value);
            } else {
              if (object is HTObject) {
                object.subSet(key, value, from: currentNamespace.fullName);
              } else {
                if (object is List) {
                  if (key is! num) {
                    throw HTError.subGetKey(key,
                        filename: _currentFile,
                        line: _currentLine,
                        column: _currentColumn);
                  }
                  final intValue = key.toInt();
                  if (intValue != key) {
                    throw HTError.subGetKey(key,
                        filename: _currentFile,
                        line: _currentLine,
                        column: _currentColumn);
                  }
                  object[intValue] = value;
                } else {
                  object[key] = value;
                }
              }
            }
          }
        case OpCode.call:
          final callee = stack.pop();
          final isNullable = _currentBytecodeModule.readBool();
          final hasNewOperator = _currentBytecodeModule.readBool();
          final hasObjectId = _currentBytecodeModule.readBool();
          String? objectId;
          if (hasObjectId) {
            objectId = _currentBytecodeModule.readUtf8String();
          }
          final argsBytesLength = _currentBytecodeModule.readUint16();
          if (callee == null) {
            if (isNullable) {
              _currentBytecodeModule.skip(argsBytesLength);
              stack.push(null);
              break;
            }
            throw HTError.callNullObject(
                objectId ?? stack.localSymbol ?? _lexicon.kNull,
                filename: _currentFile,
                line: _currentLine,
                column: _currentColumn);
          }
          final positionalLength = _currentBytecodeModule.read();
          if (positionalLength == 0) {
            final namedLength = _currentBytecodeModule.read();
            if (namedLength == 0) {
              stack.push(_call(
                callee,
                calleeId: objectId,
                isConstructorCall: hasNewOperator,
              ));
              break;
            }
            final frame = HTCallArgsEval(
                callee: callee,
                objectId: objectId,
                hasNewOperator: hasNewOperator);
            frame.namedLength = namedLength;
            frame._phase = 1;
            frame._currentNamedKey = _currentBytecodeModule.getConstString();
            stack.localSymbol = frame._currentNamedKey;
            stack.subEvalFrames.add(frame);
            break;
          }
          final frame = HTCallArgsEval(
            callee: callee,
            objectId: objectId,
            hasNewOperator: hasNewOperator,
          );
          frame.positionalLength = positionalLength;
          frame._currentIsSpread = _currentBytecodeModule.readBool();
          stack.subEvalFrames.add(frame);
        default:
          throw HTError.unknownOpCode(instruction,
              filename: _currentFile,
              line: _currentLine,
              column: _currentColumn);
      }
    } while (instruction != OpCode.endOfCode);
  }

  Future<dynamic> waitFutureExucution(FutureExecution futureExecution) async {
    var possibleFutureValue = await futureExecution.future;
    var result = execute(
      createStackFrame: false,
      propagateValue: false,
      context: futureExecution.context,
      stackFrame: futureExecution.stack,
      localValue: possibleFutureValue,
    );
    while (result is FutureExecution) {
      result = await waitFutureExucution(result);
    }
    return result;
  }

  void _handleImportExport() {
    final isExported = _currentBytecodeModule.readBool();
    final isPreloadedModule = _currentBytecodeModule.readBool();
    final showList = <String>{};
    final showListLength = _currentBytecodeModule.read();
    for (var i = 0; i < showListLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      showList.add(id);
      if (isExported) {
        currentNamespace.declareExport(id);
      }
    }
    final hasFromPath = _currentBytecodeModule.readBool();
    String? fromPath;
    if (hasFromPath) {
      fromPath = _currentBytecodeModule.getConstString();
    }
    String? alias;
    final hasAlias = _currentBytecodeModule.readBool();
    if (hasAlias) {
      alias = _currentBytecodeModule.getConstString();
    }

    // If the import path starts with 'module:', then the module should be
    // already loaded by the loadBytecode() method.
    if (isPreloadedModule) {
      assert(fromPath != null);
      assert(cachedModules.containsKey(fromPath));
      if (cachedModules.containsKey(fromPath)) {
        final importedModule = cachedModules[fromPath]!;
        final importedNamespace = importedModule.namespaces.values.last;
        if (showList.isEmpty) {
          currentNamespace.defineImport(
              alias!, importedNamespace, 'module:${importedModule.id}');
        } else {
          final aliasNamespace = HTNamespace(
              lexicon: _lexicon, id: alias!, closure: currentNamespace.closure);
          for (final id in showList) {
            final decl = importedNamespace.symbols[id]!;
            // assert(!decl.isPrivate);
            aliasNamespace.define(id, decl);
          }
          currentNamespace.defineImport(
              alias, aliasNamespace, 'module:${importedModule.id}');
        }
      }
    }
    // TODO: If the import path starts with 'package:', will try to fetch the source file from '.hetu_packages' under root.
    else {
      if (fromPath != null) {
        final ext = path.extension(fromPath);
        if (ext == HTResource.hetuModule || ext == HTResource.hetuScript) {
          final decl = UnresolvedImport(fromPath,
              alias: alias, showList: showList, isExported: isExported);
          if (_currentFileResourceType == HTResourceType.hetuModule) {
            currentNamespace.declareImport(decl);
          } else {
            _handleNamespaceImport(currentNamespace, decl);
          }
        } else {
          // TODO: import binary bytes
          assert(_currentBytecodeModule.jsonSources.containsKey(fromPath));
          final jsonSource = _currentBytecodeModule.jsonSources[fromPath]!;
          currentNamespace.defineImport(
            alias!,
            HTVariable(
              id: alias,
              interpreter: this,
              value: jsonSource.value,
              closure: currentNamespace,
              isPrivate: _lexicon.isPrivate(alias),
            ),
            jsonSource.fullName,
          );
          if (isExported) {
            currentNamespace.declareExport(alias);
          }
        }
      } else {
        // If it's an export statement regarding this namespace self,
        // It will be handled immediately since it does not needed resolve.
        assert(isExported);
        if (showList.isNotEmpty) {
          currentNamespace.willExportAll = false;
          currentNamespace.exports.addAll(showList);
        }
        // If the namespace will export all,
        // a declared id will be add to the list
        // when the declaration statement is handled.
      }
    }
  }

  void _storeLocal() {
    final valueType = _currentBytecodeModule.read();
    switch (valueType) {
      case HTValueTypeCode.nullValue:
        stack.push(null);
      case HTValueTypeCode.boolean:
        (_currentBytecodeModule.read() == 0)
            ? stack.push(false)
            : stack.push(true);
      case HTValueTypeCode.constInt:
        final index = _currentBytecodeModule.readUint16();
        stack.push(_currentBytecodeModule.getGlobalConstant(int, index));
      case HTValueTypeCode.constFloat:
        final index = _currentBytecodeModule.readUint16();
        stack.push(_currentBytecodeModule.getGlobalConstant(double, index));
      case HTValueTypeCode.constString:
        final index = _currentBytecodeModule.readUint16();
        stack.push(_currentBytecodeModule.getGlobalConstant(String, index));
      case HTValueTypeCode.string:
        stack.push(_currentBytecodeModule.readUtf8String());
      case HTValueTypeCode.stringInterpolation:
        var literal = _currentBytecodeModule.readUtf8String();
        final interpolationLength = _currentBytecodeModule.read();
        if (interpolationLength > 0) {
          stack.subEvalFrames.add(HTStringInterpEval(
            literal: literal,
            length: interpolationLength,
            interpStart: _lexicon.stringInterpolationStart,
            interpEnd: _lexicon.stringInterpolationEnd,
          ));
          return;
        }
        stack.push(literal);
      case HTValueTypeCode.identifier:
        final symbol =
            stack.localSymbol = _currentBytecodeModule.getConstString();
        final isLocal = _currentBytecodeModule.readBool();
        if (isLocal) {
          stack.push(currentNamespace.memberGet(symbol, isRecursive: true));
          // _curLeftValue = _curNamespace;
        } else {
          stack.push(symbol);
        }
      // final hasTypeArgs = _curLibrary.readBool();
      // if (hasTypeArgs) {
      //   final typeArgsLength = _curLibrary.read();
      //   final typeArgs = <HTType>[];
      //   for (var i = 0; i < typeArgsLength; ++i) {
      //     final arg = _handleTypeExpr();
      //     typeArgs.add(arg);
      //   }
      //   _curTypeArgs = typeArgs;
      // }
      case HTValueTypeCode.group:
        stack.subEvalFrames.add(HTGroupEval());
        return;
      case HTValueTypeCode.list:
        final length = _currentBytecodeModule.readUint16();
        if (length == 0) {
          stack.push([]);
          break;
        }
        final firstIsSpread = _currentBytecodeModule.readBool();
        stack.subEvalFrames
            .add(HTListEval(length: length, firstIsSpread: firstIsSpread));
        return;
      case HTValueTypeCode.struct:
        String? id;
        final hasId = _currentBytecodeModule.readBool();
        if (hasId) {
          id = _currentBytecodeModule.getConstString();
        }
        HTStruct? prototype;
        final hasPrototypeId = _currentBytecodeModule.readBool();
        if (hasPrototypeId) {
          final prototypeId = _currentBytecodeModule.getConstString();
          prototype = currentNamespace.memberGet(prototypeId,
              from: currentNamespace.fullName, isRecursive: true);
        }
        final struct = HTStruct(this,
            id: id,
            prototype: prototype,
            isPrototypeRoot: id == _lexicon.idGlobalPrototype,
            closure: currentNamespace);
        final fieldsCount = _currentBytecodeModule.read();
        if (fieldsCount == 0) {
          stack.push(struct);
          break;
        }
        final frame = HTStructEval(struct: struct, fieldsCount: fieldsCount);
        frame._currentIsSpread = _currentBytecodeModule.readBool();
        if (!frame._currentIsSpread) {
          frame._currentKey = _currentBytecodeModule.getConstString();
        }
        stack.subEvalFrames.add(frame);
        return;
      // case HTValueTypeCode.map:
      //   final map = {};
      //   final length = _curLibrary.readUint16();
      //   for (var i = 0; i < length; ++i) {
      //     final key = execute();
      //     final value = execute();
      //     map[key] = value;
      //   }
      //   _curValue = map;
      //   break;
      case HTValueTypeCode.function:
        final internalName = _currentBytecodeModule.getConstString();
        final hasExternalTypedef = _currentBytecodeModule.readBool();
        String? externalTypedef;
        if (hasExternalTypedef) {
          externalTypedef = _currentBytecodeModule.getConstString();
        }
        final isAsync = _currentBytecodeModule.readBool();
        final hasParamDecls = _currentBytecodeModule.readBool();
        final isVariadic = _currentBytecodeModule.readBool();
        final minArity = _currentBytecodeModule.read();
        final maxArity = _currentBytecodeModule.read();
        final paramDecls = _getParams(_currentBytecodeModule.read());
        HTType? returnType;
        final hasReturnType = _currentBytecodeModule.readBool();
        if (hasReturnType) {
          returnType = _handleTypeExpr();
        }
        final declType = HTFunctionType(
            parameterTypes: paramDecls.values
                .map((param) => HTParameterType(
                    declType: param.declType,
                    isOptional: param.isOptional,
                    isVariadic: param.isVariadic,
                    id: param.isNamed ? param.id : null))
                .toList(),
            returnType: returnType);
        int? line, column, definitionIp;
        final hasDefinition = _currentBytecodeModule.readBool();
        if (hasDefinition) {
          line = _currentBytecodeModule.readUint16();
          column = _currentBytecodeModule.readUint16();
          final length = _currentBytecodeModule.readUint16();
          definitionIp = _currentBytecodeModule.ip;
          _currentBytecodeModule.skip(length);
        }
        final func = HTFunction(
          internalName: internalName,
          _currentFile,
          _currentBytecodeModule.id,
          this,
          closure: currentNamespace,
          category: FunctionCategory.literal,
          externalTypeId: externalTypedef,
          hasParamDecls: hasParamDecls,
          paramDecls: paramDecls,
          declType: declType,
          isPrivate: true,
          isAsync: isAsync,
          isVariadic: isVariadic,
          minArity: minArity,
          maxArity: maxArity,
          ip: definitionIp,
          line: line,
          column: column,
          namespace: currentNamespace,
        );
        if (!hasExternalTypedef) {
          stack.push(func);
        } else {
          final externalFunc = unwrapExternalFunctionType(func);
          stack.push(externalFunc);
        }
      case HTValueTypeCode.intrinsicType:
        stack.push(_handleIntrinsicType());
      case HTValueTypeCode.nominalType:
        stack.push(_handleNominalType());
      case HTValueTypeCode.functionType:
        stack.push(_handleFunctionType());
      case HTValueTypeCode.structuralType:
        stack.push(_handleStructuralType());
      default:
        throw HTError.unkownValueType(
          valueType,
          filename: _currentFile,
          line: _currentLine,
          column: _currentColumn,
        );
    }
  }

  void _handleSwitch() {
    var condition = stack.pop();
    final hasCondition = _currentBytecodeModule.readBool();
    final casesCount = _currentBytecodeModule.read();
    for (var i = 0; i < casesCount; ++i) {
      final caseType = _currentBytecodeModule.read();
      // If condition expression is provided,
      // jump to the first case branch where its value equals condition.
      // If condition expression is not provided,
      // jump to the first case branch where its value is true.
      // If no case branch matches condition and else branch is provided,
      // will jump to else branch.
      if (caseType == HTSwitchCaseTypeCode.equals) {
        final value = execute(createStackFrame: false, propagateValue: false);
        stack.pop(); // consume value from operand stack
        if (hasCondition) {
          final matched = (condition is HTType && value is HTType)
              ? condition.isA(value)
              : condition == value;
          if (matched) {
            break;
          }
        } else if (value) {
          break;
        }
        _currentBytecodeModule.skip(3);
      } else if (caseType == HTSwitchCaseTypeCode.eigherEquals) {
        assert(hasCondition);
        final count = _currentBytecodeModule.read();
        final values = [];
        for (var i = 0; i < count; ++i) {
          values.add(execute(createStackFrame: false, propagateValue: false));
          stack.pop(); // consume each value from operand stack
        }
        final matched = (condition is HTType)
            ? values.any((v) => v is HTType && condition.isA(v))
            : values.contains(condition);
        if (matched) {
          break;
        } else {
          _currentBytecodeModule.skip(3);
        }
      } else if (caseType == HTSwitchCaseTypeCode.elementIn) {
        assert(hasCondition);
        final Iterable value =
            execute(createStackFrame: false, propagateValue: false);
        stack.pop(); // consume value from operand stack
        final matched = (condition is HTType)
            ? value.any((v) => v is HTType && condition.isA(v))
            : value.contains(condition);
        if (matched) {
          break;
        } else {
          _currentBytecodeModule.skip(3);
        }
      }
    }
  }

  void _handleTypeCheck({bool isNot = false}) {
    final rightType = (stack.pop() as HTType).resolve(currentNamespace);
    final object = stack.pop();
    HTType leftType;
    if (object != null) {
      if (object is HTType) {
        leftType = object;
      } else {
        final encap = encapsulate(object);
        leftType = encap!.valueType!;
      }
    } else {
      leftType = HTTypeNull(_lexicon.kNull);
    }
    final result = leftType.isA(rightType);
    stack.push(isNot ? !result : result);
  }

  HTIntrinsicType _handleIntrinsicType() {
    final typeName = _currentBytecodeModule.getConstString();
    final isTop = _currentBytecodeModule.readBool();
    final isBottom = _currentBytecodeModule.readBool();
    if (typeName == _lexicon.kAny) {
      return HTTypeAny(typeName);
    } else if (typeName == _lexicon.kUnknown) {
      return HTTypeUnknown(typeName);
    } else if (typeName == _lexicon.kVoid) {
      return HTTypeVoid(typeName);
    } else if (typeName == _lexicon.kNever) {
      return HTTypeNever(typeName);
    } else if (typeName == _lexicon.kType) {
      return HTTypeType(typeName);
    } else if (lexicon.kFunctions.contains(typeName)) {
      return HTTypeFunction(lexicon.kFunction);
    } else if (typeName == _lexicon.kNamespace) {
      return HTTypeNamespace(typeName);
    }
    // fallsafe measure, however this should not happen
    return HTIntrinsicType(typeName, isTop: isTop, isBottom: isBottom);
  }

  HTNominalType _handleNominalType() {
    final typeName = _currentBytecodeModule.getConstString();
    final namespacesLength = _currentBytecodeModule.read();
    final namespacesWithin = <String>[];
    for (var i = 0; i < namespacesLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      namespacesWithin.add(id);
    }
    final typeArgsLength = _currentBytecodeModule.read();
    final typeArgs = <HTType>[];
    for (var i = 0; i < typeArgsLength; ++i) {
      final typearg = _handleTypeExpr();
      typeArgs.add(typearg);
    }
    final isNullable = (_currentBytecodeModule.read() == 0) ? false : true;
    return HTNominalType(
      id: typeName,
      typeArgs: typeArgs,
      isNullable: isNullable,
      namespacesWithin: namespacesWithin,
    );
  }

  HTFunctionType _handleFunctionType() {
    final paramsLength = _currentBytecodeModule.read();
    final parameterTypes = <HTParameterType>[];
    for (var i = 0; i < paramsLength; ++i) {
      final declType = _handleTypeExpr();
      final isOptional = _currentBytecodeModule.read() == 0 ? false : true;
      final isVariadic = _currentBytecodeModule.read() == 0 ? false : true;
      final isNamed = _currentBytecodeModule.read() == 0 ? false : true;
      String? paramId;
      if (isNamed) {
        paramId = _currentBytecodeModule.getConstString();
      }
      final decl = HTParameterType(
          id: paramId,
          declType: declType,
          isOptional: isOptional,
          isVariadic: isVariadic);
      parameterTypes.add(decl);
    }
    final returnType = _handleTypeExpr();
    return HTFunctionType(
        parameterTypes: parameterTypes, returnType: returnType);
  }

  HTStructuralType _handleStructuralType() {
    final fieldsLength = _currentBytecodeModule.readUint16();
    final fieldTypes = <String, HTType>{};
    for (var i = 0; i < fieldsLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      final typeExpr = _handleTypeExpr();
      fieldTypes[id] = typeExpr;
    }
    return HTStructuralType(fieldTypes: fieldTypes, closure: currentNamespace);
  }

  HTType _handleTypeExpr() {
    final typeType = _currentBytecodeModule.read();
    switch (typeType) {
      case HTValueTypeCode.intrinsicType:
        return _handleIntrinsicType();
      case HTValueTypeCode.nominalType:
        return _handleNominalType();
      case HTValueTypeCode.functionType:
        return _handleFunctionType();
      case HTValueTypeCode.structuralType:
        return _handleStructuralType();
      default:
        // This should never happens.
        throw HTError.unknownOpCode(typeType,
            filename: _currentFile, line: _currentLine, column: _currentColumn);
    }
  }

  void _handleTypeAliasDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.getConstString();
    }
    final isPrivate = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    final value = _handleTypeExpr();
    final decl = HTVariable(
      id: id,
      interpreter: this,
      classId: classId,
      closure: currentNamespace,
      documentation: documentation,
      value: value,
      isPrivate: isPrivate,
    );
    currentNamespace.define(id, decl);
    stack.push(null);
  }

  void _handleConstDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.getConstString();
    }
    final isPrivate = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    final typeIndex = _currentBytecodeModule.read();
    final type = HTConstantType.values.elementAt(typeIndex);
    final index = _currentBytecodeModule.readUint16();
    final decl = HTConstantValue(
      id: id,
      type: getConstantType(type),
      index: index,
      classId: classId,
      documentation: documentation,
      globalConstantTable: _currentBytecodeModule,
      isPrivate: isPrivate,
    );
    currentNamespace.define(id, decl, override: config.allowVariableShadowing);
    // stack.localValue = _currentBytecodeModule.getGlobalConstant(type, index);
  }

  void _handleDestructuringDecl() {
    final isTopLevel = _currentBytecodeModule.readBool();
    final idCount = _currentBytecodeModule.read();
    final ids = <String, HTType?>{};
    final omittedPrefix = '##';
    var omittedIndex = 0;
    for (var i = 0; i < idCount; ++i) {
      var id = _currentBytecodeModule.getConstString();
      if (id == _lexicon.omittedMark) {
        id = omittedPrefix + (omittedIndex++).toString();
      } else {
        if (isTopLevel && currentNamespace.willExportAll) {
          currentNamespace.declareExport(id);
        }
      }
      HTType? declType;
      final hasTypeDecl = _currentBytecodeModule.readBool();
      if (hasTypeDecl) {
        declType = _handleTypeExpr();
      }
      ids[id] = declType;
    }
    final isVector = _currentBytecodeModule.readBool();
    final isMutable = _currentBytecodeModule.readBool();
    stack.subEvalFrames.add(HTDestructuringEval(
        ids: ids, isVector: isVector, isMutable: isMutable));
    // Main loop evaluates collection; endOfExec triggers frame
  }

  Map<String, HTParameter> _getParams(int paramDeclsLength) {
    final paramDecls = <String, HTParameter>{};
    for (var i = 0; i < paramDeclsLength; ++i) {
      final id = _currentBytecodeModule.getConstString();
      final isOptional = _currentBytecodeModule.readBool();
      final isVariadic = _currentBytecodeModule.readBool();
      final isNamed = _currentBytecodeModule.readBool();
      final isInitialization = _currentBytecodeModule.readBool();
      HTType? declType;
      final hasTypeDecl = _currentBytecodeModule.readBool();
      if (hasTypeDecl) {
        declType = _handleTypeExpr();
      }
      int? definitionIp;
      int? definitionLine;
      int? definitionColumn;
      final hasInitializer = _currentBytecodeModule.readBool();
      if (hasInitializer) {
        definitionLine = _currentBytecodeModule.readUint16();
        definitionColumn = _currentBytecodeModule.readUint16();
        final length = _currentBytecodeModule.readUint16();
        definitionIp = _currentBytecodeModule.ip;
        _currentBytecodeModule.skip(length);
      }
      paramDecls[id] = HTParameter(
        id: id,
        interpreter: this,
        file: _currentFile,
        module: _currentBytecodeModule.id,
        closure: currentNamespace,
        declType: declType,
        ip: definitionIp,
        line: definitionLine,
        column: definitionColumn,
        isVariadic: isVariadic,
        isOptional: isOptional,
        isNamed: isNamed,
        isInitialization: isInitialization,
      );
    }
    return paramDecls;
  }

  void _handleFuncDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final internalName = _currentBytecodeModule.getConstString();
    String? id;
    final hasId = _currentBytecodeModule.readBool();
    if (hasId) {
      id = _currentBytecodeModule.getConstString();
    }
    String? classId;
    final hasClassId = _currentBytecodeModule.readBool();
    if (hasClassId) {
      classId = _currentBytecodeModule.getConstString();
    }
    String? explicityNamespaceId;
    final hasExplicityNamespaceId = _currentBytecodeModule.readBool();
    if (hasExplicityNamespaceId) {
      explicityNamespaceId = _currentBytecodeModule.getConstString();
    }
    String? externalTypeId;
    final hasExternalTypedef = _currentBytecodeModule.readBool();
    if (hasExternalTypedef) {
      externalTypeId = _currentBytecodeModule.getConstString();
    }
    final category = FunctionCategory.values[_currentBytecodeModule.read()];
    final isPrivate = _currentBytecodeModule.readBool();
    final isAsync = _currentBytecodeModule.readBool();
    final isField = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isStatic = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      if (id != null) {
        currentNamespace.declareExport(id);
      }
    }
    final isConst = _currentBytecodeModule.readBool();
    final hasParamDecls = _currentBytecodeModule.readBool();
    final isVariadic = _currentBytecodeModule.readBool();
    final minArity = _currentBytecodeModule.read();
    final maxArity = _currentBytecodeModule.read();
    final paramLength = _currentBytecodeModule.read();
    final paramDecls = _getParams(paramLength);
    HTType? returnType;
    final hasReturnType = _currentBytecodeModule.readBool();
    if (hasReturnType) {
      returnType = _handleTypeExpr();
    }
    final declType = HTFunctionType(
        parameterTypes: paramDecls.values
            .map((param) => HTParameterType(
                declType: param.declType,
                isOptional: param.isOptional,
                isVariadic: param.isVariadic,
                id: param.isNamed ? param.id : null))
            .toList(),
        returnType: returnType);
    RedirectingConstructor? redirCtor;
    final positionalArgIps = <int>[];
    final namedArgIps = <String, int>{};
    if (category == FunctionCategory.constructor) {
      final hasRedirectingCtor = _currentBytecodeModule.readBool();
      if (hasRedirectingCtor) {
        final calleeId = _currentBytecodeModule.getConstString();
        final hasCtorName = _currentBytecodeModule.readBool();
        String? ctorName;
        if (hasCtorName) {
          ctorName = _currentBytecodeModule.getConstString();
        }
        final positionalArgIpsLength = _currentBytecodeModule.read();
        for (var i = 0; i < positionalArgIpsLength; ++i) {
          final argLength = _currentBytecodeModule.readUint16();
          positionalArgIps.add(_currentBytecodeModule.ip);
          _currentBytecodeModule.skip(argLength);
        }
        final namedArgsLength = _currentBytecodeModule.read();
        for (var i = 0; i < namedArgsLength; ++i) {
          final argName = _currentBytecodeModule.getConstString();
          final argLength = _currentBytecodeModule.readUint16();
          namedArgIps[argName] = _currentBytecodeModule.ip;
          _currentBytecodeModule.skip(argLength);
        }
        redirCtor = RedirectingConstructor(calleeId,
            key: ctorName,
            positionalArgsIp: positionalArgIps,
            namedArgsIp: namedArgIps);
      }
    }
    int? line, column, definitionIp;
    final hasDefinition = _currentBytecodeModule.readBool();
    if (hasDefinition) {
      line = _currentBytecodeModule.readUint16();
      column = _currentBytecodeModule.readUint16();
      final length = _currentBytecodeModule.readUint16();
      definitionIp = _currentBytecodeModule.ip;
      _currentBytecodeModule.skip(length);
    }
    final func = HTFunction(
      _currentFile,
      _currentBytecodeModule.id,
      this,
      internalName: internalName,
      id: id,
      classId: classId,
      explicityNamespaceId: explicityNamespaceId,
      closure: currentNamespace,
      documentation: documentation,
      isPrivate: isPrivate,
      isAbstract: !hasDefinition && !isExternal,
      isAsync: isAsync,
      isField: isField,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      category: category,
      externalTypeId: externalTypeId,
      hasParamDecls: hasParamDecls,
      paramDecls: paramDecls,
      declType: declType,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
      ip: definitionIp,
      line: line,
      column: column,
      redirectingConstructor: redirCtor,
    );
    if (!isField) {
      if ((category != FunctionCategory.constructor) || isStatic) {
        func.namespace = currentNamespace;
      }
      currentNamespace.define(func.internalName, func);
    }
    stack.push(func);
  }

  void _handleClassDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isPrivate = _currentBytecodeModule.readBool();
    final isExternal = _currentBytecodeModule.readBool();
    final isAbstract = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    final hasUserDefinedConstructor = _currentBytecodeModule.readBool();
    HTType? superType;
    final hasSuperClass = _currentBytecodeModule.readBool();
    if (hasSuperClass) {
      superType = _handleTypeExpr();
    } else {
      if (!isExternal && (id != _lexicon.idGlobalObject)) {
        assert(classRoot != null);
        // final HTClass object = classRoot ??
        // globalNamespace.memberGet(_lexicon.idGlobalObject,
        //         isRecursive: true);
        superType = HTNominalType(klass: classRoot);
      }
    }
    final isEnum = _currentBytecodeModule.readBool();
    final klass = HTClass(
      this,
      id: id,
      closure: currentNamespace,
      documentation: documentation,
      superType: superType,
      isPrivate: isPrivate,
      isExternal: isExternal,
      isAbstract: isAbstract,
      isEnum: isEnum,
      hasUserDefinedConstructor: hasUserDefinedConstructor,
    );
    currentNamespace.define(id, klass);
    currentNamespace = klass.namespace;

    if (id == _lexicon.idGlobalObject) {
      classRoot = klass;
    }
  }

  void _handleExternalEnumDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    final enumClass =
        HTExternalEnum(this, id: id, documentation: documentation);
    currentNamespace.define(id, enumClass);
    stack.push(null);
  }

  void _handleStructDecl() {
    final hasDoc = _currentBytecodeModule.readBool();
    String? documentation;
    if (hasDoc) {
      documentation = _currentBytecodeModule.readUtf8String();
    }
    final id = _currentBytecodeModule.getConstString();
    final isPrivate = _currentBytecodeModule.readBool();
    final isTopLevel = _currentBytecodeModule.readBool();
    if (isTopLevel && currentNamespace.willExportAll) {
      currentNamespace.declareExport(id);
    }
    String? prototypeId;
    final hasPrototypeId = _currentBytecodeModule.readBool();
    if (hasPrototypeId) {
      prototypeId = _currentBytecodeModule.getConstString();
    } else if (id != _lexicon.idGlobalPrototype) {
      prototypeId = _lexicon.idGlobalPrototype;
    }
    final mixinIdsLength = _currentBytecodeModule.read();
    List<String> mixinIds = [];
    for (var i = 0; i < mixinIdsLength; ++i) {
      mixinIds.add(_currentBytecodeModule.getConstString());
    }
    final staticFieldsLength = _currentBytecodeModule.readUint16();
    final staticDefinitionIp = _currentBytecodeModule.ip;
    _currentBytecodeModule.skip(staticFieldsLength);
    final fieldsLength = _currentBytecodeModule.readUint16();
    final definitionIp = _currentBytecodeModule.ip;
    _currentBytecodeModule.skip(fieldsLength);
    final struct = HTNamedStruct(
      id: id,
      interpreter: this,
      file: _currentFile,
      module: _currentBytecodeModule.id,
      closure: currentNamespace,
      documentation: documentation,
      isPrivate: isPrivate,
      isTopLevel: isTopLevel,
      prototypeId: prototypeId,
      mixinIds: mixinIds,
      staticDefinitionIp: staticDefinitionIp,
      definitionIp: definitionIp,
    );
    currentNamespace.define(id, struct);
    stack.push(null);
  }
}
