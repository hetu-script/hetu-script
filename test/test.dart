import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      print('24334'.indexOf('4'))
    ''', codeType: CodeType.script);
}
