import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:args/args.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/parser.dart';
import 'package:hetu_script/analyzer.dart';

import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

var cliHelp = r'''
Hetu Script Command-line Tool
Version: {0}
Usage:
hetu [command] [option]
For [command] usage, you can type '--help' after it, example:
hetu run -h
commands:
  run [path] [option]
  format [path] [option]
  analyze [path] [option]
  compile [path] [output_path] [option]
''';

var replInfo = r'''
Hetu Script Read-Evaluate-Print-Loop Tool
Version: {0}
Enter expression to evaluate.
Enter '\' for multiline, enter '.exit' to quit.''';

const kSeperator = '------------------------------------------------';

final argParser = ArgParser();

late Hetu hetu;
final currentDir = Directory.current;
final sourceContext = HTFileSystemResourceContext(
    root: currentDir.path,
    expressionModuleExtensions: [
      HTResource.json,
      HTResource.jsonWithComments,
    ]);

void main(List<String> arguments) {
  try {
    hetu = Hetu(sourceContext: sourceContext);
    hetu.init();
    final version = HTCompiler.version.toString();
    replInfo = replInfo.replaceAll('{0}', version);
    cliHelp = cliHelp.replaceAll('{0}', version);

    if (arguments.isEmpty) {
      enterReplMode();
    } else {
      final results = parseArg(arguments);
      if (results['help']) {
        print(argParser.usage);
      } else if (results['version']) {
        print('Hetu Script Language, version: $version');
      } else if (results.command != null) {
        final cmd = results.command!;
        switch (cmd.name) {
          case 'run':
            if (cmd['help']) {
              print(
                  'hetu run [path] [option]\nInterpret a Hetu script file and print its result to terminal.');
            } else {
              run(cmd.arguments, enterRepl: cmd['repl']);
            }
            break;
          case 'format':
            if (cmd['help']) {
              print('hetu format [path] [option]\nFormat a Hetu script file.');
            } else {
              format(cmd.arguments,
                  outPath: cmd['out'], printResult: cmd['print']);
            }
            break;
          case 'analyze':
            if (cmd['help']) {
              print(
                  'hetu analyze [path] [option]\nAnalyze a Hetu script file.');
            } else {
              analyze(cmd.arguments);
            }
            break;
          case 'compile':
            if (cmd['help']) {
              print(
                  'hetu compile [path] [output_path] [option]\nCompile a Hetu script file.');
            } else {
              compile(cmd.arguments);
            }
            break;
        }
      } else {
        throw 'Error: Unrecognizable commands: $arguments.';
      }
    }
  } catch (e) {
    print(e);
  }
}

void enterReplMode({String? prompt}) {
  print(replInfo);
  print(kSeperator);
  if (prompt != null) {
    print('Module execution result:\n');
    print([prompt]);
    print(kSeperator);
  }
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
        final result = hetu.eval(input, globallyImport: true);
        print(result);
      } catch (e) {
        if (e is HTError) {
          print(e.message);
        } else {
          print(e);
        }
        print(''); // flush the std to prevent unintended input capture.
      }
    }
  }
}

ArgResults parseArg(List<String> args) {
  argParser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show command help.');
  argParser.addFlag('version',
      abbr: 'v',
      negatable: false,
      help: 'Show version of current using hetu_script package.');
  final runCmd = argParser.addCommand('run');
  runCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show run command help.');
  runCmd.addFlag('repl',
      abbr: 'r', negatable: false, help: 'Enter REPL mode after evaluation.');
  final fmtCmd = argParser.addCommand('format');
  fmtCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show format command help.');
  fmtCmd.addFlag('print',
      abbr: 'p', negatable: false, help: 'Print format result to terminal.');
  fmtCmd.addOption('out', abbr: 'o', help: 'Save format result to file.');
  final analyzeCmd = argParser.addCommand('analyze');
  analyzeCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show analyze command help.');
  final compileCmd = argParser.addCommand('compile');
  compileCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show compile command help.');
  return argParser.parse(args);
}

void run(List<String> args, {bool enterRepl = false}) {
  if (args.isEmpty) {
    throw 'Error: Path argument is required for \'run\' command.';
  }
  dynamic result;
  final ext = path.extension(args.first);
  if (ext == HTResource.hetuModule || ext == HTResource.hetuScript) {
    if (args.length == 1) {
      result = hetu.evalFile(args.first, globallyImport: true);
    } else {
      final scriptInvocationArgs = <String>[];
      if (args.length > 2) {
        for (var i = 2; i < args.length; ++i) {
          scriptInvocationArgs.add(args[i]);
        }
      }
      result = hetu.evalFile(args.first,
          globallyImport: true,
          invokeFunc: args[1],
          positionalArgs: scriptInvocationArgs);
    }
  } else {
    final file = File(args.first);
    final bytes = file.readAsBytesSync();
    if (args.length == 1) {
      result = hetu.loadBytecode(
          bytes: bytes, moduleName: args.first, globallyImport: true);
    } else {
      final scriptInvocationArgs = <String>[];
      if (args.length > 2) {
        for (var i = 2; i < args.length; ++i) {
          scriptInvocationArgs.add(args[i]);
        }
      }
      result = hetu.loadBytecode(
          bytes: bytes,
          moduleName: args.first,
          globallyImport: true,
          invokeFunc: args[1],
          positionalArgs: scriptInvocationArgs);
    }
  }
  final prompt =
      'Loaded module: [${args.first}] with execution result:\n[$result]';
  if (enterRepl) {
    enterReplMode(prompt: prompt);
  } else {
    print(prompt);
  }
}

void format(List<String> args, {String? outPath, bool printResult = true}) {
  // final parser = HTAstParser();
  final formatter = HTFormatter();
  final context = HTFileSystemResourceContext();
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
      final curPath = path.dirname(source.fullName);
      final name = path.basenameWithoutExtension(outPath);
      outPath = path.join(curPath, '$name.ht');
    }
  } else {
    outPath = source.fullName;
  }
  final outFile = File(outPath);
  outFile.writeAsStringSync(fmtResult);
  print('Saved formatted file to:');
  print(outPath);
}

void analyze(List<String> args) {
  try {
    final analyzer = HTAnalyzer(sourceContext: sourceContext);
    analyzer.init();
    final result = analyzer.evalFile(args.first);
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
  } catch (e) {
    print(e);
  }
}

void compile(List<String> args, {String? outPath}) {
  if (args.isEmpty) {
    throw 'Error: Path argument is required for \'compile\' command.';
  }
  final source = sourceContext.getResource(args.first);
  stdout.write('Compiling [${source.fullName}] ...');
  String? moduleName;
  if (args.length > 1) {
    moduleName = args[1];
  }

  final parser = HTParser(context: sourceContext);
  final module = parser.parseToModule(source, moduleName: moduleName);
  if (parser.errors!.isNotEmpty) {
    for (final err in parser.errors!) {
      print(err);
    }
    throw 'Syntactic error(s) occurred while parsing.';
  } else {
    final compileConfig = CompilerConfig(compileWithLineInfo: false);
    final compiler = HTCompiler(config: compileConfig);
    final bytes = compiler.compile(module);
    final curPath = path.dirname(source.fullName);
    late String outName;
    if (outPath != null) {
      if (!path.isAbsolute(outPath)) {
        final name = path.basename(outPath);
        outName = path.join(curPath, name);
      } else {
        outName = outPath;
      }
    } else {
      outName = path.join(
          curPath, path.basenameWithoutExtension(source.fullName) + '.out');
    }
    final outFile = File(outName);
    outFile.writeAsBytesSync(bytes);
    stdout.writeln(' done!');
  }
}
