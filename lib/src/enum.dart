import 'type.dart';
import 'object.dart';
import 'lexicon.dart';
import 'errors.dart';

class HTEnum extends HTObject {
  @override
  final HTTypeId typeid = HTTypeId.ENUM;

  final String id;

  final Map<String, HTEnumItem> defs;

  HTEnum(this.id, this.defs);

  @override
  bool contains(String varName) => defs.containsKey(varName);

  @override
  void define(String varName,
      {HTTypeId? declType,
      dynamic value,
      bool isExtern = false,
      bool isImmutable = false,
      bool isNullable = false,
      bool isDynamic = false}) {
    assert(value is HTEnumItem);

    if (!defs.containsKey(varName)) {
      return defs[varName] = value;
    }
    throw HTErrorDefined_Runtime(id);
  }

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (defs.containsKey(varName)) {
      return defs[varName]!;
    } else if (varName == HTLexicon.values) {
      return defs.values;
    }
    throw HTErrorUndefined(varName);
  }

  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (defs.containsKey(varName)) {
      throw HTErrorImmutable(varName);
    }
    throw HTErrorUndefined(varName);
  }
}

class HTEnumItem extends HTObject {
  @override
  final HTTypeId typeid;

  final String id;

  HTEnumItem(this.id, this.typeid);
}
