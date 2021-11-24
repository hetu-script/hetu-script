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
    fun test {
      var foo = {
        value: 42,
        greeting: 'hi!'
      }
      print(foo.value)
      foo.value = 'ha!'
      print(foo.value)
      foo.world = 'everything'
      print(foo)
      
      class Bar {
        var name = 'barrrrrr!'
      }
      var b = Bar()
      print(b)
    }
  ''');

  hetu.evalSource(source, invokeFunc: 'test');
  // final result = hetu.invoke('namedArgFunTest');
  // print(result);
}
