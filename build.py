import os

os.system('dart pub global activate --source path packages\hetu_script_dev_tools')

os.system('hetu compile lib/core/main.ht -o packages/hetu_script/lib/interpreter/preincludes/preinclude_module.dart -m "hetu:main" -a "hetuCoreModule"')

os.system('hetu compile lib/console/console.ht -o packages/hetu_script_dev_tools/lib/preincludes/preinclude_module.dart -m "hetu:console" -a "consoleModule"')
