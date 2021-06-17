import '../error/error.dart';
// import '../class.dart' show HTInheritable;
import '../declaration/type/type.dart';
import '../declaration/object.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HTExternalClass with HTObject {
  // @override
  // final HTExternalClass? superClass;

  @override
  HTType get valueType => HTType.CLASS;

  // @override
  final String id;

  HTExternalClass(this.id); //, {this.superClass, this.superClassType});

  /// Default [HTExternalClass] constructor.
  /// Fetch a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object.key
  /// ```
  dynamic instanceMemberGet(dynamic object, String varName) =>
      throw HTError.undefined(varName);

  /// Assign a value to a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object.key = value
  /// ```
  void instanceMemberSet(dynamic object, String varName, dynamic varValue) =>
      throw HTError.undefined(varName);

  /// Fetch a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic instanceSubGet(dynamic object, dynamic key) => object[key];

  /// Assign a value to a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void instanceSubSet(dynamic object, dynamic key, dynamic varValue) =>
      object[key] = varValue;
}
