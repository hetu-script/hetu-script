import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  final result = await hetu.eval(r'''
  var a  =4 
  a
      ''', codeType: CodeType.script);

  print(result);
}
