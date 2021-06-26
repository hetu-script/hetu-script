import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  group('module -', () {
    test('import 1', () {
      final result =
          hetu.evalFile('script/import_test.ht', invokeFunc: 'importTest');
      expect(
        result,
        87.5,
      );
    });
    test('import 2', () {
      final result =
          hetu.evalFile('script/import_test2.ht', invokeFunc: 'main');
      expect(
        result,
        'Hello, world!',
      );
    });
  });
}
