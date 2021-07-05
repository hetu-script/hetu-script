import '../../grammar/lexicon.dart';
import '../object.dart';

/// Struct is a prototype based object
/// unlike class, you have to use 'this' to
/// access struct member within its own methods
class HTStruct with HTObject {
  final fields = <String, dynamic>{};

  HTStruct? prototype;

  HTStruct({this.prototype}) {
    fields[HTLexicon.prototype] = prototype;
  }

  @override
  bool contains(String varName) => fields.containsKey(varName);

  void define(String id, dynamic value,
      {bool override = false, bool error = true}) {
    fields[id] = value;
  }

  void delete(String id) {
    fields.remove(id);
  }

  @override
  dynamic memberGet(String varName) {
    if (fields.containsKey(varName)) {
      return fields[varName];
    }
    if (prototype != null) {
      return prototype!.memberGet(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue) {
    if (fields.containsKey(varName)) {
      final decl = fields[varName]!;
      decl.value = varValue;
      return;
    }
    if (prototype != null) {
      prototype!.memberSet(varName, varValue);
      return;
    }
  }
}
