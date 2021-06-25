import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu(config: InterpreterConfig(sourceType: SourceType.script));
  await hetu.init();
  final result = await hetu.eval(r'''
    var list = [1,2,3]

    var i = 0
    do  {
      print(i)
      ++i
    } while (i < 5)


  ''');
  print(result);
}
