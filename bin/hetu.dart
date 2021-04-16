import 'dart:io';

import 'package:hetu_script/hetu_script.dart';

const cli_help = '''
Hetu Script Command-line Tool
Version: 0.1.0
Usage:
hetu [option] [file_name] [invoke_func]
If only [file_name] is provided, evaluate the file in function mode.
If [file_name] and [invoke_func] is both provided, will interpret code as a program.''';

const repl_info = '''
Hetu Script Read-Evaluate-Print-Loop Tool
Version: 0.1.0
Enter expression to evaluate.
Enter '\' for multiline, enter '.exit' to quit.''';

void main(List<String> args) async {
  try {
    final hetu = Hetu();
    await hetu.init();

    dynamic result;
    if (args.isNotEmpty) {
      if ((args.first == '--help') || (args.first == '-h')) {
        print(cli_help);
      } else if (args.length == 1) {
        result = await hetu.import(args.first, codeType: CodeType.script);
      } else {
        result = await hetu.import(args.first,
            codeType: CodeType.module, invokeFunc: args[1]);
      }
      if (result != null) print(result);
    } else {
      print(repl_info);
      var exit = false;

      while (!exit) {
        stdout.write('>>>');
        var input = stdin.readLineSync();

        if (input == '.exit') {
          exit = true;
        } else {
          if (input!.endsWith('\\')) {
            input += '\n' + stdin.readLineSync()!;
          }

          try {
            result = await hetu.eval(input, codeType: CodeType.function);
            print(result);
          } catch (e) {
            print(e);
          }
        }
      }
    }
  } catch (e) {
    print(e);
  }
}
