import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();

  group('interpreter error handling test -', () {
    test('const definition', () async {
      expect(
        () async {
          await hetu.eval('''
              const i = 42
              i = 137
              ''', codeType: CodeType.block);
        },
        throwsA(isA<HTErrorImmutable>()),
      );
    });
  });
}
