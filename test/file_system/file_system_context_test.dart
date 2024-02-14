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
    test('import test 1', () {
      final result = hetu.evalFile('import_test.ht', invoke: 'importTest');
      expect(
        result,
        87.5,
      );
    });
    test('import test 2', () {
      final result = hetu.evalFile('import_test2.ht', invoke: 'main');
      expect(
        result,
        'another hello!',
      );
    });
    test('recursive import', () {
      final result = hetu.evalFile('recursive2.ht', invoke: 'main');
      expect(
        result,
        'hello, r2, I\'m r1!',
      );
    });
    test('const import', () {
      hetu.evalFile('import_test4.hts');
      // expect(
      //   result,
      //   'hello, r2, I\'m r1!',
      // );
    });
  });
}
