import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTInterpreter();

  group('interpreter error handling test -', () {
    test('const definition', () async {
      expect(
        () async {
          await hetu.eval('''
              let i = 42
              i = 137
              ''', style: ParseStyle.function);
        },
        throwsA(isA<HTErrorImmutable>()),
      );
    });
  });
}
