import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/analyzer.dart';

void main() {
  final analyzer = HTAnalyzer();
  final parser = HTBundler();
  final source = HTSource(r'''
    var i = 'Hello, world!'
  ''', type: HTResourceType.hetuLiteralCode);
  final compilation = parser.bundle(source);
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
