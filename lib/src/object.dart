import 'type.dart';
import 'errors.dart';

class _HT_Null with HT_Type {
  const _HT_Null();

  @override
  HT_TypeId get typeid => HT_TypeId.NULL;
}

/// HT_Object是命名空间、类、实例和枚举类的基类
abstract class HT_Object with HT_Type {
  static const NULL = _HT_Null();
  //bool used = false;

  bool contains(String varName) => throw HT_Error_Undefined(varName);

  void define(String varName,
          {HT_TypeId? declType,
          dynamic value,
          bool isExtern = false,
          bool isImmutable = false,
          bool isNullable = false,
          bool isDynamic = false}) =>
      throw HT_Error_Undefined(varName);

  dynamic fetch(String varName, {String? from}) => throw HT_Error_Undefined(varName);

  void assign(String varName, dynamic value, {String? from}) => throw HT_Error_Undefined(varName);
}

abstract class HT_NamedObject extends HT_Object {
  final String id;
  HT_NamedObject(this.id);
}
