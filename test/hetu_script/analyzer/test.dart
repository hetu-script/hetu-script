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
  // final source = HTSource(r'''
  //   var i = 42 * j
  //   var j = 3
  // ''', type: HTResourceType.hetuLiteralCode);

  // final compilation = hetu.bundler.bundle(source: source, parser: hetu.parser);
  // final result = hetu.analyzer.analyzeCompilation(compilation);
  // if (result.errors.isNotEmpty) {
  //   for (final error in result.errors) {
  //     if (error.severity >= ErrorSeverity.error) {
  //       print('Error: $error');
  //     } else {
  //       print('Warning: $error');
  //     }
  //   }
  // } else {
  //   print('Analyzer found 0 problem.');
  // }

  hetu.eval(r'''
      var i = 42 * j
      var j = 3
      fun main {
        print(i)
      }
  ''', type: HTResourceType.hetuModule, invokeFunc: 'main');
}
