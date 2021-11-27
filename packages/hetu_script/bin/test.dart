import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  final source = HTSource(r'''
    fun test {
      var jimmy = {
        name: 'jimmy',
        age: 17
      }
      var team = {
        number: 1
      }
      team.leader = jimmy
      // print(team.toString())

      print(team)
      
      // jimmy.doubleIt = (x) { return x * 2 }
      // print(jimmy.doubleIt(42))
    }
  ''');

  hetu.evalSource(source, invokeFunc: 'test');
  // final result = hetu.invoke('namedArgFunTest');
  // print(result);

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
}
