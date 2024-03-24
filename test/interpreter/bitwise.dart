import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('bitwise -', () {
    test('bitwise operators', () {
      final result = hetu.eval(r'''
        let a = 5
        let b = 9

        (a & b) + (a | b) + (a ^ b) + (~a)
      ''');
      expect(
        result,
        20,
      );
    });

    test('shift operators', () {
      final result = hetu.eval(r'''
        let b = 9

        (b << 1) + (b >> 1)
      ''');
      expect(
        result,
        22,
      );
    });
  });
}
