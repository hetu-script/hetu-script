import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/parser/token.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';
import 'package:hetu_script_nlp_plugin/zhongwen.dart';

void main() {
  final sourceContext =
      HTFileSystemResourceContext(root: 'lib/zhongwen/test_script/');
  final lexicon = ZhongwenLexicon();
  final lexer = HTDefaultLexer(lexicon: lexicon);
  final source = sourceContext.getResource('中文编程测试');
  Token? token = lexer.lex(source.content);
  do {
    print('lexeme: ${token!.lexeme}, type: ${token.type}');
    token = token.next;
  } while (token != null);
  // var hetu = Hetu();
  // hetu.init(locale: HTLocaleSimplifiedChinese());

  // hetu.evalFile('中文编程：核心');
}
