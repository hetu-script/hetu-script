import 'package:hetu_script/hetu_script.dart';

void main() {
  final source = HTSource(r'''
    var i = 42
    var j = 'hi, your number is ${ '#' +     i.toString()   }.'
  ''');
  final parser = HTAstParser();
  final module = parser.parseToModule(source);
  final formatter = HTFormatter();
  formatter.formatModule(module);
  print('${module.fullName}');
  print('--------------------------------------------------------------------');
  print(module.source.content);
  print('--------------------------------------------------------------------');
}
