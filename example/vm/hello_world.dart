import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTVM(debugMode: true);

  await hetu.eval(r'''
  1 + 2
  ''', style: ParseStyle.function);
}
