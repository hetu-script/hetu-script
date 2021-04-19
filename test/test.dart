import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    var list = [1,2,3,4]
    var item = list[3]
    list.removeLast()
    print(item)
    ''', codeType: CodeType.script);
}
