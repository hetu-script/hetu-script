import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script/');
  final hetu = Hetu(
      config: HetuConfig(
        printPerformanceStatistics: false,
        doStaticAnalysis: true,
        computeConstantExpression: true,
      ),
      sourceContext: sourceContext);
  // hetu.init();
  final source = HTSource(r'''
    const a = b
    const b = 42 * 2
    a
''');
  // final compilation = hetu.bundle(source);
  final bytes = hetu.compile(source.content, isModuleEntryScript: true);
  print(bytes);
  final r = hetu.loadBytecode(bytes: bytes, module: 'test');
  print(r);
  // hetu.eval(source.content);
}
