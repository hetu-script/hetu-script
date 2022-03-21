import 'package:hetu_script/lexer/lexer2.dart';

void main() {
  final source = r'''
// 程序入口
var list = ['jimmy', "tommy, ${a + b}", 42, 198.7]
''';
  final lexer = HTLexer();
  final tokens = lexer.lex(source);
  for (final token in tokens) {
    print(token.lexeme);
  }
}
