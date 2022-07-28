import 'dart:typed_data';

import 'package:pub_semver/pub_semver.dart';

import '../value/namespace/namespace.dart';
import 'bytecode_reader.dart';
import '../constant/global_constant_table.dart';

class HTBytecodeModule with BytecodeReader, HTGlobalConstantTable {
  // will be read from the bytes later.
  Version? version;
  String? compiledAt;

  final String id;

  /// a interpreted source is exist as a namespace in bytecode module.
  final Map<String, HTNamespace> namespaces = {};

  /// a interpreted non-source, such as JSON, is exist as a value in bytecode module.
  final Map<String, dynamic> values = {};

  String getConstString() {
    final index = readUint16();
    return getGlobalConstant(String, index);
  }

  HTBytecodeModule({
    required this.id,
    required Uint8List bytes,
  }) {
    this.bytes = bytes;
  }
}
