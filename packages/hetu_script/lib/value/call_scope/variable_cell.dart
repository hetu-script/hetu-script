import '../../error/error.dart';

class HTVariableCell {
  final String name;
  dynamic _value;
  bool isMutable;
  bool isInitialized;

  HTVariableCell(
    this.name,
    dynamic value, {
    required this.isMutable,
    required this.isInitialized,
  }) : _value = value;

  dynamic get value {
    if (!isInitialized) {
      throw HTError.uninitialized(name);
    }
    return _value;
  }

  set value(dynamic newValue) {
    if (!isMutable) {
      throw HTError.immutable(name);
    }
    _value = newValue;
    isInitialized = true;
  }

  void declare(
    dynamic value, {
    required bool mutable,
    required bool initialized,
  }) {
    _value = value;
    isMutable = mutable;
    isInitialized = initialized;
  }
}
