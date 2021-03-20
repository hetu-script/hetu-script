import 'dart:typed_data';
import 'dart:convert';

import 'opcode.dart';

class BytesReader {
  late final Uint8List bytes;
  var ip = 0; // instruction pointer

  BytesReader(this.bytes);

  int read([int distance = 1]) {
    final des = ip + distance;
    if (des >= 0 && des < bytes.length) {
      return bytes[des];
    } else {
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
    final uint16data = bytes.sublist(start, ip);
    return uint16data.buffer.asByteData().getUint8(0);
  }

  // Fetch a uint16 from the byte list
  int readUint16() {
    final start = ip;
    ip += 2;
    final uint16data = bytes.sublist(start, ip);
    return uint16data.buffer.asByteData().getUint16(0);
  }

  // Fetch a uint32 from the byte list
  int readUint32() {
    final start = ip;
    ip += 4;
    final uint32data = bytes.sublist(start, ip);
    return uint32data.buffer.asByteData().getUint32(0);
  }

  // Fetch a int64 from the byte list
  int readInt64() {
    final start = ip;
    ip += 8;
    final int64data = bytes.sublist(start, ip);
    return int64data.buffer.asByteData().getInt64(0);
  }

  // Fetch a float64 from the byte list
  double readFloat64() {
    final start = ip;
    ip += 8;
    final int64data = bytes.sublist(start, ip);
    return int64data.buffer.asByteData().getFloat64(0);
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
