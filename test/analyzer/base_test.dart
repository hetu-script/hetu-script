import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = HTAnalyzer();
  await hetu.init();

  group('expression -', () {
    test('string', () async {
      final result = await hetu.eval(r'''
      fun evalExpr {
        return 'hello world';
      }
    ''', invokeFunc: 'evalExpr');
      expect(
        result,
        'hello world',
      );
    });
  });
}
