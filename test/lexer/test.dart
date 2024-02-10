import 'package:hetu_script/parser.dart';

void main() {
  final source = r'''
    1
    +
    2

    3
''';
  final lexer = HTLexerHetu();
  Token? token = lexer.lex(source);
  do {
    print(token?.lexeme);
    token = token?.next;
  } while (token != null);
}
