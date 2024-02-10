import 'package:hetu_script/hetu_script.dart';

void main() {
  final config = HetuConfig(
    allowImplicitVariableDeclaration: true,
  );
  final lexicon = HTLexiconHetu();
  final parser = HTParserHetu(config: config);
  final hetu = Hetu(
    config: config,
    lexicon: lexicon,
    parser: parser,
  );
  hetu.init();

  hetu.eval('''
    print('hello world')
''');
}
