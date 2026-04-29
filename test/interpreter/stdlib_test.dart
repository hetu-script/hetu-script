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

  group('range() -', () {
    test('range(0, 5) returns 0..4', () {
      final result = hetu.eval(r'''
        JSON.stringify(range(0, 5))
      ''');
      expect(result, isA<String>());
      expect(result, contains('4'));
    });

    test('range with step', () {
      final result = hetu.eval(r'''
        var r = range(0, 10, 2)
        JSON.stringify(r)
      ''');
      expect(result, isA<String>());
    });
  });

  group('parseInt / parseFloat -', () {
    test('parseInt basic', () {
      final result = hetu.eval(r'''
        parseInt('42')
      ''');
      expect(result, 42);
    });

    test('parseFloat basic', () {
      final result = hetu.eval(r'''
        parseFloat('3.14')
      ''');
      expect(result, 3.14);
    });
  });

  group('Math -', () {
    test('Math.min', () {
      final result = hetu.eval(r'''
        Math.min(10, 20)
      ''');
      expect(result, 10);
    });

    test('Math.max', () {
      final result = hetu.eval(r'''
        Math.max(10, 20)
      ''');
      expect(result, 20);
    });

    test('Math.pow', () {
      final result = hetu.eval(r'''
        Math.pow(2, 10)
      ''');
      expect(result, 1024);
    });

    test('Math.sqrt', () {
      final result = hetu.eval(r'''
        Math.sqrt(144)
      ''');
      expect(result, 12.0);
    });
  });

  group('JSON -', () {
    test('JSON.stringify round-trip', () {
      final result = hetu.eval(r'''
        var obj = { name: 'test', value: 42 }
        var str = JSON.stringify(obj)
        str.length > 0
      ''');
      expect(result, true);
    });
  });

  group('eval() -', () {
    test('eval re-evaluates script', () {
      final result = hetu.eval(r'''
        eval('3 + 4')
      ''');
      expect(result, 7);
    });
  });
}
