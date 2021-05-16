import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:hetu_script/analyzer/parser.dart';

import 'package:hetu_script/hetu_script.dart';

const cli_help = r'''
Hetu Script Command-line Tool
Version: 0.1.0
Usage:
hetu [option] [file_name] [invoke_func]
If only [file_name] is provided, evaluate the file in function mode.
If [file_name] and [invoke_func] is both provided, will interpret code as a program.''';

const repl_info = r'''
Hetu Script Read-Evaluate-Print-Loop Tool
Version: 0.1.0
Enter expression to evaluate.
Enter '\' for multiline, enter '.exit' to quit.''';

final hetu = Hetu();

void main(List<String> arguments) async {
  try {
    await hetu.init();

    dynamic result;
    if (arguments.isEmpty) {
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

          result = await hetu.eval(input,
              config: InterpreterConfig(sourceType: SourceType.script));
          print(result);
        }
      }
    } else {
      final results = parseArg(arguments);
      if (results['help']) {
        print(cli_help);
      } else if (results.command != null) {
        final cmdResults = results.command!;
        final cmdArgs = cmdResults.arguments;

        final targetPath = cmdArgs.first;
        if (path.extension(targetPath) != '.ht') {
          throw 'Error: target file extension is not \'.ht\'';
        }

        final sourceType =
            cmdResults['script'] ? SourceType.script : SourceType.module;

        switch (cmdResults.name) {
          case 'fmt':
            var outPath = cmdResults['out'];

            final parser = HTAstParser();
            final formatter = HTFormatter();
            final sourceProvider = DefaultSourceProvider();
            final source = await sourceProvider.getSource(cmdArgs.first);

            try {
              final printResult = cmdResults['print'];

              final config = ParserConfig(sourceType: sourceType);
              final compilation = await parser.parse(
                  source.content, sourceProvider, source.fullName, config);

              final module = compilation.fetch(source.fullName);

              await formatter.format(module);

              if (printResult) {
                print(module.content);
              }

              if (outPath != null) {
                if (!path.isAbsolute(outPath)) {
                  final curPath = path.dirname(source.fullName);
                  final name = path.basenameWithoutExtension(outPath);
                  outPath = path.join(curPath, '$name.ht');
                }
              } else {
                outPath = module.fullName;
              }

              final outFile = File(outPath);
              outFile.writeAsStringSync(module.content);

              print('Saved formatted file to:');
              print(outPath);
            } catch (e) {
              if (e is HTError && e.type == ErrorType.compileError) {
                e.moduleFullName = parser.curModuleFullName;
                e.line = parser.curLine;
                e.column = parser.curColumn;
              }
              rethrow;
            }

            break;
          case 'run':
            await run(cmdArgs);
            break;
        }
      } else {
        await run(arguments);
      }
    }
  } catch (e, stack) {
    print(e);
    print(stack);
  }
}

Future<void> run(List<String> args,
    [SourceType sourceType = SourceType.script]) async {
  dynamic result;
  final config = InterpreterConfig(sourceType: sourceType);
  if (args.length == 1) {
    result = await hetu.import(args.first, config: config);
  } else {
    result = await hetu.import(args.first, config: config, invokeFunc: args[1]);
  }
  print('Execution result:');
  print(result);
}

ArgResults parseArg(List<String> args) {
  final parser = ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false);
  final runCmd = parser.addCommand('run');
  runCmd.addFlag('script', abbr: 's');
  final fmtCmd = parser.addCommand('fmt');
  fmtCmd.addFlag('script');
  fmtCmd.addFlag('save', abbr: 's');
  fmtCmd.addFlag('print', abbr: 'p');
  fmtCmd.addOption('out', abbr: 'o');

  return parser.parse(args);
}
