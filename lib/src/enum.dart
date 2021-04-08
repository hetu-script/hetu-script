import 'type.dart';
import 'object.dart';
import 'lexicon.dart';
import 'errors.dart';
import 'interpreter.dart';
import 'declaration.dart';

/// [HTEnum] is the Dart implementation of the enum declaration in Hetu.
class HTEnum with HTDeclaration, HTObject, InterpreterRef {
  @override
  final HTType rtType = HTType.ENUM;

  /// The enumeration item of this [HTEnum].
  final Map<String, HTEnumItem> enums;

  /// Wether this is a external enum, which is declared in Dart codes.
  final bool isExtern;

  /// Create a default [HTEnum] class.
  HTEnum(String id, this.enums, Interpreter interpreter,
      {this.isExtern = false}) {
    this.interpreter = interpreter;
    this.id = id;
  }

  @override
  bool contains(String varName) => enums.containsKey(varName);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    if (!isExtern) {
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
class HTEnumItem with HTObject {
  @override
  final HTType rtType;

  /// The index of this enum item.
  final int index;

  /// The name of this enum item.
  final String id;

  @override
  String toString() => '${rtType.typeName}$id';

  /// Default [HTEnumItem] constructor.
  HTEnumItem(this.index, this.id, this.rtType);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'rtType':
        return rtType;
      case 'index':
        return index;
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
