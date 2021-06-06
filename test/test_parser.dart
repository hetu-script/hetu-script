import 'package:hetu_script/ast/parser.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final srcPrdr = DefaultSourceProvider();
  final parser = HTAstParser();
  final bundle = await parser.parseFile('script\\battle.ht', srcPrdr);

  final formatter = HTFormatter();

  await formatter.formatAll(bundle);

  for (final module in bundle.modules) {
    print('========[${module.fullName}]========');
    print(module.content);
    print('================');
  }
}
