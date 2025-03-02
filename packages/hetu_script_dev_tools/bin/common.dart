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

final sourceContext = HTFileSystemResourceContext();
final lexicon = HTLexiconHetu();
final analyzer = HTAnalyzer(sourceContext: sourceContext, lexicon: lexicon);
final parser = HTParserHetu(lexicon: lexicon);
final bundler = HTBundler(sourceContext: sourceContext, parser: parser);
final hetu = Hetu(
  config: HetuConfig(
    // printPerformanceStatistics: false,
    // doStaticAnalysis: true,
    // computeConstantExpression: true,
    // showDartStackTrace: true,
    // showHetuStackTrace: true,
    allowImplicitNullToZeroConversion: true,
    allowImplicitEmptyValueToFalseConversion: true,
  ),
  sourceContext: sourceContext,
  lexicon: lexicon,
  parser: parser,
);

bool showDetailsOfError = false;

final formatter = HTFormatter();
final fileSystemResourceContext = HTFileSystemResourceContext();
