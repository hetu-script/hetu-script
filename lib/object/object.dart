import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../type/type.dart';
import '../type/unresolved_type.dart';

class _HTNull with HTObject {
  const _HTNull();

  @override
  String toString() => HTLexicon.NULL;

  @override
  HTType get valueType => HTType.NULL;
}

/// Object is a runtime entity in the program that
/// represents a value that have accessible members
abstract class HTObject {
  static const type = HTUnresolvedType(HTLexicon.object);

  /// The [null] in Hetu is a static const variable of [HTObject].
  /// Hence every null is the same object.
  static const NULL = _HTNull();

  HTType get valueType => type;

  bool contains(String field) => false;

  void delete(String field) {}

  /// Fetch a member by the [field], in the form of
  /// ```
  /// object.field
  /// ```
  dynamic memberGet(String field, {bool error = true}) {
    if (error) {
      throw HTError.undefined(field);
    }
  }

  /// Assign a value to a member by the [field], in the form of
  /// ```
  /// object.field = value
  /// ```
  void memberSet(String field, dynamic varValue, {bool error = true}) {
    if (error) {
      throw HTError.undefined(field);
    }
  }

  /// Fetch a member by the [key], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic subGet(dynamic key) {}

  /// Assign a value to a member by the [key], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void subSet(String key, dynamic varValue) {}
}
