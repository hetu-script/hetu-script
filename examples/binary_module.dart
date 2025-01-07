import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'examples/script/');
  final hetu = Hetu(
    sourceContext: sourceContext,
    config: HetuConfig(
      // checkTypeAnnotationAtRuntime: true,
      // printPerformanceStatistics: true,
      removeAssertion: true,
      removeDocumentation: true,
      removeLineInfo: false,
    ),
  );
  hetu.init();
  final binaryFile = File('examples/script/module.out');
  final mod = hetu.compileFile('module.ht');
  binaryFile.writeAsBytesSync(mod);
  print('byte length: ${mod.length}');
  hetu.interpreter.loadBytecode(bytes: mod, module: 'actor');

  hetu.evalFile('import_binary_module.hts');
}
