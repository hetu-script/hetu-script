import 'common.dart';
import 'type.dart';
import 'value.dart';
import 'lexicon.dart';
import 'errors.dart';

class HT_Enum extends HT_Value with HT_Type {
  @override
  final HT_TypeId typeid = HT_TypeId.ENUM;

  final Map<String, HT_EnumItem> defs;

  HT_Enum(String id, this.defs) : super(id);

  @override
  bool contains(String varName) => defs.containsKey(varName);

  @override
  void define(String varName, CodeRunner interpreter,
      {int? line,
      int? column,
      HT_TypeId? declType,
      dynamic value,
      bool isExtern = false,
      bool isImmutable = false,
      bool isNullable = false,
      bool isDynamic = false}) {
    assert(value is HT_EnumItem);

    if (!defs.containsKey(varName)) {
      return defs[varName] = value;
    }
    throw HTErr_Defined(id, interpreter.curFileName, line, column);
  }

  @override
  dynamic fetch(String varName, int? line, int? column, CodeRunner interpreter,
      {bool error = true, String from = HT_Lexicon.global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      return defs[varName]!;
    }
    throw HTErr_Undefined(varName, interpreter.curFileName, line, column);
  }

  @override
  void assign(String varName, dynamic value, int? line, int? column, CodeRunner interpreter,
      {bool error = true, String from = HT_Lexicon.global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      throw HTErr_Immutable(varName, interpreter.curFileName, line, column);
    }
    throw HTErr_Undefined(varName, interpreter.curFileName, line, column);
  }
}

class HT_EnumItem with HT_Type {
  late final HT_Enum parent;

  final String id;

  @override
  HT_TypeId get typeid => parent.typeid;

  HT_EnumItem(this.id, this.parent);
}
