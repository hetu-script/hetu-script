import '../errors.dart';
import '../class.dart' show HTInheritable;
import '../type.dart';
import '../object.dart';

/// Namespace class of low level external dart functions for Hetu to use.
abstract class HTExternalClass with HTObject {
  late final String id;

  HTExternalClass(String id) {
    this.id = id;
  }

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

class HTInheritableExternalClass extends HTExternalClass with HTInheritable {
  static final instanceTypes = <int, HTInstanceType>{};

  @override
  final HTInheritableExternalClass? superClass;

  @override
  final HTType? superClassType;

  HTInheritableExternalClass(String id, {this.superClass, this.superClassType})
      : super(id);
}
