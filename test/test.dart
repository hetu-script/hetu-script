import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu =
      HTAnalyzer(config: AnalyzerConfig(sourceType: SourceType.module));
  hetu.init();
  hetu.eval(r'''fun main { print('hello world! ${}') }
  ''');
  if (hetu.errors.isNotEmpty) {
    print('Analyzer found ${hetu.errors.length} problems:');
    for (final err in hetu.errors) {
      print(err);
    }
  } else {
    print('Analyzer found 0 problem.');
  }
}
