import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  group('struct -', () {
    test('basics', () {
      final result = hetu.eval(r'''
        fun structBasicTest {
          var foo = {
            value: 42,
            greeting: 'hi!'
          }
          foo.value = 'ha!'
          foo.world = 'everything'
          return foo.toString()
        }
      ''', invokeFunc: 'structBasicTest');
      expect(
        result,
        r'''{
  value: 'ha!',
  greeting: 'hi!',
  world: 'everything'
}''',
      );
    });
    test('fromJson', () {
      final jsonData = {
        "name": "Aleph",
        "type": "novel",
        "volumes": 7,
      };
      final result = hetu.eval(
          r'''
        fun fromJsonTest(data) {
          final obj = prototype.fromJson(data)
          return obj.volumes
        }
      ''',
          invokeFunc: 'fromJsonTest',
          positionalArgs: [jsonData]);
      expect(
        result,
        7,
      );
    });
    test('owns', () {
      final result = hetu.eval(r'''
        fun ownsTest {
          var ht = {
            name: 'Hetu',
            age: 1
          }
          return ht.owns('toJson') // false
        }
      ''', invokeFunc: 'ownsTest');
      expect(
        result,
        false,
      );
    });
    test('named', () {
      final result = hetu.eval(r'''
        fun namedStructTest {
          struct Named {
            var name = 'Unity'
            var age = 17
          }
          final n = Named()
          n.age = 42
          return Named.age
        }
      ''', invokeFunc: 'namedStructTest');
      expect(
        result,
        17,
      );
    });
  });
}
