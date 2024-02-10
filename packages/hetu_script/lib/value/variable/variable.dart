import '../../external/external_class.dart';
import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../bytecode/goto_info.dart';
import '../../value/namespace/namespace.dart';
import '../../declaration/variable/variable_declaration.dart';

/// Variable is a binding between an symbol and a value
class HTVariable extends HTVariableDeclaration with InterpreterRef, GotoInfo {
  final HTNamespace _closure;

  @override
  HTNamespace get closure => _closure;

  // Use dynamic type to save external values
  dynamic _value;

  var _isInitialized = false;
  var _isInitializing = false;

  HTExternalClass? externalClass;

  // var _isTypeInitialized = false;

  /// Create a [HTVariable].
  ///
  /// If it has initializer code, it will
  /// have to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be acessed within a script.
  HTVariable({
    required super.id,
    required HTInterpreter interpreter,
    String? file,
    String? module,
    super.classId,
    required HTNamespace closure,
    super.documentation,
    super.declType,
    dynamic value,
    super.isPrivate = false,
    super.isExternal = false,
    super.isStatic = false,
    super.isConst = false,
    super.isMutable = false,
    super.isTopLevel = false,
    super.isField = false,
    super.lateFinalize = false,
    int? ip,
    int? line,
    int? column,
  })  : _closure = closure,
        super(closure: closure) {
    this.interpreter = interpreter;
    if (file != null) {
      this.file = file;
    }
    if (module != null) {
      this.module = module;
    }
    this.ip = ip;
    this.line = line;
    this.column = column;

    if (value != null) {
      this.value = value;
    }
  }

  /// Initialize this variable with its declared initializer bytecode
  void initialize() {
    if (ip != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
          context: HTContext(
            file: file,
            module: module,
            ip: ip!,
            namespace: closure,
            line: line,
            column: column,
          ),
        );
        value = initVal;
        _isInitialized = true;
        _isInitializing = false;
      } else {
        throw HTError.circleInit(id!);
      }
    } else {
      value = null; // assign it even if it's null, for type check
    }
  }

  /// Assign a new value to this variable.
  @override
  set value(dynamic value) {
    if (!isMutable && _isInitialized) {
      throw HTError.immutable(id!);
    }
    // if (interpreter.config.checkTypeAnnotationAtRuntime) {
    //   if (declType != null) {
    //     // final resolvedType =
    //     //     declType!.isResolved ? declType : declType!.resolve(closure);
    //     final valueType = interpreter.typeof(value);
    //     if (valueType.isNotA(declType!)) {
    //       final err = HTError.assignType(
    //         id!,
    //         interpreter.lexicon.stringify(valueType),
    //         interpreter.lexicon.stringify(declType),
    //       );
    //       print(
    //           "hetu: (warning) - ${err.message} (at [${interpreter.currentFileName}:${interpreter.currentLine}:${interpreter.currentColumn}])");
    //     }
    //   }
    // }
    _value = value;
    _isInitialized = true;
  }

  @override
  dynamic get value {
    if (lateFinalize && !_isInitialized) {
      throw HTError.uninitialized(id!);
    }
    if (!isExternal) {
      if (_value == null && (ip != null)) {
        initialize();
      }
      return _value;
    } else {
      final externalClass = interpreter.fetchExternalClass(classId!);
      final value = externalClass.memberGet(id!);
      return value;
    }
  }

  @override
  void resolve({bool resolveType = true}) {
    super.resolve(
        resolveType:
            resolveType || interpreter.config.checkTypeAnnotationAtRuntime);
  }

  // dynamic _computeValue(dynamic value, HTType type) {
  //   final resolvedType = type.isResolved ? type : type.resolve(interpreter);
  //   if (resolvedType is HTNominalType && value is Map) {
  //     return resolvedType.klass.createInstanceFromJson(value);
  //   }
  //   // basically doing a type erasure here.
  //   if ((value is List) &&
  //       (type.id == HTLexicon.list) &&
  //       (type.typeArgs.isNotEmpty)) {
  //     final computedValueList = [];
  //     for (final item in value) {
  //       final computedValue = _computeValue(item, type.typeArgs.first);
  //       computedValueList.add(computedValue);
  //     }
  //     return computedValueList;
  //   } else if ((value is Map) &&
  //       (type.id == HTLexicon.map) &&
  //       (type.typeArgs.length >= 2)) {
  //     final mapValueTypeResolveResult = type.typeArgs[1].resolve(interpreter);
  //     if (mapValueTypeResolveResult is HTNominalType) {
  //       final computedValueMap = {};
  //       for (final entry in value.entries) {
  //         final computedValue = mapValueTypeResolveResult.klass
  //             .createInstanceFromJson(entry.value);
  //         computedValueMap[entry.key] = computedValue;
  //       }
  //       return computedValueMap;
  //     }
  //   } else {
  //     final encapsulation = interpreter.encapsulate(value);
  //     final valueType = encapsulation.valueType;
  //     if (valueType.isNotA(resolvedType)) {
  //       throw HTError.type(id, valueType.toString(), type.toString());
  //     }
  //     return value;
  //   }
  // }

  @override
  HTVariable clone() => HTVariable(
      id: id!,
      interpreter: interpreter,
      file: file,
      module: module,
      classId: classId,
      closure: closure,
      documentation: documentation,
      declType: declType,
      value: _value,
      isPrivate: isPrivate,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isMutable: isMutable,
      isTopLevel: isTopLevel,
      isField: isField,
      lateFinalize: lateFinalize,
      ip: ip,
      line: line,
      column: column);
}
