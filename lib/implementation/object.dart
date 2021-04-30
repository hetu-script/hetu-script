import '../common/errors.dart';
import 'type.dart';
import 'lexicon.dart';

class _HTNull with HTObject {
  const _HTNull();

  @override
  String toString() => HTLexicon.NULL;

  @override
  HTType get objectType => HTType.NULL;
}

/// Almost everything within Hetu is a [HTObject].
/// Includes [HTTypeid], [HTNamespace], [HTClass], [HTInstance],
/// [HTEnum], [HTExternalClass], [HTFunction].
mixin HTObject {
  /// The [null] in Hetu is a static const variable of [HTObject].
  /// Hence every null is the same.
  static const NULL = _HTNull();

  /// The [HTType] of this [HTObject],
  /// this is the runtime value type,
  /// not necessarily the declaration type
  HTType get objectType => HTType.object;

  /// Wether this object contains a member with a name by [varName].
  bool contains(String varName) => throw HTError.undefined(varName);

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object.varName
  /// ```
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'objectType':
        return objectType;
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
  void subSet(String key, dynamic varValue) => throw HTError.undefined(key);
}
