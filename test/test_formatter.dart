import 'package:hetu_script/hetu_script.dart';

void main() async {
  final srcPrdr = DefaultSourceProvider();
  final source = HTSource(HTLexicon.anonymousScript, r'''
    var i = 42
    var j = 'hi, your number is ${ '#' + i.toString()   }.'
  ''');
  final parser = HTAstParser();
  // final bundle = await parser.parseFileAsLibrary('script\\battle.ht', srcPrdr);
  final compilation = await parser.parseToCompilation(source, srcPrdr);

  final formatter = HTFormatter();

  formatter.formatLibrary(compilation);

  for (final module in compilation.modules) {
    print('========[${module.fullName}]========');
    print(module.source.content);
    print('================');
  }
}
