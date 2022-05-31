import os

os.system('dart ../bin/cli_tool.dart compile ../example/script/hello.hts -o ../example/script/hello.out')
os.system('dart ../bin/cli_tool.dart run example/script/hello.out')
