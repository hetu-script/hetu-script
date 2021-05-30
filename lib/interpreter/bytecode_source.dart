import 'dart:typed_data';

import '../source/source.dart';
import 'bytecode_reader.dart';

/// Code module class, represent a trunk of bytecode.
/// Every bytecode file has its own const tables
class HTBytecodeModule extends HTModule with BytecodeReader {
  /// Create a bytecode module from an uint8 list
  HTBytecodeModule(String fullName, String content, Uint8List bytes)
      : super(fullName, content) {
    this.bytes = bytes;
  }
}

/// The information of snippet need goto
mixin GotoInfo {
  /// The module this variable declared in.
  late final String moduleFullName;

  /// The instructor pointer of the definition's bytecode.
  int? definitionIp;

  /// The line of the definition's bytecode.
  int? definitionLine;

  /// The column of the definition's bytecode.
  int? definitionColumn;
}

class BytecodeSymbolLink {
  String moduleFullName;
  int ip;

  BytecodeSymbolLink(this.moduleFullName, this.ip);
}

class HTBytecodeCompilation extends HTCompilation {
  final _symbols = <String, BytecodeSymbolLink>{};

  @override
  Iterable<String> get symbols => _symbols.keys;

  @override
  bool containsSymbol(String id) => _symbols.containsKey(id);

  BytecodeSymbolLink? getSymbol(String id) {
    if (!_symbols.containsKey(id)) {
      throw 'Unknown symbol [$id]';
    }
    return _symbols[id]!;
  }

  void addSymbol(String id, String moduleFullName, int ip) {
    if (_symbols.containsKey(id)) {
      throw 'Already exist symbol [$id]';
    }
    _symbols[id] = BytecodeSymbolLink(moduleFullName, ip);
  }

  final _modules = <String, HTBytecodeModule>{};

  @override
  Iterable<String> get moduleKeys => _modules.keys;

  @override
  Iterable<HTBytecodeModule> get modules => _modules.values;

  @override
  bool containsModule(String key) => _modules.containsKey(key);

  @override
  HTBytecodeModule getModule(String key) {
    if (_modules.containsKey(key)) {
      return _modules[key]!;
    } else {
      throw 'Unknown module key [$key]';
    }
  }

  void addModule(HTBytecodeModule module) {
    if (_symbols.containsKey(module.fullName)) {
      throw 'Already exist module key [${module.fullName}]';
    }
    _modules[module.fullName] = module;
  }

  void join(HTBytecodeCompilation other) {
    _modules.addAll(other._modules);
  }
}
