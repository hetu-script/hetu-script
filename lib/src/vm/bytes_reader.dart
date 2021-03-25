import 'dart:typed_data';
import 'dart:convert';

import 'opcode.dart';

class BytesReader {
  late final Uint8List bytes;
  var ip = 0; // instruction pointer

  BytesReader(this.bytes);

  void skip(int distance) {
    ip += distance;
  }

  int read([int distance = 1]) {
    if (ip >= 0 && ip < bytes.length) {
      return bytes[ip++];
    } else {
      ip = 0;
      return HTOpCode.endOfFile;
    }
  }

  bool readBool() {
    return bytes[ip++] == 0 ? false : true;
  }

  // Fetch a uint8 from the byte list
  int readUint8() {
    final start = ip;
    ip += 1;
    return bytes.buffer.asByteData().getUint8(start);
  }

  // Fetch a uint16 from the byte list
  int readUint16() {
    final start = ip;
    ip += 2;
    return bytes.buffer.asByteData().getUint16(start);
  }

  // Fetch a uint32 from the byte list
  int readUint32() {
    final start = ip;
    ip += 4;
    return bytes.buffer.asByteData().getUint32(start);
  }

  // Fetch a int64 from the byte list
  int readInt64() {
    final start = ip;
    ip += 8;
    return bytes.buffer.asByteData().getUint64(start);
  }

  // Fetch a float64 from the byte list
  double readFloat64() {
    final start = ip;
    ip += 8;
    return bytes.buffer.asByteData().getFloat64(start);
  }

  // Fetch a utf8 string from the byte list
  String readShortUtf8String() {
    final length = readUint8();
    final start = ip;
    ip += length;
    final codeUnits = bytes.sublist(start, ip);
    return utf8.decoder.convert(codeUnits);
  }

  // Fetch a utf8 string from the byte list
  String readUtf8String() {
    final length = readUint16();
    final start = ip;
    ip += length;
    final codeUnits = bytes.sublist(start, ip);
    return utf8.decoder.convert(codeUnits);
  }
}
