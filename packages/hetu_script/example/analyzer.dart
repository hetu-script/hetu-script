import 'package:hetu_script/analyzer.dart';

void main() {
  final hetu = HTAnalyzer();
  hetu.init();
  final result = hetu.eval(r'''
    var i = 'Hello, world!'
  ''');
  if (result != null) {
    var hasError = false;
    if (result.syntacticErrors.isNotEmpty) {
      print(
          'Analyzer found ${result.syntacticErrors.length} syntactic errors:');
      for (final err in result.syntacticErrors) {
        print(err);
      }
      hasError = true;
    }
    if (result.analysisWarnings.isNotEmpty) {
      print('Analyzer gives ${result.syntacticErrors.length} static warnings:');
      for (final err in result.analysisWarnings) {
        print(err);
      }
      hasError = true;
    }
    if (!hasError) {
      print('Analyzer found 0 problem.');
    }
  } else {
    print('Unkown error occurred during analysis.');
  }
}
