import 'package:hetu_script/hetu_script.dart';

import 'package:hetu_script/src/lexer.dart';
import 'package:hetu_script/src/vm/compiler.dart';

void main() async {
  final hetu = Hetu();

  // await hetu.init();

  final tokens = Lexer().lex(r'''
  var i = 0
  // ''', 'test');
  final bytes = await Compiler().compile(tokens, hetu, 'test', codeType: CodeType.block);

  print(bytes);

  // await hetu.eval(r'''

  // ''', codeType: ParseStyle.module);
}
