import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';

class _HTNull with HTType {
  const _HTNull();

  @override
  HTTypeId get typeid => HTTypeId.NULL;
}

/// HTObject是命名空间、类、实例和枚举类的基类
abstract class HTObject with HTType {
  static const NULL = _HTNull();
  //bool used = false;

  bool contains(String varName) => throw HTErrorUndefined(varName);

  dynamic memberGet(String varName, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);

  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);

  dynamic subGet(dynamic key) => throw HTErrorUndefined(key);

  void subSet(String key, dynamic value) => throw HTErrorUndefined(key);
}
