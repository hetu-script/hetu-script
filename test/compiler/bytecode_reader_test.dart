import 'dart:convert';
import 'dart:typed_data';

import 'package:hetu_script/bytecode/bytecode_reader.dart';
import 'package:test/test.dart';

class _Reader with BytecodeReader {}

void main() {
  test('bytecode reader respects byte offsets, endianness and UTF-8', () {
    final numbers = ByteData(9)
      ..setUint8(0, 0xfe)
      ..setUint16(1, 0xfedc, Endian.big)
      ..setUint32(3, 0xfedcba98, Endian.big)
      ..setInt16(7, -12345, Endian.big);
    final text = utf8.encode('你好, Hetu 🌍');
    final textLength = ByteData(4)..setUint32(0, text.length, Endian.big);
    final padded = Uint8List.fromList([
      1,
      2,
      3,
      ...numbers.buffer.asUint8List(),
      ...textLength.buffer.asUint8List(),
      ...text,
      4,
      5,
    ]);
    final reader = _Reader()
      ..bytes = Uint8List.sublistView(padded, 3, padded.length - 2);

    expect(reader.bytes.offsetInBytes, 3);
    expect(reader.readUint8(), 0xfe);
    expect(reader.readUint16(), 0xfedc);
    expect(reader.readUint32(), 0xfedcba98);
    expect(reader.readInt16(), -12345);
    expect(reader.readUtf8String(), '你好, Hetu 🌍');
    expect(reader.ip, reader.bytes.length);
  });
}
