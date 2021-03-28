class ConstTable {
  /// 常量表
  late final intTable = <int>[];
  List<int> get constInt => intTable.toList(growable: false);
  int addConstInt(int value) {
    final index = intTable.indexOf(value);
    if (index == -1) {
      intTable.add(value);
      return intTable.length - 1;
    } else {
      return index;
    }
  }

  int getInt64(int index) => intTable[index];

  late final floatTable = <double>[];
  List<double> get constFloat => floatTable.toList(growable: false);
  int addConstFloat(double value) {
    final index = floatTable.indexOf(value);
    if (index == -1) {
      floatTable.add(value);
      return floatTable.length - 1;
    } else {
      return index;
    }
  }

  double getFloat64(int index) => floatTable[index];

  late final stringTable = <String>[];
  List<String> get constUtf8String => stringTable.toList(growable: false);
  int addConstString(String value) {
    final index = stringTable.indexOf(value);
    if (index == -1) {
      stringTable.add(value);
      return stringTable.length - 1;
    } else {
      return index;
    }
  }

  String getUtf8String(int index) => stringTable[index];
}
