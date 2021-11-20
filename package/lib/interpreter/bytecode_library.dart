import 'dart:typed_data';

import '../declaration/namespace/library.dart';
import 'bytecode_reader.dart';
import 'const_table.dart';

class HTBytecodeLibrary extends HTLibrary with BytecodeReader, ConstTable {
  HTBytecodeLibrary(String id, Uint8List bytes) : super(id) {
    this.bytes = bytes;
  }
}
