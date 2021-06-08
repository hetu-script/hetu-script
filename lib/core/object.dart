import '../error/errors.dart';
import '../grammar/lexicon.dart';
import '../type/type.dart';

class _HTNull with HTObject {
  const _HTNull();

  @override
  String toString() => HTLexicon.NULL;

  @override
  HTType get valueType => HTType.NULL;
}

/// Almost everything within Hetu is a [HTObject].
/// Includes [HTTypeid], [HTNamespace], [HTClass], [HTInstance],
/// [HTEnum], [HTExternalClass], [HTFunction].
abstract class HTObject {
  /// The [null] in Hetu is a static const variable of [HTObject].
  /// Hence every null is the same.
  static const NULL = _HTNull();

  /// The [HTType] of this [HTObject]
  HTType get valueType;

  /// Wether this object contains a member with a name by [varName].
  bool contains(String varName) {
    switch (varName) {
      case 'valueType':
        return true;
      case 'toString':
        return true;
      default:
        throw HTError.undefined(varName);
    }
  }

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object.varName
  /// ```
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'valueType':
        return valueType;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      default:
        throw HTError.undefined(varName);
    }
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object.varName = value
  /// ```
  void memberSet(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    switch (varName) {
      case 'valueType':
        throw HTError.immutable('valueType');
      case 'toString':
        throw HTError.immutable('toString');
      default:
        throw HTError.undefined(varName);
    }
  }

  /// Fetch a member by the [key], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic subGet(dynamic key) => throw HTError.undefined(key);

  /// Assign a value to a member by the [key], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void subSet(String key, dynamic varValue) => throw HTError.undefined(key);
}
