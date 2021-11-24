import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:args/args.dart';

import 'package:hetu_script/hetu_script.dart';

import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

const cliHelpText = r'''
Hetu Script Command-line Tool
Version: 0.1.0
Usage:
hetu [command] [option]
  command:
    format [path] [option]
      --script(-s)
      --print(-p)
      --out(-o) [outpath]
    analyze [path] [option]
      --script(-s)
    run [path] [option]
      --script(-s)
hetu [option]
  option:
    --help(-h)
''';

const replInfoText = r'''
Hetu Script Read-Evaluate-Print-Loop Tool
Version: 0.1.0
Enter expression to evaluate.
Enter '\' for multiline, enter '.exit' to quit.''';

final hetu = Hetu(config: InterpreterConfig(showDartStackTrace: false));

void main(List<String> arguments) {
  try {
    hetu.init();
    if (arguments.isEmpty) {
      print(replInfoText);
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
            final result = hetu.eval(input, type: SourceType.script);
            print(result);
          } catch (e) {
            if (e is HTError) {
              print(e.message);
            } else {
              print(e);
            }
          }
        }
      }
    } else {
      final results = parseArg(arguments);
      if (results['help']) {
        print(cliHelpText);
      } else if (results.command != null) {
        final cmd = results.command!;
        final cmdArgs = cmd.arguments;
        final targetPath = cmdArgs.first;
        if (path.extension(targetPath) != hetuSouceFileExtension) {
          throw 'Error: target file is not of extension \'$hetuSouceFileExtension\'';
        }
        final sourceType =
            cmd['script'] ? SourceType.script : SourceType.module;
        switch (cmd.name) {
          case 'run':
            run(cmdArgs, sourceType);
            break;
          case 'format':
            format(cmdArgs, cmd['out'], cmd['print']);
            break;
          case 'analyze':
            analyze(cmdArgs, sourceType);
            break;
        }
      } else {
        run(arguments);
      }
    }
  } catch (e) {
    print(e);
  }
}

ArgResults parseArg(List<String> args) {
  final parser = ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false);
  final runCmd = parser.addCommand('run');
  runCmd.addFlag('script', abbr: 's');
  final fmtCmd = parser.addCommand('format');
  fmtCmd.addFlag('script', abbr: 's');
  fmtCmd.addFlag('print', abbr: 'p');
  fmtCmd.addOption('out', abbr: 'o');
  final analyzeCmd = parser.addCommand('analyze');
  analyzeCmd.addFlag('script', abbr: 's');
  return parser.parse(args);
}

void run(List<String> args, [SourceType sourceType = SourceType.script]) {
  dynamic result;
  if (args.length == 1) {
    result = hetu.evalFile(args.first, type: sourceType);
  } else {
    result = hetu.evalFile(args.first, type: sourceType, invokeFunc: args[1]);
  }
  print('Execution result:');
  print(result);
}

void format(List<String> args, [String? outPath, bool printResult = true]) {
  // final parser = HTAstParser();
  final formatter = HTFormatter();
  final context = HTFileSystemSourceContext();
  final source = context.getResource(args.first);
  // final config = ParserConfig(sourceType: sourceType);
  // final compilation = parser.parseToCompilation(source); //, config);
  // final module = compilation.modules[source.fullName]!;
  final fmtResult = formatter.formatString(source.content);
  if (printResult) {
    print(fmtResult);
  }
  if (outPath != null) {
    if (!path.isAbsolute(outPath)) {
      final curPath = path.dirname(source.name);
      final name = path.basenameWithoutExtension(outPath);
      outPath = path.join(curPath, '$name.ht');
    }
  } else {
    outPath = source.name;
  }
  final outFile = File(outPath);
  outFile.writeAsStringSync(fmtResult);
  print('Saved formatted file to:');
  print(outPath);
}

void analyze(List<String> args, [SourceType sourceType = SourceType.script]) {
  final analyzer = HTAnalyzer();
  analyzer.init();
  final result = analyzer.evalFile(args.first, type: sourceType);
  if (result != null) {
    if (result.errors.isNotEmpty) {
      print('Analyzer found ${result.errors.length} problems:');
      for (final err in result.errors) {
        print(err);
      }
    } else {
      print('Analyzer found 0 problem.');
    }
  } else {
    print('Unkown error occurred during analysis.');
  }
}
