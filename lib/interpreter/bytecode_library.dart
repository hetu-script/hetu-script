import 'dart:typed_data';

import '../source/source.dart';
import '../declaration/library.dart';
import 'bytecode_reader.dart';
import 'const_table.dart';

class HTBytecodeLibrary extends HTLibrary with BytecodeReader, ConstTable {
  HTBytecodeLibrary(String id, Uint8List bytes, Map<String, HTSource> sources)
      : super(id, sources) {
    this.bytes = bytes;
  }
}
