import 'type.dart';

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

  late final HTTypeId? declType;

  final Function? getter;
  final Function? setter;

  final bool isExtern;
  final bool isImmutable;
  final bool isMember;
  final bool isStatic;

  var _isInitialized = false;

  /// 继承类会 override 这个接口来改变初始化过程
  bool get isInitialized => _isInitialized;

  /// 基础声明不包含初始化、类型推断和类型检查，
  /// 这些工作都是在继承类中各自实现的
  HTDeclaration(this.id,
      {this.value,
      HTTypeId? declType,
      this.getter,
      this.setter,
      this.isExtern = false,
      this.isImmutable = false,
      this.isMember = false,
      this.isStatic = false,
      bool isInitialized = true}) {
    if (declType != null) {
      this.declType = declType;
    }

    _isInitialized = isInitialized;
  }

  HTDeclaration clone() => HTDeclaration(id,
      value: value,
      declType: declType,
      getter: getter,
      setter: setter,
      isExtern: isExtern,
      isImmutable: isImmutable,
      isMember: isMember,
      isInitialized: isInitialized);

  /// 调用这个接口来初始化这个变量，继承类需要
  /// override 这个接口来实现自己的初始化过程
  void initialize() => _isInitialized = true;
}
