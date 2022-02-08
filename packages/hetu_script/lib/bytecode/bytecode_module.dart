import 'dart:typed_data';

import '../value/namespace/namespace.dart';
import 'bytecode_reader.dart';
import '../constant/constant_module.dart';

class HTBytecodeModule with BytecodeReader, HTConstantModule {
  final String id;

  final Map<String, HTNamespace> namespaces;

  final expressions = <String, dynamic>{};

  String readString() {
    final index = readUint16();
    return getConstant(String, index);
  }

  HTBytecodeModule(this.id, Uint8List bytes,
      {Map<String, HTNamespace>? declarations})
      : namespaces = declarations ?? <String, HTNamespace>{} {
    this.bytes = bytes;
  }
}
