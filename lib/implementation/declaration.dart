import '../common/errors.dart';
import 'variable.dart';
import 'function.dart';
import 'type.dart';

/// A [HTDeclaration] could be a [HTVariable], a [HTClass] or a [HTFunction]
abstract class HTDeclaration {
  late final String id;
  late final String? classId;

  /// The [HTType] of this variable, will be used to
  /// determine wether an assignment is legal.
  late final HTDeclarationType? declType;

  bool get isMember => classId != null;

  bool get isImmutable => true;

  bool get isInitialized => true;

  /// 调用这个接口来初始化这个变量，继承类需要
  /// override 这个接口来实现自己的初始化过程
  void initialize() {}

  /// 调用这个接口来赋值这个变量，继承类可以
  /// override 这个接口来实现自己的赋值过程
  /// must call super
  set value(dynamic value) {
    if (isImmutable && isInitialized) {
      throw HTError.immutable(id);
    }
  }

  dynamic get value => this;

  /// A [HTDeclaration] is uncloneable by default.
  HTDeclaration clone() => throw HTError.clone(id);
}
