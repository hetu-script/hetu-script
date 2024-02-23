import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/analyzer.dart';

void main() {
  final analyzer = HTAnalyzer();
  final parser = HTParserHetu();
  final bundler = HTBundler(
    sourceContext: HTOverlayContext(),
    parser: parser,
  );
  final source = HTSource(r'''
    i = 'Hello, world!'
  ''', type: HTResourceType.hetuLiteralCode);
  final compilation = bundler.bundle(source: source);
  final result = analyzer.analyzeCompilation(compilation);
  if (result.errors.isNotEmpty) {
    for (final error in result.errors) {
      if (error.severity >= MessageSeverity.error) {
        print('Error: $error');
      } else {
        print('Warning: $error');
      }
    }
  } else {
    print('Analyzer found 0 problem.');
  }
}
