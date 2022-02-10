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
    String? classId,
    bool isTopLevel = false,
    required this.module,
  }) : super(
          id: id,
          classId: classId,
          isTopLevel: isTopLevel,
        );

  @override
  void resolve() {}

  @override
  dynamic get value {
    return module.getGlobalConstant(type, index);
  }

  @override
  HTConstantValue clone() => this;
}
