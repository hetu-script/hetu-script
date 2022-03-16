import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'example/script/');
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();
  final binaryFile = File('example/script/module.out');
  final bytes = binaryFile.readAsBytesSync();
  hetu.interpreter.loadBytecode(bytes: bytes, moduleName: 'calculate');

  hetu.evalFile('import_binary_module.hts');
}
