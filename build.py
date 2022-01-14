import os

os.system('hetu compile lib/core/main.ht -o packages/hetu_script/lib/interpreter/preincludes/preinclude_module.dart -m "hetu:main" -a "hetuCoreModule"')
os.system('hetu compile lib/console/console.ht -o packages/hetu_script_dev_tools/lib/preincludes/preinclude_module.dart -m "hetu:console" -a "consoleModule"')
