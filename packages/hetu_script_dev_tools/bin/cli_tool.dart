import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:hetu_script/hetu_script.dart';
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

final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
      removeLineInfo: true,
      // doStaticAnalysis: true,
      // computeConstantExpression: true,
      // showDartStackTrace: true,
      // showHetuStackTrace: true,
      allowImplicitNullToZeroConversion: true,
      allowImplicitEmptyValueToFalseConversion: true,
    ),
    sourceContext: sourceContext);
final sourceContext = HTFileSystemResourceContext();
final analyzer = HTAnalyzer(sourceContext: sourceContext);
final parser = HTParserHetu();
final bundler = HTBundler(sourceContext: sourceContext);

bool showDetailsOfError = false;

void main(List<String> arguments) {
  try {
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
              print(r'''hetu run [path] [option]
Interpret a Hetu script file and print its result to terminal.
''');
            } else {
              run(cmd.rest, enterRepl: cmd['repl']);
            }
            break;
          case 'analyze':
            if (cmd['help']) {
              print(
                  'hetu analyze [path] [option]\nAnalyze a Hetu script file.');
            } else {
              analyze(cmd.rest);
            }
            break;
          case 'format':
            if (cmd['help']) {
              print('hetu format [path] [option]\nFormat a Hetu script file.');
            } else {
              format(cmd.rest, cmd['out']);
            }
            break;
          case 'compile':
            if (cmd['help']) {
              print(
                  'hetu compile [path] [output_path] [option]\nCompile a Hetu script file.');
            } else {
              compile(
                cmd.rest,
                compileToIntArrayWithName: cmd['array'],
                versionString: cmd['version'],
              );
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

void enterReplMode({dynamic prompt}) async {
  hetu.init();
  print(replInfo);
  if (prompt != null) {
    print(hetu.lexicon.stringify(prompt));
  }
  while (true) {
    stdout.write('>>>');
    var input = stdin.readLineSync();
    if (input == '.exit') {
      break;
    } else {
      if (input!.endsWith('\\')) {
        input += '\n${stdin.readLineSync()!}';
      }
      try {
        dynamic result = hetu.eval(input);
        if (result is Future) {
          result = await result;
          print('(Future) ${hetu.lexicon.stringify(result)}');
        } else {
          print(hetu.lexicon.stringify(result));
        }
      } catch (e) {
        if (e is HTError) {
          if (showDetailsOfError) {
            print(e);
          } else {
            print(e.message);
          }
        } else {
          print(e);
        }
        print('');
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
  compileCmd.addOption('array', abbr: 'a', help: 'Compile to dart array.');
  compileCmd.addOption('version',
      abbr: 'v', help: 'Set the version string for this module.');
  return argParser.parse(args);
}

void run(List<String> args, {bool enterRepl = false}) {
  hetu.init();
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
  final prompt =
      'Loaded module: [${args.first}] with execution result:\n${hetu.lexicon.stringify(result)}';
  if (enterRepl) {
    showDetailsOfError = true;
    enterReplMode(prompt: prompt);
  } else {
    print(hetu.lexicon.stringify(result));
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
  stdout.writeln('saved file to [$outPath]');
}

void analyze(List<String> args) {
  final source = sourceContext.getResource(args.first);
  final compilation = bundler.bundle(source: source, parser: parser);
  final result = analyzer.analyzeCompilation(compilation);
  if (result.errors.isNotEmpty) {
    for (final error in result.errors) {
      if (error.severity >= ErrorSeverity.error) {
        print('Error: $error');
      } else {
        print('Warning: $error');
      }
    }
  } else {
    print('Analyzer found 0 problem.');
  }
}

void compile(List<String> args,
    {String? compileToIntArrayWithName, String? versionString}) {
  if (args.isEmpty) {
    throw 'Error: Path argument is required for \'compile\' command.';
  }
  Version? version;
  if (versionString != null) {
    version = Version.parse(versionString);
  }
  final source = sourceContext.getResource(args.first);
  print('Compiling [${source.fullName}] ...');
  final module = bundler.bundle(
    source: source,
    parser: parser,
    version: version,
  );
  if (module.errors.isNotEmpty) {
    for (final err in module.errors) {
      print(err);
    }
    throw 'Syntactic error(s) occurred while parsing.';
  } else {
    final compileConfig = CompilerConfig(removeLineInfo: true);
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
        stdout.write('path not exist, creating file ...');
        outFile.createSync(recursive: true);
      }
      outFile.writeAsStringSync(content);
      stdout.writeln('saved file to [$outPath]');
    } else {
      final outFile = File(outPath);
      if (!outFile.existsSync()) {
        stdout.write('path not exist, creating file ...');
        outFile.createSync(recursive: true);
      }
      outFile.writeAsBytesSync(bytes);
      stdout.writeln('saved file to [$outPath]');
    }
  }
}
