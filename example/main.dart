import 'package:hetu_script/hetu.dart';

void main() {
  Hetu.init();
  Hetu.evalf('script\\test.hs', invokeFunc: 'main');
  //hetu.eval('println \'hello!\'', conlexeme: ParserConlexeme.commandLineInterface);
}
