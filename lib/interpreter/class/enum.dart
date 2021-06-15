import '../../error/errors.dart';
import '../../grammar/lexicon.dart';
import '../interpreter.dart';
import '../../type/type.dart';
import '../../core/object.dart';
import '../../core/declaration/variable_declaration.dart';

/// [HTEnum] is the Dart implementation of the enum declaration in Hetu.
class HTEnum extends VariableDeclaration with HTObject, HetuRef {
  @override
  HTType get valueType => HTType.ENUM;

  /// The enumeration item of this [HTEnum].
  final Map<String, HTEnumItem> enums;

  /// Create a default [HTEnum] class.
  HTEnum(String id, this.enums, String moduleFullName, String libraryName,
      Hetu interpreter, {String? classId, bool isExternal = false})
      : super(id, moduleFullName, libraryName,
            classId: classId, isExternal: isExternal) {
    this.interpreter = interpreter;
  }

  @override
  bool contains(String varName) => enums.containsKey(varName);

  @override
  dynamic memberGet(String varName,
      {String from = HTLexicon.global, bool error = true}) {
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

    if (error) {
      throw HTError.undefined(varName);
    }
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
  dynamic memberGet(String varName,
      {String from = HTLexicon.global, bool error = true}) {
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
        if (error) {
          throw HTError.undefinedMember(varName);
        }
    }
  }
}
