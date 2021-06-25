import 'package:hetu_script/hetu_script.dart';

void main() async {
  final source = HTSource(SemanticNames.anonymousScript, r'''
    var i = 42
    var j = 'hi, your number is ${ '#' +     i.toString()   }.'
  ''');
  final parser = HTAstParser();
  final module = parser.parseToModule(source);
  final formatter = HTFormatter();
  formatter.formatModule(module);
  print('========[${module.fullName}]========');
  print(module.source.content);
  print('==================================');
}
