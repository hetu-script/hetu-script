import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  await hetu.init();

  await hetu.eval(r'''
var a = 'dragon'

print('To kill the ${a}, you have to wait ${6*7} years.')

  ''', codeType: CodeType.script);
}
