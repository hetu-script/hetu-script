import '../core/declaration.dart';
import '../core/class/class.dart';
import '../type_system/type.dart';
import '../type_system/nominal_type.dart';
import '../grammar/lexicon.dart';
import '../error/errors.dart';
import 'interpreter.dart';
import 'bytecode_source.dart' show GotoInfo;

/// Bytecode implementation of [HTDeclaration].
class HTBytecodeDeclaration extends HTDeclaration with GotoInfo {
  @override
  final Hetu interpreter;

  final bool typeInferrence;

  HTType? _declType;

  @override
  HTType get declType => _declType ?? HTType.ANY;

  var _isInitializing = false;

  // var _isTypeInitialized = false;

  /// Create a standard [HTBytecodeDeclaration].
  ///
  /// A [HTDeclaration] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be used within a script.
  HTBytecodeDeclaration(String id, this.interpreter, String moduleFullName,
      {String? classId,
      dynamic value,
      HTType? declType,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      Function? getter,
      Function? setter,
      bool isExternal = false,
      this.typeInferrence = true,
      bool isStatic = false,
      bool isImmutable = false})
      : super(id, interpreter,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            isImmutable: isImmutable) {
    this.moduleFullName = moduleFullName;
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;

    if (declType != null) {
      _declType = declType;
    }

    if (value != null) {
      if (_declType == null && typeInferrence) {
        final encap = interpreter.encapsulate(value);
        _declType = encap.valueType;
      }
      this.value = value;
    }

    // if (declType != null) {
    //   _declType = declType;

    //   if (_declType is HTFunctionDeclarationType ||
    //       _declType is HTObjectType ||
    //       (HTLexicon.primitiveType.contains(declType.id))) {
    //     _isTypeInitialized = true;
    //   }
    // } else {
    //   if (!typeInferrence || (definitionIp == null)) {
    //     _declType = HTType.ANY;
    //     _isTypeInitialized = true;
    //   }
    // }
  }

  /// initialize the declared type if it's a class name.
  /// only return the [HTClass] when its a non-external class
  // void _initializeType() {
  //   final resolvedType = HTType.resolve(_declType!, interpreter);
  //   _declType = resolvedType.type;
  //   _declClass = resolvedType.klass;
  //   _isTypeInitialized = true;
  // }

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

        if (_declType == null) {
          if (typeInferrence) {
            if (initVal != null) {
              _declType = interpreter.encapsulate(initVal).valueType;
            } else {
              throw HTError.errorNullInit();
            }
          }
        }

        value = initVal;

        _isInitializing = false;
      } else {
        throw HTError.circleInit(id);
      }
    } else {
      value = null; // null 也要 assign 一下，因为需要类型检查
    }
  }

  dynamic _computeValue(dynamic value, HTType type) {
    final resolvedType = type.isResolved ? type : type.resolve(interpreter);

    if (resolvedType is HTNominalType && value is Map) {
      return resolvedType.klass.createInstanceFromJson(value);
    }

    // basically doing a type erasure here.
    if ((value is List) &&
        (type.id == HTLexicon.list) &&
        (type.typeArgs.isNotEmpty)) {
      final computedValueList = [];
      for (final item in value) {
        final computedValue = _computeValue(item, type.typeArgs.first);
        computedValueList.add(computedValue);
      }
      return computedValueList;
    } else if ((value is Map) &&
        (type.id == HTLexicon.map) &&
        (type.typeArgs.length >= 2)) {
      final mapValueTypeResolveResult = type.typeArgs[1].resolve(interpreter);
      if (mapValueTypeResolveResult is HTNominalType) {
        final computedValueMap = {};
        for (final entry in value.entries) {
          final computedValue = mapValueTypeResolveResult.klass
              .createInstanceFromJson(entry.value);
          computedValueMap[entry.key] = computedValue;
        }
        return computedValueMap;
      }
    } else {
      final encapsulation = interpreter.encapsulate(value);
      final valueType = encapsulation.valueType;
      if (valueType.isNotA(resolvedType)) {
        throw HTError.type(id, valueType.toString(), type.toString());
      }
      return value;
    }
  }

  /// Assign a new value to this variable,
  /// will perform [HTType] check during this process.
  @override
  set value(dynamic value) {
    super.value = _computeValue(value, _declType ?? HTType.ANY);
  }

  @override
  HTBytecodeDeclaration clone() =>
      HTBytecodeDeclaration(id, interpreter, moduleFullName,
          classId: classId,
          value: value,
          declType: declType,
          definitionIp: definitionIp,
          definitionLine: definitionLine,
          definitionColumn: definitionColumn,
          typeInferrence: typeInferrence,
          isExternal: isExternal,
          isImmutable: isImmutable,
          isStatic: isStatic);
}
