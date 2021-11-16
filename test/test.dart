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
    fun fa({a, b}){
      return a + b
    }

    fun fb({a:fun()->any}){
      return a()
    }

    fun fc({a:fun()->any, b:fun()->int}){
      return a() + b()
    }

    fun cc(){
      return 2
    }

    fun test(){
      print(fa(a:1, b:2))

      print(fb(a:fun()=>2))

      print(fc(a:cc, b:fun()=>3))
    }
  ''');

  hetu.evalSource(source, invokeFunc: 'test');
  // final result = hetu.invoke('namedArgFunTest');
  // print(result);
}
