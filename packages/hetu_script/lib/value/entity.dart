import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../type/type.dart';
import '../type/unresolved_nominal_type.dart';

class _HTNull with HTEntity {
  const _HTNull();

  @override
  String toString() => HTLexicon.kNull;

  @override
  HTType get valueType => HTType.nullType;
}

/// A interface for store and access symbols from a collection.
abstract class HTEntity {
  static const type = HTUnresolvedNominalType(HTLexicon.object);

  /// The encapsulated null object, used when try to interact with a null value.
  static const nullValue = _HTNull();

  HTType get valueType => type;

  bool contains(String varName) => false;

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object.varName
  /// ```
  dynamic memberGet(String varName, {String? from}) {
    throw HTError.undefined(varName);
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object.varName = varValue
  /// ```
  void memberSet(String varName, dynamic varValue, {String? from}) {
    throw HTError.undefined(varName);
  }

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object[varName]
  /// ```
  dynamic subGet(dynamic varName, {String? from}) {
    throw HTError.undefined(varName);
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object[varName] = varValue
  /// ```
  void subSet(dynamic varName, dynamic varValue, {String? from}) {
    throw HTError.undefined(varName);
  }
}
