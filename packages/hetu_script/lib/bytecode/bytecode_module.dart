import 'dart:typed_data';

import 'package:hetu_script/hetu_script.dart';
import 'package:pub_semver/pub_semver.dart';

import '../value/namespace/namespace.dart';
import 'bytecode_reader.dart';
import '../constant/global_constant_table.dart';

/// A bytecode module contains the compiled bytes,
/// after the execution of the interpreter, it will also contain namespaces & values.
class HTBytecodeModule extends HTGlobalConstantTable with BytecodeReader {
  /// The version of this module, will be read from the bytes later.
  Version? version;

  /// The compiled time of this module, will be read from the bytes later.
  String? compiledAt;

  /// The name of this module.
  final String id;

  /// An interpreted source is exist as a namespace in bytecode module.
  /// This is empty until interpreter insert the evaled values.
  final Map<String, HTNamespace> namespaces = {};

  /// An interpreted non-source, such as JSON, is exist as a value in bytecode module.
  /// This is empty until interpreter insert the evaled values.
  final Map<String, HTJsonSource> jsonSources = {};

  /// fetch a contant value defined within any namespace of this module.
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
