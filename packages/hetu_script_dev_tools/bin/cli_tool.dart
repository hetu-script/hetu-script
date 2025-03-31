import 'dart:io';

import 'package:path/path.dart' as path;
// import 'package:args/command_runner.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:args/args.dart';

import 'common.dart';
// import 'command.dart';

enum ConsoleColor {
  red,
  green,
  yellow,
  blue,
  none,
}

const kConsoleColorRed = '\x1B[31m';
const kConsoleColorGreen = '\x1B[32m';
const kConsoleColorYellow = '\x1B[33m';
const kConsoleColorBlue = '\x1B[34m';
const kConsoleColorReset = '\x1B[0m';

final argParser = ArgParser();
late final ArgParser runCmd, formatCmd, analyzeCmd, compileCmd;

void initargParser() {
  argParser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show command help.');
  argParser.addFlag('version',
      negatable: false,
      help: 'Show version of current using hetu_script package.');
  runCmd = argParser.addCommand('run');
  runCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show run command help.');
  runCmd.addFlag('repl',
      abbr: 'r', negatable: false, help: 'Enter REPL mode after evaluation.');
  runCmd.addFlag('perfs',
      abbr: 'p', negatable: false, help: 'Print performance statistics.');
  formatCmd = argParser.addCommand('format');
  formatCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show format command help.');
  formatCmd.addOption('out', abbr: 'o', help: 'Save format result to file.');
  analyzeCmd = argParser.addCommand('analyze');
  analyzeCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show analyze command help.');
  compileCmd = argParser.addCommand('compile');
  compileCmd.addFlag('help',
      abbr: 'h', negatable: false, help: 'Show compile command help.');
  compileCmd.addOption('out', abbr: 'o', help: 'Save compile result to file.');
  compileCmd.addOption('array', abbr: 'a', help: 'Compile to dart array.');
  compileCmd.addOption('version',
      abbr: 'v', help: 'Set the version string for this module.');
}

void info(String message, {ConsoleColor color = ConsoleColor.green}) {
  switch (color) {
    case ConsoleColor.red:
      print('$kConsoleColorRed$message$kConsoleColorReset');
      return;
    case ConsoleColor.green:
      print('$kConsoleColorGreen$message$kConsoleColorReset');
      return;
    case ConsoleColor.yellow:
      print('$kConsoleColorYellow$message$kConsoleColorReset');
      return;
    case ConsoleColor.blue:
      print('$kConsoleColorBlue$message$kConsoleColorReset');
      return;
    case ConsoleColor.none:
      print(message);
  }
}

void main(List<String> arguments) {
  hetu.init();
  initargParser();

  try {
    final version = kHetuVersion.toString();
    replInfo = replInfo.replaceAll('{0}', version);
    cliHelp = cliHelp.replaceAll('{0}', version);

    if (arguments.isEmpty) {
      enterReplMode();
    } else {
      final results = argParser.parse(arguments);
      if (results['help']) {
        info(cliHelp);
        info(argParser.usage);
      } else if (results['version']) {
        info('Hetu Script Language, version: $version');
      } else if (results.command != null) {
        final cmd = results.command!;
        switch (cmd.name) {
          case 'run':
            if (cmd['help']) {
              info(r'''hetu run [path] [option]
Interpret a Hetu script file and print its result to terminal.
''');
              info(runCmd.usage);
            } else {
              run(cmd.rest, enterRepl: cmd['repl'], printPerfs: cmd['perfs']);
            }
          case 'format':
            if (cmd['help']) {
              info('hetu format [path] [option]\nFormat a Hetu script file.');
              info(formatCmd.usage);
            } else {
              format(cmd.rest, cmd['out']);
            }
          case 'analyze':
            if (cmd['help']) {
              info('hetu analyze [path] [option]\nAnalyze a Hetu script file.');
              info(analyzeCmd.usage);
            } else {
              analyze(cmd.rest);
            }
          case 'compile':
            if (cmd['help']) {
              info(
                  'hetu compile [path] [output_path] [option]\nCompile a Hetu script file.');
              info(compileCmd.usage);
            } else {
              compile(
                cmd.rest,
                compileToIntArrayWithName: cmd['array'],
                versionString: cmd['version'],
              );
            }
        }
      } else {
        info('Unrecognizable commands: $arguments.', color: ConsoleColor.red);
      }
    }
  } catch (e) {
    info(e.toString(), color: ConsoleColor.red);
  }
}

