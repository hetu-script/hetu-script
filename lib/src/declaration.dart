import 'type.dart';
import 'function.dart';

/// 变量的声明，包含了类型等额外信息
class HT_Declaration {
  final String id;

  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HT_Value
  dynamic value;
  HT_Function? getter;
  HT_Function? setter;

  final HT_TypeId declType;
  final bool isExtern;
  final bool isNullable;
  final bool isImmutable;

  HT_Declaration(this.id,
      {this.value,
      this.getter,
      this.setter,
      this.declType = HT_TypeId.ANY,
      this.isExtern = false,
      this.isNullable = false,
      this.isImmutable = false});
}
