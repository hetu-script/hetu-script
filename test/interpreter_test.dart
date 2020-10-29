import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/src/lexer.dart';

void main() async {
  group('lexer test -', () {
    test('lexer', () async {
      final lexer = Lexer();
      expect(
        lexer
            .lex('// this is a comment\n'
                'var _Words: String = "hello world"\n'
                'let n_42 = 42\n'
                'void main() {\n'
                'print(_Words);\n'
                '}')
            .toString(),
        '[var, _Words, :, String, =, "hello world", let, n_42, =, 42, void, main, (, ), {, print, (, _Words, ), ;, }]',
      );
    });
  });
  group('interpreter error handling test -', () {
    test('const definition', () async {
      var itp = await Hetu.init();
      expect(
        () {
          itp.eval(
              'let i = 42\n'
              'i = 137',
              style: ParseStyle.function);
        },
        throwsA(isA<HTErr_Mutable>()),
      );
    });
  });
}
