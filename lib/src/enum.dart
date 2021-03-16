import 'type.dart';
import 'object.dart';
import 'lexicon.dart';
import 'errors.dart';

class HT_Enum extends HT_NamedObject {
  @override
  final HT_TypeId typeid = HT_TypeId.ENUM;

  final Map<String, HT_EnumItem> defs;

  HT_Enum(String id, this.defs) : super(id);

  @override
  bool contains(String varName) => defs.containsKey(varName);

  @override
  void define(String varName,
      {HT_TypeId? declType,
      dynamic value,
      bool isExtern = false,
      bool isImmutable = false,
      bool isNullable = false,
      bool isDynamic = false}) {
    assert(value is HT_EnumItem);

    if (!defs.containsKey(varName)) {
      return defs[varName] = value;
    }
    throw HT_Error_Defined_Runtime(id);
  }

  @override
  dynamic fetch(String varName, {String? from}) {
    if (defs.containsKey(varName)) {
      return defs[varName]!;
    } else if (varName == HT_Lexicon.values) {
      return defs.values;
    }
    throw HT_Error_Undefined(varName);
  }

  @override
  void assign(String varName, dynamic value, {String? from}) {
    if (defs.containsKey(varName)) {
      throw HT_Error_Immutable(varName);
    }
    throw HT_Error_Undefined(varName);
  }
}

class HT_EnumItem extends HT_NamedObject {
  @override
  final HT_TypeId typeid;

  HT_EnumItem(String id, this.typeid) : super(id);
}
