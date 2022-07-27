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

  final output = StringBuffer();
  output.writeln('''/// The pre-compiled binary code of [${source.basename}].
/// This file has been automatically generated, please do not edit manually.
final hetuCoreModule = [''');
  for (var i = 0; i < bytes.length; ++i) {
    output.write('  ${bytes[i]}');
    if (i < bytes.length - 1) {
      output.write(',');
    }
    output.writeln();
  }
  output.writeln('];');

  final content = output.toString();
  final outFile =
      File('packages/hetu_script/lib/preincludes/preinclude_module.dart');
  if (!outFile.existsSync()) {
    stdout.write('path not exist, creating file ...');
    outFile.createSync(recursive: true);
  }
  outFile.writeAsStringSync(content);
  print('done!');
}
