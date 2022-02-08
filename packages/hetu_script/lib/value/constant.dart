import '../constant/constant_module.dart';
import '../declaration/declaration.dart';

enum HTConstantType {
  nullValue,
  boolean,
  integer,
  float,
  string,
}

Type getConstantType(HTConstantType type) {
  switch (type) {
    case HTConstantType.nullValue:
      return Null;
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

class HTConstantDeclaration extends HTDeclaration {
  final String _id;

  @override
  String get id => _id;

  @override
  bool get isConst => true;

  final int index;

  final Type type;

  final HTConstantModule module;

  HTConstantDeclaration({
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
    return module.getGlobalConstant(type, index);
  }

  @override
  HTConstantDeclaration clone() => this;
}
