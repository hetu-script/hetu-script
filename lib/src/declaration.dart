import 'package:hetu_script/src/namespace.dart';

import 'errors.dart';

/// 一个声明，包含了类型等额外信息。
/// 在命名空间中，所有的对象都被其各自的声明所包裹在内。
///
/// 在编译后的代码中，被提前到整个代码块最前面。
///
/// 这个类的继承者包括类声明、函数声明、参数声明等等，
/// 他们需要各自实现初始化、类型推断和类型检查。
class HTDeclaration {
  final String id;
  // 为了允许保存宿主程序变量，这里是dynamic，而不是HTObject
  dynamic value;

  final Function? getter;
  final Function? setter;

  final bool isExtern;
  bool get isImmutable => true;
  final bool isMember;
  final bool isStatic;

  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  final HTNamespace? closure;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  HTDeclaration(this.id,
      {dynamic value,
      this.getter,
      this.setter,
      this.isExtern = false,
      this.isMember = false,
      this.isStatic = false,
      this.closure}) {
    if (value != null) assign(value);
  }

  /// 调用这个接口来初始化这个变量，继承类需要
  /// override 这个接口来实现自己的初始化过程
  void initialize() {}

  /// 调用这个接口来赋值这个变量，继承类可以
  /// override 这个接口来实现自己的赋值过程
  void assign(dynamic value) {
    if (isImmutable && _isInitialized) {
      throw HTErrorImmutable(id);
    }

    this.value = value;
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  HTDeclaration clone() =>
      HTDeclaration(id, value: value, getter: getter, setter: setter, isExtern: isExtern, isMember: isMember);
}
