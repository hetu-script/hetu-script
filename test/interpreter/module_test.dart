import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('edge cases -', () {
    test('import 1', () async {
      final result = await hetu.evalFile('script/import_test.ht',
          invokeFunc: 'importTest');
      expect(
        result,
        87.5,
      );
    });
    test('import 2', () async {
      final result =
          await hetu.evalFile('script/import_test2.ht', invokeFunc: 'main');
      expect(
        result,
        'Hello, world!',
      );
    });
  });
}
