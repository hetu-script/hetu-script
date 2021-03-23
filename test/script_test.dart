import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTAstInterpreter();
  group('script test -', () {
    test('basic function', () async {
      var functions_result = await hetu.import('script/functions.ht', invokeFunc: 'main');
      expect(
        functions_result,
        14,
      );
    });
  });
}
