import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('spread - ', () {
    test('spread in struct', () {
      final result = hetu.eval(r'''
        var name = {
          familyName: 'Hord',
          firstName: 'Luk'
        }
        var person = {
          ...name,
          age: 23,
        }
        person.firstName
      ''');
      expect(
        result,
        'Luk',
      );
    });
    test('spread in list', () {
      final result = hetu.eval(r'''
        var list = [5, 6]
        var ht = [1, 2, ...[3, 4], ...list]
        JSON.stringify(ht)
      ''');
      expect(
        result,
        r'''[
  1,
  2,
  3,
  4,
  5,
  6
]''',
      );
    });
    test('spread in function call', () {
      final result = hetu.eval(r'''
        function someFunc(a, b) {
          return a + b
        }
        var list = [5, 6]
        someFunc(...list)
      ''');
      expect(
        result,
        11,
      );
    });
  });

  group('operators -', () {
    test('brackets', () {
      final result = hetu.eval(r'''
        3 - (2 * 3 - 5)
      ''');
      expect(
        result,
        2,
      );
    });
    test('null checker', () {
      final result = hetu.eval(r'''
        var kek = null
        if (kek == null || true) {
          'is null'
        } else {
          'eroor'
        }
      ''');
      expect(
        result,
        'is null',
      );
    });
    test('ternary operator', () {
      final result = hetu.eval(r'''
        (5 > 4 ? true ? 'certainly' : 'yeah' : 'ha') + ', Eva!'
      ''');
      expect(
        result,
        'certainly, Eva!',
      );
    });
    test('member and sub get', () {
      final result = hetu.eval(r'''
        class Ming {
          var first = 'tom'
        }
        class Member {
          var array = {'tom': 'kaine'}
          var name = Ming()
        }
        var m = Member()
        m.array[m.name.first]
      ''');
      expect(
        result,
        'kaine',
      );
    });
    test('complex assign', () {
      final result = hetu.eval(r'''
        var jimmy = {
          age: 17
        }
        jimmy.age -= 5 + 2
        jimmy.age *= 6
        jimmy.age += 3 * 4
      ''');
      expect(
        result,
        72,
      );
    });
  });
}
