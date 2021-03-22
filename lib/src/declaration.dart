import 'type.dart';
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

  late final HTTypeId? declType;

  final Function? getter;
  final Function? setter;

  final bool isExtern;
  bool get isImmutable => true;
  final bool isMember;
  final bool isStatic;

  /// 继承类会 override 这个接口来改变初始化过程
  bool get isInitialized => true;

  /// 基础声明不包含可变性、初始化、类型推断、类型检查（含空安全）
  /// 这些工作都是在继承类中各自实现的
  HTDeclaration(this.id,
      {this.value,
      HTTypeId? declType,
      this.getter,
      this.setter,
      this.isExtern = false,
      this.isMember = false,
      this.isStatic = false}) {
    if (declType != null) {
      this.declType = declType;
    } else {
      this.declType = HTTypeId.ANY;
    }
  }

  /// 调用这个接口来初始化这个变量，继承类需要
  /// override 这个接口来实现自己的初始化过程
  void initialize() {}

  /// 调用这个接口来赋值这个变量，继承类需要
  /// override 这个接口来实现自己的赋值过程
  void assign(dynamic value) => throw HTErrorImmutable(id);

  HTDeclaration clone() => HTDeclaration(id,
      value: value, declType: declType, getter: getter, setter: setter, isExtern: isExtern, isMember: isMember);
}
