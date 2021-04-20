import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
  var j = 'jimmy'
    print('${j}')
    ''', codeType: CodeType.script);
}
