import 'package:hetu_script/hetu_script.dart';

void main() {
  // final parser = HTAstParser();
  // final nodes = parser.parseString('');
  // print(nodes);

  // final lexer = HTLexer();
  // final tokens = lexer.lex('');
  // print(tokens);

  // final source = HTSource(r'''
  //       enum Race {
  //         caucasian,
  //         mongolian,
  //         african,
  //       }
  //       var race: Race = Race.african
  //       print( race.toString())
  // ''', type: SourceType.script);
  // // final parser = HTAstParser();
  // final module = parser.parseToModule(source);
  // final formatter = HTFormatter();
  // formatter.formatModule(module);
  // print('${module.fullName}');
  // print('--------------------------------------------------------------------');
  // print(module.source.content);

  final hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    // fun namedArgFun(a: num, b: num) {
    fun namedArgFun({a: num, b: num}) {
      return a + b
    }

    fun namedArgFunTest {
      // return namedArgFun(1, 41)
      return namedArgFun(a: 1, b: 41)
    }
  ''');
  final result = hetu.invoke('namedArgFunTest');
  print(result);
  // hetu.evalSource(source);
}
