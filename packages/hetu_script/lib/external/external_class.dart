import '../error/error.dart';
// import '../class.dart' show HTInheritable;
// import '../type/type.dart';
import '../value/entity.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HTExternalClass with HTEntity {
  // @override
  // final HTExternalClass? superClass;

  // @override
  // HTType get valueType => HTType.CLASS;

  // @override
  final String id;

  HTExternalClass(this.id); //, {this.superClass, this.superClassType});

  /// Default [HTExternalClass] constructor.
  /// Fetch a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object.key
  /// ```
  dynamic instanceMemberGet(dynamic object, String id) =>
      throw HTError.undefined(id);

  /// Assign a value to a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object.key = value
  /// ```
  void instanceMemberSet(dynamic object, String id, dynamic value) =>
      throw HTError.undefined(id);

  /// Fetch a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic instanceSubGet(dynamic object, dynamic key) => object[key];

  /// Assign a value to a instance member of the Dart class by the [id], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void instanceSubSet(dynamic object, dynamic key, dynamic value) =>
      object[key] = value;
}
