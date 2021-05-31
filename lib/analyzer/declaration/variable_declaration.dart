// import '../../error/errors.dart';
import '../../type_system/type.dart';
import '../../core/declaration/abstract_declaration.dart';
// import '../../core/abstract_interpreter.dart';
// import '../../core/function/abstract_function.dart';

/// A [HTDeclaration] is basically a binding between a symbol and a value
class HTDeclaration extends AbstractDeclaration {
  @override
  dynamic get value => null;

  @override
  set value(dynamic newVal) {}

  HTType? _declType;

  final bool typeInferrence;

  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type to
  /// determine wether an value binding (assignment) is legal.
  HTType get declType => _declType ?? HTType.ANY;

  final bool isStatic;

  /// Whether this variable is immutable.
  final bool isImmutable;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  HTDeclaration(String id,
      {String? classId,
      HTType? declType,
      this.typeInferrence = false,
      this.isStatic = false,
      this.isImmutable = true,
      bool isExternal = false})
      : super(id, classId: classId, isExternal: isExternal) {
    if (declType != null) {
      _declType = declType;
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

  /// Create a copy of this variable declaration,
  /// mainly used on class member inheritance and function arguments passing.
  HTDeclaration clone() => HTDeclaration(id,
      classId: classId,
      declType: declType,
      typeInferrence: typeInferrence,
      isStatic: isStatic,
      isImmutable: isImmutable,
      isExternal: isExternal);
}
