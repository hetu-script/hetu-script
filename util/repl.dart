import 'dart:io';

import 'package:hetu_script/hetu_script.dart';

const cli_help = '''

  Hetu Script Command-line Tool
  Version: 0.0.1
  Usage:

  hetu [option] [file_name] [invoke_func]
  
  If [file_name] is provided, evaluate the file in function mode.
  
  If [invoke_func] is provided, will switch to program style interpretation.
  Otherwise interpret file as a function.
        ''';

void main(List<String> args) async {
  try {
    var hetu = HT_Interpreter();

    dynamic result;
    if (args.isNotEmpty) {
      if ((args.first == '--help') || (args.first == '-h')) {
        print(cli_help);
      } else if (args.length == 1) {
        result = await hetu.evalf(args.first, style: ParseStyle.function);
      } else {
        result = await hetu.evalf(args.first, style: ParseStyle.library, invokeFunc: args[1]);
      }
      if (result != null) print(result);
    } else {
      stdout.writeln('\nHetu Script Read-Evaluate-Print-Loop Tool\n'
          'Version: 0.0.1\n\n'
          'Enter your code to evaluate.\n'
          'Enter \'\\\' for multiline, enter \'quit\' to quit.\n');
      var quit = false;

      while (!quit) {
        stdout.write('>>>');
        var input = stdin.readLineSync();

        if ((input == 'exit') || (input == 'quit') || (input == 'close') || (input == 'end')) {
          quit = true;
        } else {
          if (input!.endsWith('\\')) {
            input += '\n' + stdin.readLineSync()!;
          }

          try {
            result = hetu.eval(input, style: ParseStyle.function);
            if (result != null) print(result);
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
