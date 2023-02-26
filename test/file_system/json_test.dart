import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext(root: 'script/');
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
    sourceContext: sourceContext,
  );
  hetu.init();

  group('module -', () {
    test('json test 1', () {
      final result = hetu.evalFile('json.hts');
      expect(
        result,
        1.0,
      );
    });
  });
}
