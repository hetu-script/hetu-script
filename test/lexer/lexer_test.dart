import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('buildin values -', () {
    test('short float', () {
      final result = hetu.eval(r'''
        -.4
        ''');
      expect(
        result,
        -.4,
      );
    });
    test('hex number literal', () {
      final result = hetu.eval(r'''
        -0xFF
        ''');
      expect(
        result,
        -255,
      );
    });
    test('short float method', () {
      final result = hetu.eval(r'''
        -.4.toString()
        ''');
      expect(
        result,
        '-0.4',
      );
    });
  });
}
