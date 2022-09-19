import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'examples/script/');
  final hetu = Hetu(
    sourceContext: sourceContext,
    config: HetuConfig(
      checkTypeAnnotationAtRuntime: true,
    ),
  );
  hetu.init();
  final binaryFile = File('examples/script/module.out');
  final bytes = binaryFile.readAsBytesSync();
  hetu.interpreter.loadBytecode(bytes: bytes, moduleName: 'actor');

  hetu.evalFile('import_binary_module.hts');
}
