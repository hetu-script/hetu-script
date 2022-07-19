import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'lib/');
  final hetu = Hetu(sourceContext: sourceContext);

  final source = sourceContext.getResource('core/main.ht');
  final module = hetu.bundle(source);
  if (module.errors.isNotEmpty) {
    for (final err in module.errors) {
      print(err);
    }
    throw 'Syntactic error(s) occurred while parsing.';
  }
  final bytes = hetu.compiler.compile(module);
  final outFile = File('hetu_core_test_compile.out');
  if (!outFile.existsSync()) {
    outFile.createSync(recursive: true);
  }
  outFile.writeAsBytesSync(bytes);
}
