import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  await hetu.init();
  final result = await hetu.eval(r'''
    var i = 0
    var list = [1,2,3]
    print(list[0]--)
    print(list)
  ''', invokeFunc: 'main');
  print(result);
}
