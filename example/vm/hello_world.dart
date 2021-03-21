import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTVM();

  // await hetu.init();

  await hetu.eval(r'''
  var i = (4 + 2) * (15 - 8)
  var j = [3, 5, 'world!']
  var map = { "hi": "jack"}
  ''', style: ParseStyle.function);
}
