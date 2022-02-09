import '../constant/global_constant_table.dart';
import '../declaration/constant.dart';

class HTConstantValue extends HTConstantDeclaration {
  final HTGlobalConstantTable module;

  HTConstantValue({
    required String id,
    required Type type,
    required int index,
    String? classId,
    bool isTopLevel = false,
    required this.module,
  }) : super(
          id: id,
          type: type,
          index: index,
          classId: classId,
          isTopLevel: isTopLevel,
        );

  @override
  dynamic get value {
    return module.getGlobalConstant(type, index);
  }

  @override
  HTConstantValue clone() => this;
}
