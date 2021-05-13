/// Helper mixin to store consts,
/// used in [Compiler] and [HTBytecode]
class ConstTable {
  /// Const int table.
  final intTable = <int>[];

  /// Add a int to the const int table.
  int addInt(int value) {
    final index = intTable.indexOf(value);
    if (index == -1) {
      intTable.add(value);
      return intTable.length - 1;
    } else {
      return index;
    }
  }

  /// Get a int in the const int table at the [index].
  int getInt64(int index) => intTable[index];

  /// Const float table.
  final floatTable = <double>[];

  /// Add a float to the const float table.
  int addFloat(double value) {
    final index = floatTable.indexOf(value);
    if (index == -1) {
      floatTable.add(value);
      return floatTable.length - 1;
    } else {
      return index;
    }
  }

  /// Get a float in the const float table at the [index].
  double getFloat64(int index) => floatTable[index];

  /// Const string table.
  final stringTable = <String>[];

  /// Add a string to the const string table.
  int addString(String value) {
    final index = stringTable.indexOf(value);
    if (index == -1) {
      stringTable.add(value);
      return stringTable.length - 1;
    } else {
      return index;
    }
  }

  /// Get a string in the const string table at the [index].
  String getUtf8String(int index) => stringTable[index];
}
