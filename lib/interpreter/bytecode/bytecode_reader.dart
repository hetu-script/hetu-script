import 'dart:typed_data';
import 'dart:convert';

import '../opcode.dart';

class BytecodeReader {
  /// The bytecode, stores as uint8 list
  Uint8List bytes;

  BytecodeReader(this.bytes);

  void changeCode(Uint8List newBytes) => bytes = newBytes;

  /// Instruction pointer
  var ip = 0;

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
