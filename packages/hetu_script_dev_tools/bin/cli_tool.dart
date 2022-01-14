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
  analyze [path] [option]
  format [path] [output_path] [option]
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
final sourceContext = HTFileSystemResourceContext(expressionModuleExtensions: [
  HTResource.json,
  HTResource.jsonWithComments,
]);

void main(List<String> arguments) {
  try {
    hetu = Hetu(sourceContext: sourceContext);
    hetu.init();
    final version = kHetuVersion.toString();
    replInfo = replInfo.replaceAll('{0}', version);
    cliHelp = cliHelp.replaceAll('{0}', version);

    if (arguments.isEmpty) {
      enterReplMode();
    } else {
      final results = parseArg(arguments);
      if (results['help']) {
        print(cliHelp);
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
          case 'analyze':
            if (cmd['help']) {
              print(
                  'hetu analyze [path] [option]\nAnalyze a Hetu script file.');
            } else {
              analyze(cmd.arguments);
            }
            break;
          case 'format':
            if (cmd['help']) {
              print('hetu format [path] [option]\nFormat a Hetu script file.');
            } else {
              format(cmd.arguments, cmd['out']);
            }
            break;
          case 'compile':
            if (cmd['help']) {
              print(
                  'hetu compile [path] [output_path] [option]\nCompile a Hetu script file.');
            } else {
              final outPath = cmd['out'];
              if (outPath == null) {
                throw 'Error: Outpath argument is required for \'compile\' command.';
              }
              compile(cmd.arguments, outPath,
                  moduleName: cmd['module'],
                  compileToIntArrayWithName: cmd['array']);
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
  fmtCmd.addOption('out', abbr: 'o', help: 'Save format result to file.');
  final analyzeCmd = argParser.addCommand('analyze');
  analyzeCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show analyze command help.');
  final compileCmd = argParser.addCommand('compile');
  compileCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show compile command help.');
  compileCmd.addOption('out', abbr: 'o', help: 'Save compile result to file.');
  compileCmd.addOption('module',
      abbr: 'm', help: 'Module name of the library to be compiled.');
  compileCmd.addOption('array', abbr: 'a', help: 'Compile to dart array.');
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

void format(List<String> args, String outPath) {
  // final parser = HTAstParser();
  final formatter = HTFormatter();
  final context = HTFileSystemResourceContext();
  final source = context.getResource(args.first);
  stdout.write('Formating: [${source.fullName}] ... ');
  // final config = ParserConfig(sourceType: sourceType);
  // final compilation = parser.parseToCompilation(source); //, config);
  // final module = compilation.modules[source.fullName]!;
  final fmtResult = formatter.formatString(source.content);
  if (!path.isAbsolute(outPath)) {
    final joined = path.join(sourceContext.root, outPath);
    outPath = sourceContext.getAbsolutePath(key: joined);
  }
  final outFile = File(outPath);
  if (!outFile.existsSync()) {
    stdout.write('path not exist, creating file ...');
    outFile.createSync(recursive: true);
  }
  outFile.writeAsStringSync(fmtResult);
  stdout.writeln('done!');
}

void analyze(List<String> args) {
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
}

void compile(List<String> args, String? outPath,
    {String? moduleName, String? compileToIntArrayWithName}) {
  if (args.isEmpty) {
    throw 'Error: Path argument is required for \'compile\' command.';
  }

  final source = sourceContext.getResource(args.first);
  stdout.write('Compiling [${source.fullName}] ');
  if (moduleName != null) {
    stdout.write('with module name: [$moduleName] ...');
  } else {
    stdout.write('with module name: [${source.fullName}] ...');
  }

  final parser = HTParser(context: sourceContext);
  final module = parser.parseToModule(source, moduleName: moduleName);
  if (module.errors.isNotEmpty) {
    for (final err in module.errors) {
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
        final joined = path.join(sourceContext.root, outPath);
        outName = sourceContext.getAbsolutePath(key: joined);
      } else {
        outName = outPath;
      }
    } else {
      outName = path.join(
          curPath,
          path.basenameWithoutExtension(source.fullName) +
              (compileToIntArrayWithName != null ? '.dart' : '.out'));
    }

    if (compileToIntArrayWithName != null) {
      final output = StringBuffer();
      output.writeln(
          '''/// The pre-compiled binary code of [${moduleName ?? source.basename}].
/// This file has been automatically generated, please do not edit manually.
final $compileToIntArrayWithName = [''');
      for (var i = 0; i < bytes.length; ++i) {
        output.write('  ${bytes[i]}');
        if (i < bytes.length - 1) {
          output.write(',');
        }
        output.writeln();
      }
      output.writeln('];');

      final content = output.toString();
      final outFile = File(outName);
      if (!outFile.existsSync()) {
        stdout.write('path not exist, creating file ...');
        outFile.createSync(recursive: true);
      }
      outFile.writeAsStringSync(content);
      stdout.write('done!');
    } else {
      final outFile = File(outName);
      if (!outFile.existsSync()) {
        stdout.write('path not exist, creating file ...');
        outFile.createSync(recursive: true);
      }
      outFile.writeAsBytesSync(bytes);
      stdout.write('done!');
    }
  }
}
