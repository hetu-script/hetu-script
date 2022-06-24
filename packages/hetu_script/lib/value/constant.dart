import '../constant/global_constant_table.dart';
import '../declaration/declaration.dart';

class HTConstantValue extends HTDeclaration {
  @override
  bool get isConst => true;

  final int index;

  final Type type;

  final HTGlobalConstantTable module;

  HTConstantValue({
    required String id,
    required this.type,
    required this.index,
    super.classId,
    super.isTopLevel = false,
    required this.module,
  }) : super(id: id);

  @override
  void resolve() {}

  @override
  dynamic get value {
    return module.getGlobalConstant(type, index);
  }

  @override
  HTConstantValue clone() => this;
}
