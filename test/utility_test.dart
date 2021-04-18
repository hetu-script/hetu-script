import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('utilities -', () {
    test('json conversion', () async {
      final result = await hetu.eval('''
        class SomePerson {
          var age = 17
          var name = 'Jimmy'
          var klass = 'farmer'
        }
        fun JsonTest {
          var p = SomePerson.fromJson({'age': 8, 'name': 'Lawrence', 'klass': 'magician'})
          return p.toJson().toString()
        }
      ''', invokeFunc: 'JsonTest');
      expect(
        result,
        '{age: 8, name: Lawrence, klass: magician}',
      );
    });
  });
}
