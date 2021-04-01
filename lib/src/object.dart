import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';

class _HTNull with HTObject {
  const _HTNull();

  @override
  HTTypeId get typeid => HTTypeId.NULL;
}

/// HTObject是命名空间、类、实例和枚举类的基类
mixin HTObject {
  static const NULL = _HTNull();
  //bool used = false;

  HTTypeId get typeid => HTTypeId.object;

  bool contains(String varName) => throw HTErrorUndefined(varName);

  dynamic memberGet(String varName, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);

  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);

  dynamic subGet(dynamic key) => throw HTErrorUndefined(key);

  void subSet(String key, dynamic value) => throw HTErrorUndefined(key);

  bool isA(HTTypeId otherTypeId) {
    var result = true;
    if (otherTypeId.id != HTLexicon.ANY) {
      if (typeid.id == otherTypeId.id) {
        if (typeid.arguments.length >= otherTypeId.arguments.length) {
          for (var i = 0; i < otherTypeId.arguments.length; ++i) {
            if (typeid.arguments[i].isNotA(otherTypeId.arguments[i])) {
              result = false;
              break;
            }
          }
        } else {
          result = false;
        }
      } else {
        if (typeid.id == HTLexicon.NULL && otherTypeId.isNullable) {
          result = true;
        } else {
          result = false;
        }
      }
    }
    return result;
  }

  bool isNotA(HTTypeId typeid) => !isA(typeid);
}
