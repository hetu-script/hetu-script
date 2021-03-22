import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = HTVM();

  // await hetu.init();

  await hetu.eval(r'''
  fun hello {
    return 1 + 2
  }

  hello()
  ''', style: ParseStyle.function);
}
