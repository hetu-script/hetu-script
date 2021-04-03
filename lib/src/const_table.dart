/// Helper mixin to store consts,
/// used in [Compiler] and [HTBytecode]
mixin ConstTable {
  /// 常量表
  late final _intTable = <int>[];
  List<int> get intTable => _intTable.toList(growable: false);
  int addInt(int value) {
    final index = _intTable.indexOf(value);
    if (index == -1) {
      _intTable.add(value);
      return _intTable.length - 1;
    } else {
      return index;
    }
  }

  int getInt64(int index) => intTable[index];

  late final _floatTable = <double>[];
  List<double> get floatTable => _floatTable.toList(growable: false);
  int addConstFloat(double value) {
    final index = _floatTable.indexOf(value);
    if (index == -1) {
      _floatTable.add(value);
      return _floatTable.length - 1;
    } else {
      return index;
    }
  }

  double getFloat64(int index) => floatTable[index];

  late final _stringTable = <String>[];
  List<String> get stringTable => _stringTable.toList(growable: false);
  int addConstString(String value) {
    final index = _stringTable.indexOf(value);
    if (index == -1) {
      _stringTable.add(value);
      return _stringTable.length - 1;
    } else {
      return index;
    }
  }

  String getUtf8String(int index) => stringTable[index];
}
