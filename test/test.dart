import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      // var l = List()
      // l.add(4)
      // l.add(3)

      // print(l)
      var i = 42
      print(i.toString())
    ''', codeType: CodeType.script);
}
