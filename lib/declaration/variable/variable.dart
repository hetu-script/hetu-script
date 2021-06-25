import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/compiler.dart' show GotoInfo;
import '../../type/type.dart';
import '../../source/source.dart';
import '../namespace.dart';
import '../declaration.dart';

/// Variable is a binding between an element and a value
class HTVariable extends HTDeclaration with HetuRef, GotoInfo {
  @override
  final String id;

  // 为了允许保存宿主程序变量，这里是dynamic，而不是HTObject
  dynamic _value;

  var _isInitializing = false;

  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // var _isTypeInitialized = false;

  /// Create a standard [HTVariable].
  /// has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be acessed within a script.
  HTVariable(this.id, Hetu interpreter,
      {String? classId,
      HTNamespace? closure,
      HTType? declType,
      dynamic value,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isMutable = false,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn})
      : super(
            id: id,
            classId: classId,
            closure: closure,
            declType: declType,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isMutable: isMutable) {
    this.interpreter = interpreter;
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;

    if (value != null) {
      this.value = value;
      _isInitialized = true;
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

  /// Initialize this variable with its declared initializer bytecode
  void initialize() {
    if (isInitialized) return;

    if (definitionIp != null) {
      if (!_isInitializing) {
        _isInitializing = true;
        final initVal = interpreter.execute(
            moduleFullName: source?.fullName,
            libraryName: source?.libraryName,
            ip: definitionIp!,
            namespace: closure,
            line: definitionLine,
            column: definitionColumn);

        value = initVal;

        _isInitializing = false;
      } else {
        throw HTError.circleInit(name);
      }
    } else {
      value = null; // null 也要 assign 一下，因为需要类型检查
    }
  }

  /// Assign a new value to this variable.
  @override
  set value(dynamic value) {
    _value = value;
    _isInitialized = true;
  }

  @override
  dynamic get value {
    if (!isExternal) {
      if (!isInitialized) {
        initialize();
      }
      return _value;
    } else {
      final externClass = interpreter.fetchExternalClass(classId!);
      return externClass.memberGet(id);
    }
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
  HTVariable clone() => HTVariable(id, interpreter,
      classId: classId,
      closure: closure,
      declType: declType,
      value: value,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      isMutable: isMutable,
      definitionIp: definitionIp,
      definitionLine: definitionLine,
      definitionColumn: definitionColumn);
}
