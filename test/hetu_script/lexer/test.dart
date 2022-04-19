import 'package:hetu_script/lexer/lexer.dart';
import 'package:hetu_script/parser/token.dart';

void main() {
  final source = r'''
    1
    +
    2

    3
''';
  final lexer = HTLexer();
  Token? token = lexer.lex(source);
  do {
    print(token?.lexeme);
    token = token?.next;
  } while (token != null);
}
