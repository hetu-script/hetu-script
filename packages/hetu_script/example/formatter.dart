import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/analyzer.dart';
import 'package:hetu_script/parser.dart';

void main() {
  final source = HTSource(r'''
    var i = 42
    var j = 'hi, your number is ${ '#' +     i.toString()   }.'
  ''');
  final parser = HTParser();
  final module = parser.parseToModule(source);
  final formatter = HTFormatter();
  formatter.formatModule(module);
  print(module.fullName);
  print('--------------------------------------------------------------------');
  print(module.source.content);
  print('--------------------------------------------------------------------');
}
