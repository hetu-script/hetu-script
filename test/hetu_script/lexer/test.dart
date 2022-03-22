import 'package:hetu_script/lexer/lexer.dart';

void main() {
  final source = r'''
// 程序入口
fun main {
  var i = 0
  while (true) {
    i = i + 1
    if (i == 10) {
      break
    } else if (i % 2 == 0) {
      print(i)
    } else {
      continue
    }
  }

  var list = ['jimmy', 'tommy', 'larry', 'perry']
  for (var item in list) {
    print(item)
  }
}
''';
  final lexer = HTLexer();
  final tokens = lexer.lex(source);
  for (final token in tokens) {
    print(token.lexeme);
  }
}
