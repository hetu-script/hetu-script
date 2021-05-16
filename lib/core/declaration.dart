import '../error/errors.dart';
import '../type_system/type.dart';
import 'variable.dart';
import 'function/abstract_function.dart';

/// A [HTDeclaration] could be a [HTVariable], a [HTClass] or a [HTFunction]
/// it is basically a binding between a symbol and a value
class HTDeclaration {
  final String id;
  final String? classId;

  /// The [HTType] of this symbol, will be used to
  /// determine wether an value binding (assignment) is legal.
  /// this is not same with the property [valueType] on [HTObject]
  /// the declaration type can be resolved to a value type
  HTType? get declType => null;

  bool get isMember => classId != null;

  bool get isImmutable => true;

  bool get isInitialized => true;

  HTDeclaration(this.id, [this.classId]);

  dynamic get value => this;

  /// 调用这个接口来赋值这个变量，继承类可以
  /// override 这个接口来实现自己的赋值过程
  /// must call super
  set value(dynamic value) {
    if (isImmutable && isInitialized) {
      throw HTError.immutable(id);
    }
  }

  /// 调用这个接口来初始化这个变量，继承类需要
  /// override 这个接口来实现自己的初始化过程
  void initialize() {}

  /// A [HTDeclaration] is uncloneable by default.
  HTDeclaration clone() => throw HTError.clone(id);
}
