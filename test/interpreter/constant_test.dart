import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      printPerformanceStatistics: false,
      processError: true,
    ),
  );
  hetu.init();

  group('const -', () {
    test('const integer', () {
      final result = hetu.eval(r'''
        const answer = 42
        answer
      ''');
      expect(result, 42);
    });

    test('const float', () {
      final result = hetu.eval(r'''
        const pi = 3.14159
        pi
      ''');
      expect(result, 3.14159);
    });

    test('const string', () {
      final result = hetu.eval(r'''
        const greeting = 'Hello, Hetu!'
        greeting
      ''');
      expect(result, 'Hello, Hetu!');
    });

    test('const boolean true', () {
      final result = hetu.eval(r'''
        const isReady = true
        isReady
      ''');
      expect(result, true);
    });

    test('const boolean false', () {
      final result = hetu.eval(r'''
        const isDone = false
        isDone
      ''');
      expect(result, false);
    });

    test('const immutability - reassign throws', () {
      expect(
        () => hetu.eval(r'''
          const answer = 42
          answer = 100
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('multiple const int same value share storage', () {
      final result = hetu.eval(r'''
        const a = 42
        const b = 42
        a == b
      ''');
      expect(result, true);
    });
  });
}
