class HTContext {
  void clear() {
    _constInt.clear();
    _constFloat.clear();
    _constString.clear();
  }

  /// 常量表
  final _constInt = <int>[];
  List<int> get constInt => _constInt.toList(growable: false);
  int addConstInt(int value) {
    for (var i = 0; i < _constInt.length; ++i) {
      if (_constInt[i] == value) return i;
    }

    _constInt.add(value);
    return _constInt.length - 1;
  }

  int getConstInt(int index) => _constInt[index];

  final _constFloat = <double>[];
  List<double> get constFloat => _constFloat.toList(growable: false);
  int addConstFloat(double value) {
    for (var i = 0; i < _constFloat.length; ++i) {
      if (_constFloat[i] == value) return i;
    }

    _constFloat.add(value);
    return _constFloat.length - 1;
  }

  double getConstFloat(int index) => _constFloat[index];

  final _constString = <String>[];
  List<String> get constUtf8String => _constString.toList(growable: false);
  int addConstString(String value) {
    for (var i = 0; i < _constString.length; ++i) {
      if (_constString[i] == value) return i;
    }

    _constString.add(value);
    return _constString.length - 1;
  }

  String getConstString(int index) => _constString[index];
}