void enterReplMode({dynamic prompt}) async {
  info(replInfo);
  if (prompt != null) {
    info(hetu.lexicon.stringify(prompt), color: ConsoleColor.blue);
  }
  while (true) {
    stdout.write('>>>');
    String input = '';
    bool inputContinued = true;
    while (inputContinued) {
      String? line = stdin.readLineSync();
      if (line == null || line.trim().isEmpty) {
        break;
      }
      if (line.endsWith('\\')) {
        line = line.substring(0, line.length - 1);
      } else {
        inputContinued = false;
      }
      input += '$line\n';
    }
    if (input == '.exit\n') {
      break;
    } else {
      try {
        dynamic result = hetu.eval(input);
        if (result is Future) {
          result = await result;
          info('(Future) ${hetu.lexicon.stringify(result)}',
              color: ConsoleColor.blue);
        } else {
          info(hetu.lexicon.stringify(result), color: ConsoleColor.blue);
        }
      } catch (error) {
        if (error is HTError) {
          if (showDetailsOfError) {
            info(error.toString(), color: ConsoleColor.red);
          } else {
            info(error.message,
                color: error.severity >= MessageSeverity.error
                    ? ConsoleColor.red
                    : ConsoleColor.yellow);
          }
        } else {
          info(error.toString(), color: ConsoleColor.red);
        }
        print('');
      }
    }
  }
}

void run(List<String> args, {bool enterRepl = false, bool printPerfs = false}) {
  if (args.isEmpty) {
    info('Path argument is required for \'run\' command.',
        color: ConsoleColor.red);
    return;
  }
  if (printPerfs) {
    hetu.config.printPerformanceStatistics = true;
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
          invoke: args[1],
          positionalArgs: scriptInvocationArgs);
    }
  } else {
    final file = File(args.first);
    final bytes = file.readAsBytesSync();
    if (args.length == 1) {
      result = hetu.interpreter
          .loadBytecode(bytes: bytes, module: args.first, globallyImport: true);
    } else {
      final scriptInvocationArgs = <String>[];
      if (args.length > 2) {
        for (var i = 2; i < args.length; ++i) {
          scriptInvocationArgs.add(args[i]);
        }
      }
      result = hetu.interpreter.loadBytecode(
          bytes: bytes,
          module: args.first,
          globallyImport: true,
          invoke: args[1],
          positionalArgs: scriptInvocationArgs);
    }
  }
  info('Loaded module: [${args.first}] with execution result:\n');
  if (enterRepl) {
    showDetailsOfError = true;
    enterReplMode(prompt: result);
  } else {
    info(hetu.lexicon.stringify(result));
  }
}

void format(List<String> args, String outPath) {
  // final parser = HTAstParser();
  final source = fileSystemResourceContext.getResource(args.first);
  info('Formating: [${source.fullName}] ... ');
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
    info('Path not exist, creating file ...', color: ConsoleColor.red);
    outFile.createSync(recursive: true);
  }
  outFile.writeAsStringSync(fmtResult);
  info('Saved file to [$outPath]', color: ConsoleColor.blue);
}

void analyze(List<String> args) {
  final source = sourceContext.getResource(args.first);
  final compilation = bundler.bundle(source: source);
  final result = analyzer.analyzeCompilation(compilation);
  if (result.errors.isNotEmpty) {
    for (final error in result.errors) {
      info(error.toString(),
          color: error.severity >= MessageSeverity.error
              ? ConsoleColor.red
              : ConsoleColor.yellow);
    }
  } else {
    info('Analyzer found 0 problem.', color: ConsoleColor.blue);
  }
}

void compile(List<String> args,
    {String? compileToIntArrayWithName, String? versionString}) {
  if (args.isEmpty) {
    info('Path argument is required for \'compile\' command.',
        color: ConsoleColor.red);
    return;
  }
  Version? version;
  if (versionString != null) {
    version = Version.parse(versionString);
  }
  final source = sourceContext.getResource(args.first);
  info('Compiling [${source.fullName}] ...');
  final module = bundler.bundle(
    source: source,
    version: version,
  );
  if (module.errors.isNotEmpty) {
    for (final error in module.errors) {
      info(error.toString(),
          color: error.severity >= MessageSeverity.error
              ? ConsoleColor.red
              : ConsoleColor.yellow);
    }
    return;
  } else {
    final compileConfig = CompilerConfig(removeLineInfo: false);
    final compiler = HTCompiler(config: compileConfig);
    final bytes = compiler.compile(module);

    final curPath = path.dirname(source.fullName);
    late String outPath;
    if (args.length >= 2) {
      final outArg = args[1];
      if (!path.isAbsolute(outArg)) {
        final joined = path.join(sourceContext.root, outArg);
        outPath = sourceContext.getAbsolutePath(key: joined);
      } else {
        outPath = outArg;
      }
    } else {
      outPath = path.join(
          curPath,
          path.basenameWithoutExtension(source.fullName) +
              (compileToIntArrayWithName != null ? '.dart' : '.out'));
    }

    if (compileToIntArrayWithName != null) {
      final output = StringBuffer();
      output
          .writeln('''/// The pre-compiled binary code of [${source.basename}].
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
      final outFile = File(outPath);
      if (!outFile.existsSync()) {
        info('Path not exist, creating file ...', color: ConsoleColor.yellow);
        outFile.createSync(recursive: true);
      }
      outFile.writeAsStringSync(content);
      stdout.writeln('Saved file to [$outPath]');
    } else {
      final outFile = File(outPath);
      if (!outFile.existsSync()) {
        stdout.write('Path not exist, creating file ...');
        outFile.createSync(recursive: true);
      }
      outFile.writeAsBytesSync(bytes);
      stdout.writeln('saved file to [$outPath]');
    }
  }
}
