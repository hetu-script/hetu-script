import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTVM();

  await hetu.eval(r'''
  true && false
  ''', style: ParseStyle.function);
}
