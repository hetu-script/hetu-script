import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';
import 'declaration.dart';

class _HTNull with HTType {
  const _HTNull();

  @override
  HTTypeId get typeid => HTTypeId.NULL;
}

/// HTObject是命名空间、类、实例和枚举类的基类
abstract class HTObject with HTType {
  static const NULL = _HTNull();
  //bool used = false;

  final String fullName = '';

  bool contains(String varName) => throw HTErrorUndefined(varName);

  void define(HTDeclaration decl, {bool override = false}) => throw HTErrorUndefined(decl.id);

  dynamic memberGet(String varName, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);

  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);

  dynamic subGet(dynamic key, {String from = HTLexicon.global}) => throw HTErrorUndefined(key);

  void subSet(String key, dynamic value, {String from = HTLexicon.global}) => throw HTErrorUndefined(key);
}
