import '../../error/errors.dart';
import '../../grammar/lexicon.dart';
import '../abstract_interpreter.dart';
import '../../type_system/type.dart';
import '../../type_system/value_type.dart';
import '../object.dart';

/// [HTEnum] is the Dart implementation of the enum declaration in Hetu.
class HTEnum with HTObject, InterpreterRef {
  final String id;

  @override
  HTType get valueType => HTType.ENUM;

  /// The enumeration item of this [HTEnum].
  final Map<String, HTEnumItem> enums;

  /// Wether this is a external enum, which is declared in Dart codes.
  final bool isExternal;

  /// Create a default [HTEnum] class.
  HTEnum(this.id, this.enums, HTInterpreter interpreter,
      {this.isExternal = false}) {
    this.interpreter = interpreter;
  }

  @override
  bool contains(String varName) => enums.containsKey(varName);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    if (!isExternal) {
      if (enums.containsKey(varName)) {
        return enums[varName]!;
      } else if (varName == HTLexicon.values) {
        return enums.values.toList();
      }
    } else {
      final externEnumClass = interpreter.fetchExternalClass(id);
      return externEnumClass.memberGet(varName);
    }

    // TODO: elementAt() 方法

    throw HTError.undefined(varName);
  }

  @override
  void memberSet(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    if (enums.containsKey(varName)) {
      throw HTError.immutable(varName);
    }
    throw HTError.undefined(varName);
  }
}

/// The Dart implementation of the enum item in Hetu.
class HTEnumItem<T> with HTObject {
  @override
  final HTValueType valueType;

  /// The value of this enum item.
  final T value;

  /// The name of this enum item.
  final String id;

  @override
  String toString() => '${valueType.id}$id';

  /// Default [HTEnumItem] constructor.
  HTEnumItem(this.value, this.id, this.valueType);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'valueType':
        return valueType;
      case 'index':
        return value;
      case 'value':
        return value;
      case 'name':
        return id;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      default:
        throw HTError.undefinedMember(varName);
    }
  }
}
