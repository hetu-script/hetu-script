import '../../error/error.dart';
import '../../grammar/lexicon.dart';
import '../../interpreter/interpreter.dart';
import '../../source/source.dart';
import '../../type/type.dart';
import '../element.dart';
import '../object.dart';

/// [HTEnum] is the Dart implementation of the enum declaration in Hetu.
class HTEnum extends HTElement with HTObject, HetuRef {
  @override
  HTType get valueType => HTType.ENUM;

  /// The enumeration item of this [HTEnum].
  final Map<String, HTEnumItem> enums;

  /// Create a default [HTEnum] class.
  HTEnum(String id, this.enums, Hetu interpreter,
      {String? classId, HTSource? source, bool isExternal = false})
      : super(
            id: id, classId: classId, source: source, isExternal: isExternal) {
    this.interpreter = interpreter;
  }

  @override
  bool contains(String field) => enums.containsKey(field);

  @override
  dynamic memberGet(String field, {bool error = true}) {
    if (!isExternal) {
      if (enums.containsKey(field)) {
        return enums[field]!;
      } else if (field == HTLexicon.values) {
        return enums.values.toList();
      }
    } else {
      final externEnumClass = interpreter.fetchExternalClass(id!);
      return externEnumClass.memberGet(field);
    }

    // TODO: elementAt() 方法

    if (error) {
      throw HTError.undefined(field);
    }
  }

  @override
  void memberSet(String field, dynamic varValue, {bool error = true}) {
    if (enums.containsKey(field)) {
      throw HTError.immutable(field);
    }
    throw HTError.undefined(field);
  }

  @override
  HTEnum clone() => HTEnum(id!, enums, interpreter,
      classId: classId, source: source, isExternal: isExternal);
}

/// The Dart implementation of the enum item in Hetu.
class HTEnumItem<T> with HTObject {
  @override
  final HTType valueType;

  /// The value of this enum item.
  final T value;

  /// The name of this enum item.
  final String id;

  @override
  String toString() => '${valueType.id}$id';

  /// Default [HTEnumItem] constructor.
  HTEnumItem(this.value, this.id, this.valueType);

  @override
  dynamic memberGet(String field, {bool error = true}) {
    switch (field) {
      case 'index':
        return value;
      case 'value':
        return value;
      case 'name':
        return id;
      default:
        if (error) {
          throw HTError.undefinedMember(field);
        }
    }
  }
}
