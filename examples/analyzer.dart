import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/analyzer.dart';

void main() {
  final analyzer = HTAnalyzer();
  final bundler = HTBundler(sourceContext: HTOverlayContext());
  final parser = HTParserHetu();
  final source = HTSource(r'''
    i = 'Hello, world!'
  ''', type: HTResourceType.hetuLiteralCode);
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
