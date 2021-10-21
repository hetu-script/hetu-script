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

  final source = HTSource(r'''
    class Person {
      static var race = 'Human'

      var name = 'Jimmy'

    }

    fun classTest {

      print(Person.name)
    }
  ''');

  hetu.evalSource(source, invokeFunc: 'classTest');
  // final result = hetu.invoke('namedArgFunTest');
  // print(result);
}
