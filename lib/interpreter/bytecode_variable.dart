import '../implementation/variable.dart';
import '../implementation/type.dart';
import '../implementation/errors.dart';
import '../implementation/class.dart';
import '../implementation/lexicon.dart';
import 'bytecode_interpreter.dart';
import 'bytecode.dart' show GotoInfo;

/// Bytecode implementation of [HTVariable].
class HTBytecodeVariable extends HTVariable with GotoInfo, HetuRef {
  final bool typeInferrence;

  /// Whether this variable is immutable.
  @override
  final bool isImmutable;

  var _isInitializing = false;

  var _isTypeInitialized = false;

  HTType? _declType;

  // The class decl, if this is a internal class
  HTClass? _declClass;

  /// The [HTType] of this variable, will be used to
  /// determine wether an assignment is legal.
  HTType? get declType => _declType;

  /// Create a standard [HTBytecodeVariable].
  ///
  /// A [HTVariable] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be used within a script.
  HTBytecodeVariable(String id, Hetu interpreter, String moduleFullName,
      {String? classId,
      dynamic value,
      HTType? declType,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      Function? getter,
      Function? setter,
      bool isExtern = false,
      this.typeInferrence = false,
      this.isImmutable = false,
      bool isStatic = false})
      : super(id,
            classId: classId,
            value: value,
            getter: getter,
            setter: setter,
            isExtern: isExtern,
            isStatic: isStatic) {
    this.interpreter = interpreter;
    this.moduleFullName = moduleFullName;
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;

    if (declType != null) {
      _declType = declType;

      if (_declType is HTFunctionType ||
          _declType is HTObjectType ||
          (HTLexicon.primitiveType.contains(declType.typeName))) {
        _isTypeInitialized = true;
      }
    } else {
      if (!typeInferrence || (definitionIp == null)) {
        _declType = HTType.ANY;
        _isTypeInitialized = true;
      }
    }
  }

  /// initialize the declared type if it's a class name.
  /// only return the [HTClass] when its a non-external class
  void _initializeType() {
    final resolvedType = HTType.resolve(_declType!, interpreter);
    _declType = resolvedType.type;
    _declClass = resolvedType.klass;
    _isTypeInitialized = true;
  }

  /// Initialize this variable with its declared initializer bytecode
  @override
  void initialize() {
    if (isInitialized) return;

    if (definitionIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
            moduleFullName: moduleFullName,
            ip: definitionIp!,
            namespace: closure,
            line: definitionLine,
            column: definitionColumn);

        assign(initVal);

        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      assign(null); // null 也要 assign 一下，因为需要类型检查
    }
  }

  dynamic _computeValue(dynamic value, HTType type, [HTClass? klass]) {
    if (klass == null) {
      final resolveResult = HTType.resolve(type, interpreter);
      klass = resolveResult.klass;
    }
    if (klass != null) {
      return klass.createInstanceFromJson(value);
    } else {
      // basically doing a type erasure here.
      if ((value is List) &&
          (type.typeName == HTLexicon.list) &&
          (type.typeArgs.isNotEmpty)) {
        final computedValueList = [];
        for (final item in value) {
          final computedValue = _computeValue(item, type.typeArgs.first);
          computedValueList.add(computedValue);
        }
        return computedValueList;
      } else if ((value is Map) &&
          (type.typeName == HTLexicon.map) &&
          (type.typeArgs.length >= 2)) {
        final mapValueTypeResolveResult =
            HTType.resolve(type.typeArgs[1], interpreter);
        if (mapValueTypeResolveResult.klass != null) {
          final computedValueMap = {};
          for (final entry in value.entries) {
            final computedValue = mapValueTypeResolveResult.klass!
                .createInstanceFromJson(entry.value);
            computedValueMap[entry.key] = computedValue;
          }
          return computedValueMap;
        }
      } else {
        final encapsulation = interpreter.encapsulate(value);
        final valueType = encapsulation.objectType;
        if (valueType.isNotA(_declType!)) {
          throw HTError.type(id, valueType.toString(), _declType.toString());
        }
        return value;
      }
    }
  }

  /// Assign a new value to this variable,
  /// will perform [HTType] check during this process.
  @override
  void assign(dynamic value) {
    if (_declType != null) {
      if (!_isTypeInitialized) {
        _initializeType();
      }
    } else {
      if ((_declType == null) && typeInferrence && (value != null)) {
        _declType = interpreter.encapsulate(value).objectType;
        _isTypeInitialized = true;
      }
    }

    super.assign(_computeValue(value, _declType!, _declClass));
  }

  /// Create a copy of this variable declaration,
  /// mainly used on class member inheritance and function arguments passing.
  @override
  HTBytecodeVariable clone() =>
      HTBytecodeVariable(id, interpreter, moduleFullName,
          classId: classId,
          value: value,
          declType: declType,
          definitionIp: definitionIp,
          definitionLine: definitionLine,
          definitionColumn: definitionColumn,
          getter: getter,
          setter: setter,
          typeInferrence: typeInferrence,
          isExtern: isExtern,
          isImmutable: isImmutable,
          isStatic: isStatic);
}

/// An implementation of [HTVariable] for function parameter declaration.
class HTBytecodeParameter extends HTBytecodeVariable {
  late final HTParameterType paramType;

  /// Create a standard [HTBytecodeParameter].
  HTBytecodeParameter(String id, Hetu interpreter, String moduleFullName,
      {dynamic value,
      HTType? declType,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      bool isOptional = false,
      bool isNamed = false,
      bool isVariadic = false})
      : super(id, interpreter, moduleFullName,
            value: value,
            declType: declType,
            definitionIp: definitionIp,
            definitionLine: definitionLine,
            definitionColumn: definitionColumn,
            typeInferrence: false,
            isImmutable: false) {
    final paramDeclType = declType ?? HTType.ANY;
    paramType = HTParameterType(paramDeclType.typeName,
        typeArgs: paramDeclType.typeArgs,
        isNullable: paramDeclType.isNullable,
        isOptional: isOptional,
        isNamed: isNamed,
        isVariadic: isVariadic);
  }

  @override
  HTBytecodeParameter clone() {
    return HTBytecodeParameter(id, interpreter, moduleFullName,
        value: value,
        declType: declType,
        definitionIp: definitionIp,
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isOptional: paramType.isOptional,
        isNamed: paramType.isNamed,
        isVariadic: paramType.isVariadic);
  }
}
