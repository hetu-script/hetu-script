import os
import subprocess

try:
    result = subprocess.run(
        'dart run utils/compile_hetu.dart',
        shell=True,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    print(result.stdout)  

    result = subprocess.run(
        'dart pub global activate --source path packages/hetu_script_dev_tools',
        shell=True,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    print(result.stdout)  
    
    err_code = os.system('dart pub global run hetu_script_dev_tools:cli_tool')

    if err_code != 0:
        print(f"Error: Command exited with code {err_code}")
   
except subprocess.CalledProcessError as e:
    print(f"Error occurred: {e.stderr}")
