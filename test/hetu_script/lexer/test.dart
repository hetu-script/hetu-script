import 'package:hetu_script/lexer/lexer2.dart';

void main() {
  final source = "print('hello, world!')";
  final lexer = HTLexer();
  final tokens = lexer.lex(source);
  for (final token in tokens) {
    print(token.lexeme);
  }
}
