import 'type.dart';
import '../errors.dart';
import '../lexicon.dart';

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

  void define(String varName,
          {HTTypeId? declType,
          dynamic value,
          bool isExtern = false,
          bool isImmutable = false,
          bool isNullable = false,
          bool isDynamic = false}) =>
      throw HTErrorUndefined(varName);

  dynamic fetch(String varName, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);

  void assign(String varName, dynamic value, {String from = HTLexicon.global}) => throw HTErrorUndefined(varName);
}
