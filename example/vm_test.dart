import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = HTVM();

  // await hetu.init();

  await hetu.eval(r'''
  fun hello (a, b) {
    return a * b + a * b
  }

  hello(6, 7)
  ''', style: ParseStyle.function);
}
