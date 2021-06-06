import 'package:test/test.dart';
import 'package:hetu_script/utils/crc32b.dart';

void main() async {
  group('utilities -', () {
    test('crc32b compute', () {
      final data = 'hello, world!';
      final result = Crc32b.compute(data);
      expect(
        result,
        '58988d13',
      );
    });
  });
}
