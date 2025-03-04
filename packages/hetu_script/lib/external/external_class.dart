import '../error/error.dart';
// import '../class.dart' show HTInheritable;
// import '../type/type.dart';
import '../value/object.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HTExternalClass with HTObject {
  // @override
  // final HTExternalClass? superClass;

  // @override
  // HTType get valueType => HTType.CLASS;

  // @override
  final String id;

  final HTExternalClass? superClass;

  HTExternalClass(
    this.id, {
    this.superClass,
  });

  /// Default [HTExternalClass] constructor.
  /// Fetch a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object.key
  /// ```
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    if (!ignoreUndefined) throw HTError.undefined(id);
  }

  /// Assign a value to a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object.key = value
  /// ```
  void instanceMemberSet(dynamic instance, String id, dynamic value,
          {bool ignoreUndefined = false}) =>
      throw HTError.undefined(id);

  /// Fetch a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic instanceSubGet(dynamic instance, dynamic key) => instance[key];

  /// Assign a value to a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void instanceSubSet(dynamic instance, dynamic key, dynamic value) =>
      instance[key] = value;
}
