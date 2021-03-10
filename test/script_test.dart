import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  group('script test -', () {
    test('basic function', () async {
      var hetu = await Hetu.create();
      var functions_result = await hetu.evalf('script/functions.ht', invokeFunc: 'main');
      expect(
        functions_result,
        14,
      );
    });
  });
}
