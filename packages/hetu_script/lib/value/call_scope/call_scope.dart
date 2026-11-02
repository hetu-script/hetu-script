import '../../error/error.dart';
import 'variable_cell.dart';

class HTCallScopeUpvalue {
  final int depth;
  final int slot;
  final String name;

  const HTCallScopeUpvalue(this.depth, this.slot, this.name);
}

class HTCallScope {
  final HTCallScope? closure;
  final List<dynamic> slots;
  final List<String> slotNames;
  List<int> capturedSlots;
  final List<HTVariableCell> upvalues;
  bool _hasCapturedSlots;
  final List<bool> _mutable;
  final List<bool> _initialized;

  HTCallScope(
    int slotCount,
    this.slotNames, {
    this.closure,
    List<int> capturedSlots = const [],
    this.upvalues = const [],
  })  : slots = List<dynamic>.filled(slotCount, null),
        capturedSlots = capturedSlots,
        _hasCapturedSlots = capturedSlots.isNotEmpty,
        _mutable = List<bool>.filled(slotCount, true),
        _initialized = List<bool>.filled(slotCount, false);

  String _name(int slot) =>
      slot < slotNames.length ? slotNames[slot] : slot.toString();

  dynamic getUncaptured(int slot) {
    if (!_initialized[slot]) {
      throw HTError.uninitialized(_name(slot));
    }
    return slots[slot];
  }

  dynamic get(int slot) {
    final value = slots[slot];
    if (value is HTVariableCell) {
      return value.value;
    }
    return getUncaptured(slot);
  }

  void declare(
    int slot,
    dynamic value, {
    required bool isMutable,
    required bool isInitialized,
    bool reuseCell = false,
  }) {
    _mutable[slot] = isMutable;
    _initialized[slot] = isInitialized;
    if (_hasCapturedSlots && capturedSlots.contains(slot)) {
      final current = slots[slot];
      if (reuseCell && current is HTVariableCell) {
        current.declare(
          value,
          mutable: isMutable,
          initialized: isInitialized,
        );
      } else {
        slots[slot] = HTVariableCell(
          _name(slot),
          value,
          isMutable: isMutable,
          isInitialized: isInitialized,
        );
      }
    } else {
      slots[slot] = value;
    }
  }

  void setUncaptured(int slot, dynamic value) {
    if (!_mutable[slot]) {
      throw HTError.immutable(_name(slot));
    }
    slots[slot] = value;
    _initialized[slot] = true;
  }

  void set(int slot, dynamic value) {
    final current = slots[slot];
    if (current is HTVariableCell) {
      current.value = value;
      return;
    }
    setUncaptured(slot, value);
  }

  HTVariableCell capture(int slot) {
    final current = slots[slot];
    if (current is HTVariableCell) {
      return current;
    }
    final cell = HTVariableCell(
      _name(slot),
      current,
      isMutable: _mutable[slot],
      isInitialized: _initialized[slot],
    );
    slots[slot] = cell;
    if (!capturedSlots.contains(slot)) {
      capturedSlots = List<int>.of(capturedSlots)..add(slot);
    }
    _hasCapturedSlots = true;
    return cell;
  }

  dynamic getUpvalue(int index) => upvalues[index].value;

  void setUpvalue(int index, dynamic value) {
    upvalues[index].value = value;
  }
}
