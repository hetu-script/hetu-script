library hetu_script_dev_tools;

import 'package:hetu_script/hetu_script.dart';

import 'extensions/extension_bindings.dart';

export 'context/file_system_context.dart';
export 'logger/logger.dart';
export 'util/uuid.dart';

part 'extensions/extension_modules.dart';

extension HTExtension on Hetu {
  // TODO: add extension config, if there's more than one extension
  void loadExtensions() {
    for (final file in extensionModules.keys) {
      eval(
        extensionModules[file]!,
        moduleFullName: file,
        globallyImport: true,
        type: SourceType.module,
      );
    }
    bindExternalClass(HTConsoleClass());
  }
}
