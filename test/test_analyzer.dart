import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu =
      HTAnalyzer(config: AnalyzerConfig(sourceType: SourceType.script));
  hetu.init();
  final result = hetu.eval(r'''
    import 'nofile.ht'
    var %i = 'hey! ${}'
  ''');
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
