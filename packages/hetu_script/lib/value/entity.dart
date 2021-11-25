import '../error/error.dart';
import '../grammar/lexicon.dart';
import '../type/type.dart';
import '../type/unresolved_type.dart';

class _HTNull with HTEntity {
  const _HTNull();

  @override
  String toString() => HTLexicon.NULL;

  @override
  HTType get valueType => HTType.NULL;
}

/// A collection of various symbols & value pairs.
abstract class HTEntity {
  static const type = HTUnresolvedType(HTLexicon.object);

  /// The [null] in Hetu is a static const variable of [HTEntity].
  /// Hence every null is the same object.
  static const NULL = _HTNull();

  HTType get valueType => type;

  bool contains(String varName) => false;

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object.varName
  /// ```
  dynamic memberGet(String varName) {
    throw HTError.undefined(varName);
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object.varName = varValue
  /// ```
  void memberSet(String varName, dynamic varValue) {
    throw HTError.undefined(varName);
  }

  /// Fetch a member by the [varName], in the form of
  /// ```
  /// object[varName]
  /// ```
  dynamic subGet(dynamic varName) {
    throw HTError.undefined(varName);
  }

  /// Assign a value to a member by the [varName], in the form of
  /// ```
  /// object[varName] = varValue
  /// ```
  void subSet(dynamic varName, dynamic varValue) {
    throw HTError.undefined(varName);
  }
}
