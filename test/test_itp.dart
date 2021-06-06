import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  final result = await hetu.eval(r'''
    var i = 0
    print(i++)
    print(i)
  ''',
      config: InterpreterConfig(sourceType: SourceType.script),
      invokeFunc: 'main');
  print(result);
}
