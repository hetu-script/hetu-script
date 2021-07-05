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
<<<<<<< HEAD
/// represents a value that have accessible members
=======
/// represents a value that have accessable member varNames
>>>>>>> refactor function type
abstract class HTObject {
  static const type = HTUnresolvedType(HTLexicon.object);

  /// The [null] in Hetu is a static const variable of [HTObject].
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
  /// object.varName = value
  /// ```
  void memberSet(String varName, dynamic varValue) {
    throw HTError.undefined(varName);
  }
}
