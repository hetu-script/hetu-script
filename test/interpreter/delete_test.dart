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

  group('delete local variable -', () {
    test('delete top-level variable', () {
      expect(
        () => hetu.eval(r'''
          var a = 42
          delete a
          a
        '''),
        throwsA(isA<HTError>()),
      );
    });

    test('delete variable in function scope', () {
      expect(
        () => hetu.eval(r'''
          function test() {
            var local = 'hello'
            delete local
            local
          }
          test()
        '''),
        throwsA(isA<HTError>()),
      );
    });
  });

  group('delete struct member -', () {
    test('delete struct field via member access', () {
      final result = hetu.eval(r'''
        var obj = { name: 'the world', meaning: 42 }
        delete obj.meaning
        obj.toString()
      ''');
      expect(result, '''{\n  name: 'the world'\n}''');
    });

    test('delete non-existent struct member', () {
      final result = hetu.eval(r'''
        var obj = { name: 'test' }
        delete obj.nonExistent
        obj.toString()
      ''');
      expect(result, '''{\n  name: 'test'\n}''');
    });
  });

  group('delete subscript -', () {
    test('delete map entry by key', () {
      final result = hetu.eval(r'''
        var map = Map()
        map['a'] = 1
        map['b'] = 2
        delete map['a']
        map.toString()
      ''');
      expect(result, '{b: 2}');
    });

    test('delete struct field by subscript key', () {
      final result = hetu.eval(r'''
        var obj = { name: 'the world', meaning: 42 }
        delete obj['meaning']
        obj.toString()
      ''');
      expect(result, '''{\n  name: 'the world'\n}''');
    });
  });
}
