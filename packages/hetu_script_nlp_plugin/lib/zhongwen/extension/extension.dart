import 'dart:typed_data';

import 'package:hetu_script/hetu_script.dart';

import '../preincludes/preinclude_module.dart';

extension HTExtension on Hetu {
  void loadModuleZhongwen() {
    // load precompiled core module.
    final coreModule = Uint8List.fromList(zhongwenModule);
    interpreter.loadBytecode(
        bytes: coreModule, module: 'hetu_console', globallyImport: true);
  }
}
