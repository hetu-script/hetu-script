import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  group('parser -', () {
    test('parse struct literal with comments', () {
      final code = r'''
        {
          // names: {},
          entities: {
            // nested
          }
        }
      ''';
      final source = HTSource(code, type: HTResourceType.hetuScript);
      final parser = HTParserHetu();
      final result = parser.parseSource(source);
      expect(result.errors, isEmpty);
      expect(result.nodes, isNotEmpty);
    });

    test('parse variable declaration', () {
      final code = r''' var x = 42 ''';
      final source = HTSource(code, type: HTResourceType.hetuScript);
      final parser = HTParserHetu();
      final result = parser.parseSource(source);
      expect(result.errors, isEmpty);
    });

    test('parse function declaration', () {
      final code = r'''
        function add(a, b) {
          return a + b
        }
      ''';
      final source = HTSource(code, type: HTResourceType.hetuScript);
      final parser = HTParserHetu();
      final result = parser.parseSource(source);
      expect(result.errors, isEmpty);
    });

    test('parse class declaration', () {
      final code = r'''
        class Person {
          var name: string
          constructor (name: string) {
            this.name = name
          }
        }
      ''';
      final source = HTSource(code, type: HTResourceType.hetuScript);
      final parser = HTParserHetu();
      final result = parser.parseSource(source);
      expect(result.errors, isEmpty);
    });

    test('parse syntax error produces errors', () {
      final code = r''' var x: ''';
      final source = HTSource(code, type: HTResourceType.hetuScript);
      final parser = HTParserHetu();
      final result = parser.parseSource(source);
      expect(result.errors, isNotEmpty);
    });
  });
}
