import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    print('hi' + 2)
  ''', config: ParserConfig(codeType: CodeType.script));
}
