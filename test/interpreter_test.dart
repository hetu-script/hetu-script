import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/src/lexer.dart';

void main() async {
  var itp = await Hetu.init();
  group('lexer test -', () {
    test('lexer', () async {
      final lexer = Lexer(itp, '''
                // this is a comment
                var _Words: String = "hello world"
                let n_42 = 42
                void main() {
                print(_Words);
                }
                ''');
      expect(
        lexer.tokens.toString(),
        '[var, _Words, :, String, =, "hello world", let, n_42, =, 42, void, main, (, ), {, print, (, _Words, ), ;, }]',
      );
    });
  });
  group('interpreter error handling test -', () {
    test('const definition', () async {
      expect(
        () {
          itp.eval('''
              let i = 42
              i = 137
              ''', style: ParseStyle.function);
        },
        throwsA(isA<HTErr_Mutable>()),
      );
    });
  });
}
