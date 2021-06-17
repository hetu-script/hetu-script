import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  await hetu.init();
  await hetu.eval(r'''
    type MyFuncType = fun (num, num) -> num
    var func: MyFuncType = fun add(a: num, b: num) -> num = a + b
    print(func(6, 7))

  ''');
}
