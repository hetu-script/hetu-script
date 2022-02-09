import 'declaration.dart';

enum HTConstantType {
  integer,
  float,
  string,
}

Type getConstantType(HTConstantType type) {
  switch (type) {
    case HTConstantType.integer:
      return int;
    case HTConstantType.float:
      return double;
    case HTConstantType.string:
      return String;
  }
}

class HTConstantDeclaration extends HTDeclaration {
  @override
  bool get isConst => true;

  final int index;

  final Type type;

  HTConstantDeclaration({
    required String id,
    required this.type,
    required this.index,
    String? classId,
    bool isTopLevel = false,
  }) : super(
            id: id,
            classId: classId,
            isStatic: classId != null ? true : false,
            isTopLevel: isTopLevel);

  @override
  dynamic get value => null;

  @override
  HTConstantDeclaration clone() => this;
}
