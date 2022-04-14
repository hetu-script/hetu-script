import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script/');
  final hetu = Hetu(
      config: HetuConfig(
        doStaticAnalysis: true,
        computeConstantExpression: true,
      ),
      sourceContext: sourceContext);
  hetu.init();
  final source = HTSource(r'''
    fun test {
      const a = b
      var b = 23
    }
''');
  final compilation = hetu.bundle(source);
  final analysisResult = hetu.analyzer.analyzeCompilation(compilation);
  if (analysisResult.errors.isNotEmpty) {
    for (final error in analysisResult.errors) {
      if (error.severity >= ErrorSeverity.error) {
        print('Error: $error');
      } else {
        print('Warning: $error');
      }
    }
  } else {
    print('Analyzer found 0 problem.');
  }

  // hetu.eval(source.content);
}
