import 'package:hetu_script/lexer/lexer.dart';
import 'package:hetu_script/grammar/token.dart';

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
  Token? token = lexer.lex(source);
  do {
    print(token?.lexeme);
    token = token?.next;
  } while (token != null);
}
