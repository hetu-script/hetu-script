/// All constant values of a compilation module.
class HTConstantModule {
  /// Const tables stored by its type.
  final values = <Type, List>{};

  /// Add a constant value with type T to the table.
  int addConstant<T>(T value) {
    var table = values[T];
    if (table == null) {
      values[T] = table = <T>[];
    }
    final index = table.indexOf(value);
    if (index == -1) {
      table.add(value);
      return table.length - 1;
    } else {
      return index;
    }
  }

  /// Get a constant value in the table at the [index].
  dynamic getConstant(Type type, int index) {
    assert(values.keys.contains(type));
    return values[type]![index]!;
  }
}
