import 'dart:typed_data';
import 'dart:convert';

import 'shared.dart';

/// An utility class to read bytes and return the actual value.
mixin BytecodeReader {
  /// The bytecode, stores as uint8 list
  late Uint8List bytes;

  /// Instruction pointer
  var ip = 0;

  /// Skip forward [distance] of bytes
  void skip(int distance) {
    ip += distance;
  }

  int get curByte => bytes[ip];

  /// Fetch a single byte at the current instruction pointer
  int read() {
    if (ip >= 0 && ip < bytes.length) {
      return bytes[ip++];
    } else {
      ip = 0;
      return OpCode.endOfCode;
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

  /// Fetch a int32 from the bytes list
  // int readInt32() {
  //   final start = ip;
  //   ip += 4;
  //   return bytes.buffer.asByteData().getInt32(start);
  // }

  /// Fetch a int64 from the bytes list
  // int readInt64() {
  //   final start = ip;
  //   ip += 8;
  //   return bytes.buffer.asByteData().getInt64(start);
  // }

  /// Fetch a float64 from the bytes list
  // double readFloat64() {
  //   final start = ip;
  //   ip += 8;
  //   return bytes.buffer.asByteData().getFloat64(start);
  // }

  /// Fetch a int64 from the bytes list
  // int readInt64() {
  //   final signMask = 1 << 31;
  //   final highBits = bytes.buffer.asByteData().getUint32(ip, Endian.big);
  //   final isNegative = (highBits & signMask) >> 31 == 1 ? -1 : 1;
  //   final littleEnd = bytes.buffer.asByteData().getUint32(ip + 4, Endian.big);
  //   ip += 8;
  //   var bigEnd = highBits;
  //   if (isNegative < 0) {
  //     bigEnd = highBits - signMask;
  //     return ((bigEnd << 32) + littleEnd) * -1 - 1;
  //   } else {
  //     return (bigEnd << 32) + littleEnd;
  //   }
  // }

  /// Fetch a int64 from the bytes list
  int readInt64() {
    final data = readUtf8String();
    final number = int.parse(data);
    return number;
  }

  /// Fetch a float64 from the bytes list
  double readFloat64() {
    final data = readUtf8String();
    final number = double.parse(data);
    return number;
  }

  /// Fetch a utf8 string from the bytes list
  String readUtf8String() {
    final length = readUint32();
    final start = ip;
    ip += length;
    final codeUnits = bytes.sublist(start, ip);
    return utf8.decoder.convert(codeUnits);
  }
}
