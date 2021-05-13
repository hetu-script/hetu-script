import 'dart:typed_data';
import 'dart:convert';

import '../source/source.dart';
import '../core/const_table.dart';
import 'opcode.dart';

/// Code module class, represent a trunk of bytecode.
/// Every bytecode file has its own const tables
class HTBytecodeModule extends HTModule with ConstTable {
  /// The bytecode, stores as uint8 list
  final Uint8List bytes;

  /// final symbols = <String, int>{};

  /// Instruction pointer
  var ip = 0;

  /// Create a bytecode module from an uint8 list
  HTBytecodeModule(String fullName, String content, this.bytes)
      : super(fullName, content);

  /// Skip forward [distance] of bytes
  void skip(int distance) {
    ip += distance;
  }

  /// Fetch a single byte at the current instruction pointer
  int read() {
    if (ip >= 0 && ip < bytes.length) {
      return bytes[ip++];
    } else {
      ip = 0;
      return HTOpCode.endOfFile;
    }
  }

  /// Fetch a bool value from the bytes list
  bool readBool() {
    return bytes[ip++] == 0 ? false : true;
  }

  /// Fetch a uint8 from the bytes list
  int readUint8() {
    final start = ip;
    ip += 1;
    return bytes.buffer.asByteData().getUint8(start);
  }

  /// Fetch a uint16 from the bytes list
  int readUint16() {
    final start = ip;
    ip += 2;
    return bytes.buffer.asByteData().getUint16(start);
  }

  /// Fetch a uint32 from the bytes list
  int readUint32() {
    final start = ip;
    ip += 4;
    return bytes.buffer.asByteData().getUint32(start);
  }

  /// Fetch a int64 from the bytes list
  int readInt16() {
    final start = ip;
    ip += 2;
    return bytes.buffer.asByteData().getInt16(start);
  }

  /// Fetch a int64 from the bytes list
  int readInt64() {
    final start = ip;
    ip += 8;
    return bytes.buffer.asByteData().getUint64(start);
  }

  /// Fetch a float64 from the bytes list
  double readFloat64() {
    final start = ip;
    ip += 8;
    return bytes.buffer.asByteData().getFloat64(start);
  }

  /// Fetch a utf8 string from the bytes list
  String readShortUtf8String() {
    final length = readUint8();
    final start = ip;
    ip += length;
    final codeUnits = bytes.sublist(start, ip);
    return utf8.decoder.convert(codeUnits);
  }

  /// Fetch a utf8 string from the bytes list
  String readUtf8String() {
    final length = readUint16();
    final start = ip;
    ip += length;
    final codeUnits = bytes.sublist(start, ip);
    return utf8.decoder.convert(codeUnits);
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

class HTBytecodeCompilation extends HTCompilation {
  final _modules = <String, HTBytecodeModule>{};

  @override
  Iterable<String> get keys => _modules.keys;

  @override
  Iterable<HTBytecodeModule> get sources => _modules.values;

  @override
  bool contains(String fullName) => _modules.containsKey(fullName);

  @override
  HTBytecodeModule fetch(String fullName) {
    if (_modules.containsKey(fullName)) {
      return _modules[fullName]!;
    } else {
      throw 'Unknown source: $fullName';
    }
  }

  void add(HTBytecodeModule source) => _modules[source.fullName] = source;

  void addAll(HTBytecodeCompilation other) {
    _modules.addAll(other._modules);
  }
}
