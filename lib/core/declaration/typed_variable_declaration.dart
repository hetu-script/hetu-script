// import '../../error/errors.dart';
import '../../type/type.dart';
import 'variable_declaration.dart';
// import '../../core/abstract_interpreter.dart';
// import '../../core/function/abstract_function.dart';

/// A [TypedVariableDeclaration] is basically a binding between a symbol and a value
class TypedVariableDeclaration extends VariableDeclaration {
  /// The declared [HTType] of this symbol, will be used to
  /// compare with the value type to
  /// determine wether an value binding (assignment) is legal.
  final HTType declType;

  final bool typeInferrence;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  TypedVariableDeclaration(String id, String moduleFullName, String libraryName,
      {String? classId,
      this.declType = HTType.ANY,
      this.typeInferrence = false,
      bool isExternal = false,
      bool isMutable = false,
      bool isStatic = false})
      : super(id, moduleFullName, libraryName,
            classId: classId, isMutable: isMutable, isExternal: isExternal);

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
  TypedVariableDeclaration clone() =>
      TypedVariableDeclaration(id, moduleFullName, libraryName,
          classId: classId,
          declType: declType,
          typeInferrence: typeInferrence,
          isStatic: isStatic,
          isMutable: isMutable,
          isExternal: isExternal);
}
