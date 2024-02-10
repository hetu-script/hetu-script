import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('struct -', () {
    test('basics', () {
      final result = hetu.eval(r'''
        var foo = {
          value: 42,
          greeting: 'hi!'
        }
        foo.value = 'ha!'
        foo.world = 'everything'
        foo.toString()
      ''');
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
            function fromJsonTest(data) {
              final obj = Prototype.fromJson(data)
              return obj.volumes
            }
          ''',
          invoke: 'fromJsonTest',
          positionalArgs: [jsonData]);
      expect(
        result,
        7,
      );
    });
    test('containsKey', () {
      final result = hetu.eval(r'''
        var ht = {
          name: 'Hetu',
          age: 1
        }
        ht.containsKey('toJson') // false
      ''');
      expect(
        result,
        false,
      );
    });
    test('named', () {
      final result = hetu.eval(r'''
        struct Named {
          var name = 'Unity'
          var age = 17
        }
        final n = Named()
        n.age = 42
        Named.age
      ''');
      expect(
        result,
        17,
      );
    });

    test('named constructor', () {
      final result = hetu.eval(r'''
        struct DialogContentData {
          constructor ({
            localeKeys,
          }) {
            this.localeKeys = localeKeys
          }

          constructor fromData(data) : this(
            localeKeys: data.localeKeys,
          ) {}
        }

        final dlg = DialogContentData.fromData({
          localeKeys: ['a', 'b']
        })

        dlg.localeKeys
      ''');
      expect(result, ['a', 'b']);
    });
  });
}
