import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  await hetu.init();

  await hetu.eval(r'''
    var a = 'hello world!'

    print('hi, ${a} ${6 * 7} fizz buzz')

  ''', style: ParseStyle.script);
}
