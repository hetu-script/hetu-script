import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('buildin values -', () {
    test('escape char in string', () {
      final result = hetu.eval(r'''
        'Alice\'s world.'
      ''');
      expect(
        result,
        "Alice's world.",
      );
    });

    test('multiline string', () {
      final result = hetu.eval(r'''
    var p = 'PPP'
    var m = 'MMM'
    final s = '
${
      p
      +
      m
    }'
    s
      ''');
      expect(
        result,
        "\nPPPMMM",
      );
    });
    test('string interpolation', () {
      final result = hetu.eval(r'''
        var a = 'dragon'
        var b
        'To kill the ${a}, you have to wait ${b} years.'
      ''');
      expect(
        result,
        'To kill the dragon, you have to wait null years.',
      );
    });
  });

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
        stringify(ht)
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
        jimmy.age -= 10
        jimmy.age *= 6
        jimmy.age
      ''');
      expect(
        result,
        42,
      );
    });
  });

  group('control flow -', () {
    test('loop', () {
      final result = hetu.eval(r'''
        var j = 1
        var i = 0
        for (;;) {
          ++i
          switch (i % 2) {
            0 => j += i
            1 => j *= i
          }
          if (i > 5) {
            break
          }
        }
        j
      ''');
      expect(
        result,
        71,
      );
    });
    test('for in', () {
      final result = hetu.eval(r'''
        var value = ['', 'hello', 'world']
        var result = ''
        for (var item in value) {
          if (item != '') {
            result = item
            break
          }
        }
        result
      ''');
      expect(
        result,
        'hello',
      );
    });
    test('continue', () {
      final result = hetu.eval(r'''
        var j = 0
        for (var i = 0; i < 5; ++i) {
          if (i % 2 == 0){
            continue
          }
          j += i
        }
        j
      ''');
      expect(
        result,
        4,
      );
    });
    test('switch', () {
      final result = hetu.eval(r'''
        function switchTest(expr) {
          switch (expr) {
            0 => return '0'
            1 => return '1'
          }
          return ''
        }
        switchTest(5 - 4)
      ''');
      expect(
        result,
        '1',
      );
    });
  });

  group('variables -', () {
    test('global var', () {
      final result = hetu.eval(r'''
        var globalVar = 0
        class GetGlobal {
          constructor {
            globalVar = 2
          }
          function test {
            return (globalVar * globalVar)
          }
          static function staticTest {
            return (globalVar + 1)
          }
        }
        var a = GetGlobal()
        a.test() + GetGlobal.staticTest()
      ''');
      expect(
        result,
        7,
      );
    });
    test('delete', () {
      final result = hetu.eval(r'''
        var a = {
          age: 17,
          meaning: 42
        }
        delete a['meaning']
        a.toString()
      ''');
      expect(
        result,
        '''{
  age: 17
}''',
      );
    });
    test('set', () {
      final result = hetu.eval(r'''
        final list = [1, 2, 1, 3, 2, 5, 1]
        final s = Set(...list)
        s.add(7)
        s.toString()
      ''');
      expect(
        result,
        '{1, 2, 3, 5, 7}',
      );
    });
    test('map', () {
      final result = hetu.eval(r'''
        final m = Map()
        m[1] = 2
        m.toString()
      ''');
      expect(
        result,
        '''{1: 2}''',
      );
    });

    test('destructuring', () {
      final result = hetu.eval(r'''
        final obj = {
          a: 6,
          b: 7,
        }
        final { a, b } = obj
        final list = [1, 2, 3]
        final [ x, y, z ] = list
        a * z
      ''');
      expect(
        result,
        18,
      );
    });
  });
}
