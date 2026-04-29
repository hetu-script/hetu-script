import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('number literals -', () {
    test('short float', () {
      final result = hetu.eval(r''' -.4 ''');
      expect(result, -.4);
    });
    test('hex number literal', () {
      final result = hetu.eval(r''' -0xFF ''');
      expect(result, -255);
    });
    test('decimal integer', () {
      final result = hetu.eval(r''' 42 ''');
      expect(result, 42);
    });
    test('float with leading zero', () {
      final result = hetu.eval(r''' 0.5 ''');
      expect(result, 0.5);
    });
  });

  group('string literals -', () {
    test('escape sequences', () {
      final result = hetu.eval(r''' 'line1\nline2\tend' ''');
      expect(result, 'line1\nline2\tend');
    });
    test('string with quotes', () {
      final result = hetu.eval(r""" 'it\'s fine' """);
      expect(result, "it's fine");
    });
    test('multiline string', () {
      final result = hetu.eval(r'''
        var s = 'first line
second line'
        s
      ''');
      expect(result.contains('first'), isTrue);
    });
  });

  group('comments -', () {
    test('single line comment ignored', () {
      final result = hetu.eval(r'''
        // this is a comment
        var a = 42 // trailing comment
        a
      ''');
      expect(result, 42);
    });
    test('documentation comment ignored', () {
      final result = hetu.eval(r'''
        /// This is a doc comment
        100
      ''');
      expect(result, 100);
    });
  });

  group('identifier -', () {
    test('backtick identifier', () {
      final result = hetu.eval(r'''
        var `weird name` = 'hello'
        `weird name`
      ''');
      expect(result, 'hello');
    });
    test('private identifier with underscore', () {
      final result = hetu.eval(r'''
        var _private = 'secret'
        _private
      ''');
      expect(result, 'secret');
    });
  });
}
