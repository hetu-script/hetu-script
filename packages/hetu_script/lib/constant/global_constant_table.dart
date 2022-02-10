/// All constant values of a compilation module.
class HTGlobalConstantTable {
  /// Const tables stored by its type.
  final Map<Type, List> constants = {};

  /// Add a constant value with type T to the table.
  int addGlobalConstant<T>(T value) {
    var table = constants[T];
    if (table == null) {
      constants[T] = table = <T>[];
    }
    int index;
    if (value is bool || value is int || value is double || value is String) {
      index = table.indexOf(value);
    } else {
      index = table.length;
      table.add(value);
    }
    if (index == -1) {
      table.add(value);
      return table.length - 1;
    } else {
      return index;
    }
  }

  /// Get a constant value in the table at the [index].
  dynamic getGlobalConstant(Type type, int index) {
    assert(constants.keys.contains(type));
    return constants[type]![index]!;
  }
}
