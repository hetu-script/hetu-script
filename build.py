import os

os.system('dart run utils/compile_hetu.dart')

os.system('dart run packages/hetu_script_dev_tools/bin/cli_tool.dart compile lib/core/main.ht packages/hetu_script/lib/preincludes/preinclude_module.dart -a "hetuCoreModule"')

os.system('dart run packages/hetu_script_dev_tools/bin/cli_tool.dart compile lib/console/console.ht packages/hetu_script_dev_tools/lib/preincludes/preinclude_module.dart -a "consoleModule"')

os.system('dart pub global activate --source path packages/hetu_script_dev_tools')
