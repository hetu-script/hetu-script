import 'constant_module.dart';
import '../declaration/declaration.dart';

enum HTConstantType {
  boolean,
  integer,
  float,
  string,
}

Type getConstantType(HTConstantType type) {
  switch (type) {
    case HTConstantType.boolean:
      return bool;
    case HTConstantType.integer:
      return int;
    case HTConstantType.float:
      return double;
    case HTConstantType.string:
      return String;
  }
}

class HTConstant extends HTDeclaration {
  final String _id;

  @override
  String get id => _id;

  @override
  bool get isConst => true;

  final int index;

  final Type type;

  final HTConstantModule module;

  HTConstant({
    required String id,
    required this.type,
    required this.index,
    required this.module,
    String? classId,
    bool isStatic = false,
    bool isTopLevel = false,
  })  : _id = id,
        super(
            id: id,
            classId: classId,
            isStatic: isStatic,
            isTopLevel: isTopLevel);

  @override
  dynamic get value {
    return module.getConstant(type, index);
  }

  @override
  HTConstant clone() => this;
}
