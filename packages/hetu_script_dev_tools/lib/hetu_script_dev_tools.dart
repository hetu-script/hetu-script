library hetu_script_dev_tools;

import 'dart:typed_data';

import 'package:hetu_script/hetu_script.dart';

import 'extensions/extension_bindings.dart';
import 'preincludes/preinclude_module.dart';

export 'context/file_system_context.dart';
export 'logger/logger.dart';

extension HTExtension on HTInterpreter {
  void loadExtensions(Iterable<String> extensions) {
    if (extensions.contains('console')) {
      bindExternalClass(HTConsoleClass());
      // load precompiled core module.
      final coreModule = Uint8List.fromList(consoleModule);
      loadBytecode(
          bytes: coreModule, moduleName: 'hetu_console', globallyImport: true);
    }
  }
}
