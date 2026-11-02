import '../../error/error.dart';

class HTCallScope {
  final HTCallScope? closure;
  final List<dynamic> slots;
  final List<String> slotNames;
  final List<bool> _mutable;
  final List<bool> _initialized;

  HTCallScope(int slotCount, this.slotNames, {this.closure})
      : slots = List<dynamic>.filled(slotCount, null),
        _mutable = List<bool>.filled(slotCount, true),
        _initialized = List<bool>.filled(slotCount, false);

  String _name(int slot) =>
      slot < slotNames.length ? slotNames[slot] : slot.toString();

  dynamic get(int slot) {
    if (!_initialized[slot]) {
      throw HTError.uninitialized(_name(slot));
    }
    return slots[slot];
  }

  void declare(
    int slot,
    dynamic value, {
    required bool isMutable,
    required bool isInitialized,
  }) {
    slots[slot] = value;
    _mutable[slot] = isMutable;
    _initialized[slot] = isInitialized;
  }

  void set(int slot, dynamic value) {
    if (!_mutable[slot]) {
      throw HTError.immutable(_name(slot));
    }
    slots[slot] = value;
    _initialized[slot] = true;
  }
}
