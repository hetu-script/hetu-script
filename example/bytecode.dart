import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  // await hetu.init();

  final tokens = Lexer().lex(r'''
  var i = 0
  // ''', 'test');
  final bytes = await Compiler().compile(tokens, hetu, 'test', ParseStyle.block);

  print(bytes);

  // await hetu.eval(r'''

  // ''', style: ParseStyle.module);
}
