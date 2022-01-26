import os

os.system('dart packages/hetu_script_dev_tools/bin/cli_tool.dart compile lib/core/main.ht -o packages/hetu_script/lib/interpreter/preincludes/preinclude_module.dart -m "hetu:main" -a "hetuCoreModule"')

os.system('dart packages/hetu_script_dev_tools/bin/cli_tool.dart compile lib/console/console.ht -o packages/hetu_script_dev_tools/lib/preincludes/preinclude_module.dart -m "hetu:console" -a "consoleModule"')

os.system('dart pub global activate --source path packages/hetu_script_dev_tools')
