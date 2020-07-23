import 'package:test/test.dart';
import 'package:hetu_script/hetu.dart';
import 'package:hetu_script/src/lexer.dart';

void main() {
  //var hetu = Hetu();
  var lexer = Lexer();
  group('Hetu test', () {
    test('consoleLog', () {
      expect(
        lexer.lex("void main() {\nprint('Hello, World!');\n}").toString(),
        "[void, main, (, ), {, print, (, 'Hello, World!', ), ;, }]",
      );
    });
  });
}
