import '../error/error.dart';
import '../lexicon/lexicon.dart';
import '../type/type.dart';

/// The encapsulated null object, used when try to interact with a null value.
class _HTNull with HTEntity {
  const _HTNull();

  @override
  String toString() => HTLexicon.kNull;

  // @override
  // HTType get valueType => const HTTypeNull();
}

/// A interface for store and access symbols from a collection.
abstract class HTEntity {
  /// An constant null object.
  static const nullValue = _HTNull();

  HTType? get valueType => null;

  bool contains(String varName) => false;

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object.varName
  /// ```
  /// [varName] must be of String type.
  dynamic memberGet(String varName, {String? from}) {
    throw HTError.undefined(varName);
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object.varName = varValue
  /// ```
  /// [varName] must be of String type.
  void memberSet(String varName, dynamic varValue, {String? from}) {
    throw HTError.undefined(varName);
  }

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object[varName]
  /// ```
  /// [varName] is of dynamic type, and will be converted to String by [toString] method.
  dynamic subGet(dynamic varName, {String? from}) {
    throw HTError.undefined(varName);
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object[varName] = varValue
  /// ```
  /// [varName] is of dynamic type, and will be converted to String by [toString] method.
  void subSet(dynamic varName, dynamic varValue, {String? from}) {
    throw HTError.undefined(varName);
  }
}
