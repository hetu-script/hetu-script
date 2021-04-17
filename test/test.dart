import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      print((3).toStringAsExponential())

      print([1,3,565].runtimeType)
    ''', codeType: CodeType.script);
}
