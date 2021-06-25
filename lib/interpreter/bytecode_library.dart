import 'dart:typed_data';

import 'bytecode_reader.dart';

import 'const_table.dart';

import '../declaration/library.dart';

class HTBytecodeLibrary extends HTLibrary with BytecodeReader, ConstTable {
  HTBytecodeLibrary(String id, Uint8List bytes) : super(id) {
    this.bytes = bytes;
  }
}
