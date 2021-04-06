import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';

class _HTNull with HTObject {
  const _HTNull();

  @override
  String toString() => HTLexicon.NULL;

  @override
  HTTypeId get typeid => HTTypeId.NULL;
}

/// Almost everything within Hetu is a [HTObject].
/// Includes [HTTypeid], [HTNamespace], [HTClass], [HTInstance],
/// [HTEnum], [HTExternalClass], [HTFunction].
mixin HTObject {
  /// The [null] in Hetu is a static const variable of [HTObject].
  /// Hence every null is the same.
  static const NULL = _HTNull();

  /// Typeid of this [HTObject]
  HTTypeId get typeid => HTTypeId.object;

  /// Wether this object contains a member with a name by [varName].
  bool contains(String varName) => throw HTError.undefined(varName);

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object.varName
  /// ```
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            toString();
      default:
        throw HTError.undefined(varName);
    }
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object.varName = value
  /// ```
  void memberSet(String varName, dynamic value,
          {String from = HTLexicon.global}) =>
      throw HTError.undefined(varName);

  /// Fetch a member by the [key], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic subGet(dynamic key) => throw HTError.undefined(key);

  /// Assign a value to a member by the [key], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void subSet(String key, dynamic value) => throw HTError.undefined(key);

  /// Wether this object is of the type by [otherTypeId]
  bool isA(HTTypeId otherTypeId) {
    if (otherTypeId == HTTypeId.ANY) {
      return true;
    } else {
      return typeid == otherTypeId;
    }
  }

  /// Wether this object is not of the type by [otherTypeId]
  bool isNotA(HTTypeId otherTypeId) => !isA(otherTypeId);
}
