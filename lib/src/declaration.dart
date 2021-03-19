import 'type.dart';
import 'function.dart';

/// 变量的声明，包含了类型等额外信息
class HTDeclaration {
  final String id;
  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HTObject
  dynamic value;

  final HTFunction? getter;
  final HTFunction? setter;

  final HTTypeId declType;
  final bool isExtern;
  final bool isNullable;
  final bool isImmutable;

  HTDeclaration(this.id,
      {this.value,
      this.getter,
      this.setter,
      this.declType = HTTypeId.ANY,
      this.isExtern = false,
      this.isNullable = false,
      this.isImmutable = false});
}
