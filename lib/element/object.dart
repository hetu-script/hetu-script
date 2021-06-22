import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../type/type.dart';

class _HTNull with HTObject {
  const _HTNull();

  @override
  String toString() => HTLexicon.NULL;

  @override
  HTType get valueType => HTType.NULL;
}

/// Object is a runtime entity in the program that
/// represents a value that have accessable member fields
abstract class HTObject {
  /// The [null] in Hetu is a static const variable of [HTObject].
  /// Hence every null is the same object.
  static const NULL = _HTNull();

  HTType get valueType => HTType.object;

  void delete(String field) {}

  /// Fetch a member by the [field], in the form of
  /// ```
  /// object.field
  /// ```
  dynamic memberGet(String field,
      {String from = SemanticNames.global, bool error = true}) {
    switch (field) {
      case 'valueType':
        return valueType;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            toString();
      default:
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }

  /// Assign a value to a member by the [field], in the form of
  /// ```
  /// object.field = value
  /// ```
  void memberSet(String field, dynamic varValue,
      {String from = SemanticNames.global, bool error = true}) {
    switch (field) {
      case 'valueType':
        throw HTError.immutable('valueType');
      case 'toString':
        throw HTError.immutable('toString');
      default:
        // will throw even if error arg is false
        throw HTError.undefined(field);
    }
  }

  /// Fetch a member by the [key], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic subGet(dynamic key) => null;

  /// Assign a value to a member by the [key], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void subSet(String key, dynamic varValue) => throw HTError.undefined(key);
}
