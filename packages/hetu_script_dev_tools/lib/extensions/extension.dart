import 'dart:typed_data';

import 'package:hetu_script/hetu_script.dart';

import 'extension_bindings.dart';
import '../preincludes/preinclude_module.dart';

extension HTExtension on Hetu {
  void loadModuleConsole() {
    interpreter.bindExternalClass(HTConsoleClass());
    // load precompiled core module.
    final coreModule = Uint8List.fromList(consoleModule);
    interpreter.loadBytecode(
        bytes: coreModule, module: 'hetu_console', globallyImport: true);
  }
}
