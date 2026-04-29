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

  group('while loop -', () {
    test('basic while with counter', () {
      final result = hetu.eval(r'''
        var i = 0
        var sum = 0
        while (i < 5) {
          sum += i
          ++i
        }
        sum
      ''');
      expect(result, 10);
    });

    test('while with break', () {
      final result = hetu.eval(r'''
        var i = 0
        while (true) {
          ++i
          if (i >= 5) {
            break
          }
        }
        i
      ''');
      expect(result, 5);
    });

    test('while with continue', () {
      final result = hetu.eval(r'''
        var i = 0
        var sum = 0
        while (i < 10) {
          ++i
          if (i % 2 == 0) {
            continue
          }
          sum += i
        }
        sum
      ''');
      expect(result, 25);
    });

    test('nested while loops', () {
      final result = hetu.eval(r'''
        var i = 0
        var j = 0
        var sum = 0
        while (i < 3) {
          j = 0
          while (j < 3) {
            sum += i * j
            ++j
          }
          ++i
        }
        sum
      ''');
      expect(result, 9);
    });
  });

  group('do-while loop -', () {
    test('basic do-while', () {
      final result = hetu.eval(r'''
        var i = 0
        var sum = 0
        do {
          sum += i
          ++i
        } while (i < 5)
        sum
      ''');
      expect(result, 10);
    });

    test('do-while runs once even when condition false', () {
      final result = hetu.eval(r'''
        var count = 0
        do {
          count = 1
        } while (false)
        count
      ''');
      expect(result, 1);
    });

    test('do-while with break', () {
      final result = hetu.eval(r'''
        var i = 0
        do {
          ++i
          if (i >= 5) {
            break
          }
        } while (true)
        i
      ''');
      expect(result, 5);
    });

    test('nested do-while and while', () {
      final result = hetu.eval(r'''
        var i = 0
        var sum = 0
        while (i < 3) {
          var j = i
          do {
            sum += j
            ++j
          } while (j < 4)
          ++i
        }
        sum
      ''');
      expect(result, 17);
    });
  });

  group('switch -', () {
    test('switch with typeval pattern matching', () {
      final result = hetu.eval(r'''
        function checkType(t: type) {
          switch (t) {
            typeval ()->any => 'function'
            typeval {} => 'struct'
            else => 'other'
          }
        }
        checkType(typeof {} )
      ''');
      expect(result, 'struct');
    });

    test('switch with comma-separated alternatives', () {
      final result = hetu.eval(r'''
        function test(x) {
          switch (x) {
            1, 2, 3 => 'small'
            4, 5, 6 => 'medium'
            else => 'large'
          }
        }
        test(5)
      ''');
      expect(result, 'medium');
    });

    test('switch with in matching', () {
      final result = hetu.eval(r'''
        function switchInTest(x) {
          switch (x) {
            in [1, 2, 3] => 'found in list'
            else => 'not found'
          }
        }
        switchInTest(2)
      ''');
      expect(result, 'found in list');
    });
  });
}
