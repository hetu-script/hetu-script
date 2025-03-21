// import 'package:hetu_script/declaration/declaration.dart';
// import 'package:hetu_script/value/function/function.dart';

import '../error/error.dart';
// import '../lexicon/lexicon.dart';
import '../type/type.dart';

/// The encapsulated null object, used when try to interact with a null value.
class _HTNull with HTObject {
  const _HTNull();
}

/// A mixin for store and access symbols from a collection.
mixin HTObject {
  /// An constant null object.
  static const nullValue = _HTNull();

  HTType? get valueType => null;

  bool contains(String id) => false;

  void define(String id, dynamic value, {bool override = false}) {
    throw HTError.undefined(id);
  }

  /// Fetch a member by the [id], in the form of
  /// ```
  /// object.id
  /// ```
  /// [id] must be of String type.
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    throw HTError.undefined(id);
  }

  /// Assign a value to a member by the [id], in the form of
  /// ```
  /// object.id = value
  /// ```
  /// [id] must be of String type.
  void memberSet(String id, dynamic value,
      {String? from, bool defineIfAbsent = false}) {
    throw HTError.undefined(id);
  }

  /// Fetch a member by the [id], in the form of
  /// ```
  /// object[id]
  /// ```
  /// [id] is of dynamic type, and will be converted to String by [toString] method.
  dynamic subGet(dynamic id, {String? from}) {
    return memberGet(id.toString(), from: from, ignoreUndefined: true);
  }

  /// Assign a value to a member by the [id], in the form of
  /// ```
  /// object[id] = value
  /// ```
  /// [id] is of dynamic type, and will be converted to String by [toString] method.
  void subSet(dynamic id, dynamic value, {String? from}) {
    memberSet(id.toString(), value, from: from);
  }
}
