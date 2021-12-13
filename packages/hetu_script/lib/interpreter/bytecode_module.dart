import 'dart:typed_data';

import '../declaration/namespace/module.dart';
import 'bytecode_reader.dart';
import 'const_table.dart';

class HTBytecodeModule extends HTModule with BytecodeReader, ConstTable {
  HTBytecodeModule(String id, Uint8List bytes) : super(id) {
    this.bytes = bytes;
  }
}
